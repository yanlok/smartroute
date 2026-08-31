import 'dart:math';

import '../../../shared/models/journey_models.dart';
import '../../../shared/models/transit_models.dart';

class RoutePlannerService {
  final TransitNetwork network;

  const RoutePlannerService(this.network);

  List<JourneyOption> plan({
    required String originStopId,
    required String destinationStopId,
    Set<TransitMode>? allowedModes,
  }) {
    if (!network.stopsById.containsKey(originStopId) ||
        !network.stopsById.containsKey(destinationStopId)) {
      return const [];
    }
    if (originStopId == destinationStopId) {
      return [
        JourneyOption(
          id: 'same-stop',
          objective: RouteObjective.fastest,
          originStopId: originStopId,
          destinationStopId: destinationStopId,
          durationMinutes: 0,
          transferCount: 0,
          walkingMetres: 0,
          segments: const [],
        ),
      ];
    }

    final results = <JourneyOption>[];
    final signatures = <String>{};
    for (final objective in RouteObjective.values) {
      final result = _shortestPath(
        originStopId: originStopId,
        destinationStopId: destinationStopId,
        objective: objective,
        allowedModes: allowedModes,
        excludedRouteIds: const {},
      );
      if (result != null && signatures.add(result.signature)) {
        results.add(result);
      }
    }

    if (results.length < 3 && results.isNotEmpty) {
      final fastestRoutes =
          results.first.segments
              .map((segment) => segment.routeId)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
      for (final excluded in fastestRoutes) {
        if (results.length >= 3) break;
        final objective = RouteObjective.values[results.length];
        final alternative = _shortestPath(
          originStopId: originStopId,
          destinationStopId: destinationStopId,
          objective: objective,
          allowedModes: allowedModes,
          excludedRouteIds: {excluded},
        );
        if (alternative != null && signatures.add(alternative.signature)) {
          results.add(alternative);
        }
      }
    }
    return results;
  }

  JourneyOption? planForObjective({
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
    Set<TransitMode>? allowedModes,
  }) {
    if (!network.stopsById.containsKey(originStopId) ||
        !network.stopsById.containsKey(destinationStopId)) {
      return null;
    }
    if (originStopId == destinationStopId) {
      return JourneyOption(
        id: 'same-stop',
        objective: objective,
        originStopId: originStopId,
        destinationStopId: destinationStopId,
        durationMinutes: 0,
        transferCount: 0,
        walkingMetres: 0,
        segments: const [],
      );
    }
    return _shortestPath(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      objective: objective,
      allowedModes: allowedModes,
      excludedRouteIds: const {},
    );
  }

  JourneyOption? _shortestPath({
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
    required Set<TransitMode>? allowedModes,
    required Set<String> excludedRouteIds,
  }) {
    final queue = _MinHeap();
    final origin = _State(originStopId, null);
    final best = <_State, int>{origin: 0};
    final totals = <_State, _Totals>{origin: const _Totals()};
    final previous = <_State, _Step>{};
    queue.add(_QueueEntry(origin, 0));
    _State? destination;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current.score != best[current.state]) continue;
      if (current.state.stopId == destinationStopId) {
        destination = current.state;
        break;
      }
      final outgoing = network.outgoingEdges[current.state.stopId] ?? const [];
      for (final edge in outgoing) {
        final routeId = edge.routeId;
        if (routeId != null) {
          if (excludedRouteIds.contains(routeId)) continue;
          final route = network.routesById[routeId];
          if (route == null ||
              (allowedModes != null && !allowedModes.contains(route.mode))) {
            continue;
          }
        }
        final changedRoute =
            routeId != null &&
            current.state.routeId != null &&
            routeId != current.state.routeId;
        final transferMinutes = changedRoute ? 4 : 0;
        final boardingMinutes = routeId != null && current.state.routeId == null
            ? 3
            : 0;
        final nextTotals = totals[current.state]!.add(
          minutes: edge.minutes + transferMinutes + boardingMinutes,
          transfers: changedRoute ? 1 : 0,
          walkingMetres: edge.walkingMetres,
        );
        final nextRouteId = routeId ?? current.state.routeId;
        final next = _State(edge.toStopId, nextRouteId);
        final nextScore = _score(nextTotals, objective);
        final previousScore = best[next];
        if (previousScore != null && previousScore <= nextScore) continue;
        best[next] = nextScore;
        totals[next] = nextTotals;
        previous[next] = _Step(
          current.state,
          edge,
          transferMinutes + boardingMinutes,
        );
        queue.add(_QueueEntry(next, nextScore));
      }
    }
    if (destination == null) return null;

    final path = <_ResolvedEdge>[];
    var cursor = destination;
    while (cursor != origin) {
      final step = previous[cursor];
      if (step == null) return null;
      path.add(_ResolvedEdge(step.edge, step.extraMinutes));
      cursor = step.previous;
    }
    final ordered = path.reversed.toList(growable: false);
    final total = totals[destination]!;
    final segments = _segments(ordered);
    final suffix = excludedRouteIds.isEmpty ? '' : '-alt';
    return JourneyOption(
      id: '${objective.name}$suffix-$originStopId-$destinationStopId',
      objective: objective,
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      durationMinutes: total.minutes,
      transferCount: total.transfers,
      walkingMetres: total.walkingMetres,
      segments: segments,
    );
  }

  int _score(_Totals totals, RouteObjective objective) => switch (objective) {
    RouteObjective.fastest => totals.minutes,
    RouteObjective.fewerTransfers => totals.minutes + totals.transfers * 25,
    RouteObjective.leastWalking =>
      totals.minutes +
          (totals.walkingMetres / 75).ceil() * 4 +
          totals.transfers * 5,
  };

  List<JourneySegment> _segments(List<_ResolvedEdge> path) {
    if (path.isEmpty) return const [];
    final result = <JourneySegment>[];
    var current = <_ResolvedEdge>[path.first];
    for (final edge in path.skip(1)) {
      if (edge.edge.routeId == current.last.edge.routeId) {
        current.add(edge);
      } else {
        result.add(_segment(current));
        current = <_ResolvedEdge>[edge];
      }
    }
    result.add(_segment(current));
    return result;
  }

  JourneySegment _segment(List<_ResolvedEdge> edges) {
    final first = edges.first.edge;
    final routeId = first.routeId;
    final stopIds = <String>[
      first.fromStopId,
      for (final edge in edges) edge.edge.toStopId,
    ];
    return JourneySegment(
      fromStopId: first.fromStopId,
      toStopId: edges.last.edge.toStopId,
      routeId: routeId,
      mode: routeId == null ? null : network.routesById[routeId]?.mode,
      durationMinutes: edges.fold(
        0,
        (total, edge) => total + edge.edge.minutes + edge.extraMinutes,
      ),
      stopCount: routeId == null ? 0 : edges.length,
      walkingMetres: edges.fold(
        0,
        (total, edge) => total + edge.edge.walkingMetres,
      ),
      stopIds: stopIds,
    );
  }
}

class JourneyMapProjector {
  const JourneyMapProjector();

  List<TransitCoordinate> coordinatesFor(
    JourneyOption journey,
    TransitNetwork network,
  ) {
    final result = <TransitCoordinate>[];
    for (final segment in journey.segments) {
      final route = segment.routeId == null
          ? null
          : network.routesById[segment.routeId];
      final from = network.stopsById[segment.fromStopId];
      final to = network.stopsById[segment.toStopId];
      if (route == null || route.shape.isEmpty || from == null || to == null) {
        if (from != null) result.add(from.coordinate);
        if (to != null) result.add(to.coordinate);
        continue;
      }
      final fromIndex = _nearest(route.shape, from.coordinate);
      final toIndex = _nearest(route.shape, to.coordinate);
      final start = min(fromIndex, toIndex);
      final end = max(fromIndex, toIndex);
      final portion = route.shape.sublist(start, end + 1);
      result.addAll(fromIndex <= toIndex ? portion : portion.reversed);
    }
    return _deduplicate(result);
  }

  int _nearest(List<TransitCoordinate> shape, TransitCoordinate target) {
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < shape.length; index++) {
      final point = shape[index];
      final lat = point.latitude - target.latitude;
      final lon = point.longitude - target.longitude;
      final distance = lat * lat + lon * lon;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  List<TransitCoordinate> _deduplicate(List<TransitCoordinate> points) {
    final result = <TransitCoordinate>[];
    for (final point in points) {
      if (result.isEmpty ||
          result.last.latitude != point.latitude ||
          result.last.longitude != point.longitude) {
        result.add(point);
      }
    }
    return result;
  }
}

class _State {
  final String stopId;
  final String? routeId;

  const _State(this.stopId, this.routeId);

  @override
  bool operator ==(Object other) =>
      other is _State && stopId == other.stopId && routeId == other.routeId;

  @override
  int get hashCode => Object.hash(stopId, routeId);
}

class _Totals {
  final int minutes;
  final int transfers;
  final int walkingMetres;

  const _Totals({this.minutes = 0, this.transfers = 0, this.walkingMetres = 0});

  _Totals add({
    required int minutes,
    required int transfers,
    required int walkingMetres,
  }) => _Totals(
    minutes: this.minutes + minutes,
    transfers: this.transfers + transfers,
    walkingMetres: this.walkingMetres + walkingMetres,
  );
}

class _Step {
  final _State previous;
  final TransitEdge edge;
  final int extraMinutes;

  const _Step(this.previous, this.edge, this.extraMinutes);
}

class _ResolvedEdge {
  final TransitEdge edge;
  final int extraMinutes;

  const _ResolvedEdge(this.edge, this.extraMinutes);
}

class _QueueEntry {
  final _State state;
  final int score;

  const _QueueEntry(this.state, this.score);
}

class _MinHeap {
  final List<_QueueEntry> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  void add(_QueueEntry entry) {
    _items.add(entry);
    var index = _items.length - 1;
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_compare(_items[parent], entry) <= 0) break;
      _items[index] = _items[parent];
      index = parent;
    }
    _items[index] = entry;
  }

  _QueueEntry removeFirst() {
    final first = _items.first;
    final last = _items.removeLast();
    if (_items.isEmpty) return first;
    var index = 0;
    while (true) {
      final left = index * 2 + 1;
      if (left >= _items.length) break;
      final right = left + 1;
      var child = left;
      if (right < _items.length && _compare(_items[right], _items[left]) < 0) {
        child = right;
      }
      if (_compare(last, _items[child]) <= 0) break;
      _items[index] = _items[child];
      index = child;
    }
    _items[index] = last;
    return first;
  }

  int _compare(_QueueEntry a, _QueueEntry b) {
    final score = a.score.compareTo(b.score);
    if (score != 0) return score;
    final stop = a.state.stopId.compareTo(b.state.stopId);
    if (stop != 0) return stop;
    return (a.state.routeId ?? '').compareTo(b.state.routeId ?? '');
  }
}

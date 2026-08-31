import 'transit_models.dart';

enum RouteObjective { fastest, fewerTransfers, leastWalking }

extension RouteObjectiveDisplay on RouteObjective {
  String get label => switch (this) {
    RouteObjective.fastest => 'Fastest',
    RouteObjective.fewerTransfers => 'Fewer transfers',
    RouteObjective.leastWalking => 'Least walking',
  };
}

class JourneySegment {
  final String fromStopId;
  final String toStopId;
  final String? routeId;
  final TransitMode? mode;
  final int durationMinutes;
  final int stopCount;
  final int walkingMetres;
  final List<String> stopIds;

  const JourneySegment({
    required this.fromStopId,
    required this.toStopId,
    required this.routeId,
    required this.mode,
    required this.durationMinutes,
    required this.stopCount,
    required this.walkingMetres,
    required this.stopIds,
  });

  bool get isWalking => routeId == null;
}

class JourneyOption {
  final String id;
  final RouteObjective objective;
  final String originStopId;
  final String destinationStopId;
  final int durationMinutes;
  final int transferCount;
  final int walkingMetres;
  final List<JourneySegment> segments;

  const JourneyOption({
    required this.id,
    required this.objective,
    required this.originStopId,
    required this.destinationStopId,
    required this.durationMinutes,
    required this.transferCount,
    required this.walkingMetres,
    required this.segments,
  });

  String get signature => segments
      .map(
        (segment) =>
            '${segment.routeId ?? 'walk'}:${segment.fromStopId}:${segment.toStopId}',
      )
      .join('|');
}

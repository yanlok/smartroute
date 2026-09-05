import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _categories = <String>[
  'rapid-rail-kl',
  'rapid-bus-kl',
  'rapid-bus-mrtfeeder',
];

void main(List<String> arguments) {
  final options = <String, String>{};
  for (final argument in arguments) {
    final separator = argument.indexOf('=');
    if (argument.startsWith('--') && separator > 2) {
      options[argument.substring(2, separator)] = argument.substring(
        separator + 1,
      );
    }
  }
  final input = options['input'];
  final output = options['output'] ?? 'assets/data/transit_network.json';
  final generatedAt =
      options['generated-at'] ?? DateTime.now().toUtc().toIso8601String();
  if (input == null) {
    stderr.writeln(
      'Usage: dart run tool/import_gtfs_network.dart --input=/path/to/extracted-feeds '
      '--output=assets/data/transit_network.json --generated-at=ISO8601',
    );
    exitCode = 64;
    return;
  }

  final routes = <String, _Route>{};
  final stops = <String, _Stop>{};
  final edges = <String, _Edge>{};
  final patterns = <String, _Pattern>{};
  final selectedShapes = <String, String>{};
  final sources = <Map<String, Object?>>[];

  for (final category in _categories) {
    final directory = Directory('$input/$category');
    if (!directory.existsSync()) {
      throw StateError('Missing extracted GTFS directory: ${directory.path}');
    }
    final feed = _readFeed(category, directory);
    routes.addAll(feed.routes);
    stops.addAll(feed.stops);
    for (final edge in feed.edges) {
      final key = '${edge.routeId}|${edge.from}|${edge.to}';
      final previous = edges[key];
      if (previous == null || edge.minutes < previous.minutes) {
        edges[key] = edge;
      }
    }
    for (final pattern in feed.patterns) {
      patterns[pattern.id] = pattern;
      selectedShapes[pattern.shapeKey] = pattern.routeId;
    }
    sources.add({
      'category': category,
      'url': 'https://api.data.gov.my/gtfs-static/prasarana?category=$category',
      'routeCount': feed.routes.length,
      'stopCount': feed.stops.length,
      'tripCount': feed.tripCount,
      'stopTimeCount': feed.stopTimeCount,
      'serviceStart': feed.serviceStart,
      'serviceEnd': feed.serviceEnd,
    });
  }

  final routeShapes = <String, List<List<num>>>{};
  for (final category in _categories) {
    final shapeFile = File('$input/$category/shapes.txt');
    if (!shapeFile.existsSync()) continue;
    final table = _CsvTable.read(shapeFile);
    final grouped = <String, List<_ShapePoint>>{};
    for (final row in table.rows) {
      final shapeId = table.value(row, 'shape_id');
      final shapeKey = '$category:$shapeId';
      if (!selectedShapes.containsKey(shapeKey)) continue;
      final lat = double.tryParse(table.value(row, 'shape_pt_lat'));
      final lon = double.tryParse(table.value(row, 'shape_pt_lon'));
      final sequence = int.tryParse(table.value(row, 'shape_pt_sequence'));
      if (lat == null || lon == null || sequence == null) continue;
      grouped
          .putIfAbsent(shapeKey, () => <_ShapePoint>[])
          .add(_ShapePoint(sequence, lat, lon));
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.sequence.compareTo(b.sequence));
      final routeId = selectedShapes[entry.key]!;
      final points = _sampleShape(entry.value, 240);
      final existing = routeShapes[routeId];
      if (existing == null || points.length > existing.length) {
        routeShapes[routeId] = points;
      }
    }
  }

  for (final edge in edges.values) {
    final routeId = edge.routeId;
    if (routeId != null) {
      stops[edge.from]?.routeIds.add(routeId);
      stops[edge.to]?.routeIds.add(routeId);
    }
  }
  final transferEdges = _buildTransfers(stops.values.toList());

  final routeList = routes.values.toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));
  final stopList = stops.values.toList()
    ..removeWhere((stop) => stop.routeIds.isEmpty)
    ..sort((a, b) => a.name.compareTo(b.name));
  final patternList = patterns.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final edgeList = <_Edge>[...edges.values, ...transferEdges]
    ..sort((a, b) {
      final from = a.from.compareTo(b.from);
      if (from != 0) return from;
      final to = a.to.compareTo(b.to);
      if (to != 0) return to;
      return (a.routeId ?? '').compareTo(b.routeId ?? '');
    });

  final payload = <String, Object?>{
    'metadata': {
      'generatedAt': generatedAt,
      'publisher': 'Prasarana Malaysia Berhad via data.gov.my',
      'licence': 'Creative Commons Attribution 4.0',
      'sources': sources,
      'routeCount': routeList.length,
      'stopCount': stopList.length,
      'edgeCount': edgeList.length,
      'patternCount': patternList.length,
      'shapeRouteCount': routeShapes.length,
    },
    'routes': [
      for (final route in routeList) route.toJson(routeShapes[route.id]),
    ],
    'stops': [for (final stop in stopList) stop.toJson()],
    'edges': [for (final edge in edgeList) edge.toJson()],
    'patterns': [for (final pattern in patternList) pattern.toJson()],
  };
  final target = File(output)..parent.createSync(recursive: true);
  target.writeAsStringSync(jsonEncode(payload));
  stdout.writeln(
    'Generated $output with ${routeList.length} routes, ${stopList.length} stops, '
    '${edgeList.length} edges, ${patternList.length} patterns, and '
    '${routeShapes.length} route shapes.',
  );
}

_Feed _readFeed(String category, Directory directory) {
  final routeTable = _CsvTable.read(File('${directory.path}/routes.txt'));
  final stopTable = _CsvTable.read(File('${directory.path}/stops.txt'));
  final tripTable = _CsvTable.read(File('${directory.path}/trips.txt'));
  final stopTimeTable = _CsvTable.read(
    File('${directory.path}/stop_times.txt'),
  );
  final frequencyFile = File('${directory.path}/frequencies.txt');
  final calendarFile = File('${directory.path}/calendar.txt');

  final routes = <String, _Route>{};
  for (final row in routeTable.rows) {
    final gtfsId = routeTable.value(row, 'route_id');
    if (gtfsId.isEmpty) continue;
    final id = '$category:$gtfsId';
    routes[id] = _Route(
      id: id,
      gtfsId: gtfsId,
      source: category,
      shortName: routeTable.value(row, 'route_short_name'),
      longName: routeTable.value(row, 'route_long_name'),
      mode: _modeFor(
        category,
        gtfsId,
        routeTable.value(row, 'route_long_name'),
        routeTable.value(row, 'route_type'),
      ),
      color: _color(routeTable.value(row, 'route_color')),
    );
  }

  final stops = <String, _Stop>{};
  for (final row in stopTable.rows) {
    final gtfsId = stopTable.value(row, 'stop_id');
    final lat = double.tryParse(stopTable.value(row, 'stop_lat'));
    final lon = double.tryParse(stopTable.value(row, 'stop_lon'));
    if (gtfsId.isEmpty || lat == null || lon == null) continue;
    final id = '$category:$gtfsId';
    stops[id] = _Stop(
      id: id,
      gtfsId: gtfsId,
      source: category,
      name: _cleanName(stopTable.value(row, 'stop_name')),
      latitude: lat,
      longitude: lon,
    );
  }

  final trips = <String, _Trip>{};
  for (final row in tripTable.rows) {
    final tripId = tripTable.value(row, 'trip_id');
    final rawRouteId = tripTable.value(row, 'route_id');
    final routeId = '$category:$rawRouteId';
    if (tripId.isEmpty || !routes.containsKey(routeId)) continue;
    trips[tripId] = _Trip(
      id: tripId,
      routeId: routeId,
      direction: int.tryParse(tripTable.value(row, 'direction_id')) ?? 0,
      shapeKey: '$category:${tripTable.value(row, 'shape_id')}',
      headsign: tripTable.value(row, 'trip_headsign'),
    );
  }

  final frequencies = <String, _Frequency>{};
  if (frequencyFile.existsSync()) {
    final table = _CsvTable.read(frequencyFile);
    for (final row in table.rows) {
      final tripId = table.value(row, 'trip_id');
      final start = _time(table.value(row, 'start_time'));
      final end = _time(table.value(row, 'end_time'));
      final headway = int.tryParse(table.value(row, 'headway_secs'));
      if (tripId.isEmpty || start == null || end == null || headway == null) {
        continue;
      }
      final existing = frequencies[tripId];
      frequencies[tripId] = existing == null
          ? _Frequency(start, end, headway)
          : _Frequency(
              min(existing.start, start),
              max(existing.end, end),
              min(existing.headway, headway),
            );
    }
  }

  final byTrip = <String, List<_StopTime>>{};
  for (final row in stopTimeTable.rows) {
    final tripId = stopTimeTable.value(row, 'trip_id');
    final trip = trips[tripId];
    if (trip == null) continue;
    final rawStopId = stopTimeTable.value(row, 'stop_id');
    final stopId = '$category:$rawStopId';
    if (!stops.containsKey(stopId)) continue;
    final arrival = _time(stopTimeTable.value(row, 'arrival_time'));
    final departure =
        _time(stopTimeTable.value(row, 'departure_time')) ?? arrival;
    final sequence = int.tryParse(stopTimeTable.value(row, 'stop_sequence'));
    if (arrival == null || departure == null || sequence == null) continue;
    byTrip
        .putIfAbsent(tripId, () => <_StopTime>[])
        .add(_StopTime(stopId, sequence, arrival, departure));
  }

  final edges = <_Edge>[];
  final candidates = <String, _Pattern>{};
  for (final entry in byTrip.entries) {
    final trip = trips[entry.key]!;
    final times = entry.value..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (times.length < 2) continue;
    for (var index = 0; index < times.length - 1; index++) {
      final from = times[index];
      final to = times[index + 1];
      final minutes = max(1, ((to.arrival - from.departure) / 60).round());
      edges.add(_Edge(from.stopId, to.stopId, trip.routeId, minutes, 0));
    }
    final key = '${trip.routeId}:${trip.direction}';
    final frequency = frequencies[trip.id];
    final pattern = _Pattern(
      id: '$key:${trip.id}',
      routeId: trip.routeId,
      gtfsTripId: trip.id,
      direction: trip.direction,
      headsign: trip.headsign,
      shapeKey: trip.shapeKey,
      stopIds: [for (final time in times) time.stopId],
      offsets: [
        for (final time in times)
          ((time.departure - times.first.departure) / 60).round(),
      ],
      startSeconds: frequency?.start ?? times.first.departure,
      endSeconds: frequency?.end ?? times.last.departure,
      headwaySeconds: frequency?.headway,
    );
    final previous = candidates[key];
    if (previous == null || pattern.stopIds.length > previous.stopIds.length) {
      candidates[key] = pattern;
    }
  }

  String? serviceStart;
  String? serviceEnd;
  if (calendarFile.existsSync()) {
    final table = _CsvTable.read(calendarFile);
    final starts =
        [for (final row in table.rows) table.value(row, 'start_date')]
          ..removeWhere((value) => value.isEmpty)
          ..sort();
    final ends = [for (final row in table.rows) table.value(row, 'end_date')]
      ..removeWhere((value) => value.isEmpty)
      ..sort();
    if (starts.isNotEmpty) serviceStart = starts.first;
    if (ends.isNotEmpty) serviceEnd = ends.last;
  }

  return _Feed(
    routes: routes,
    stops: stops,
    edges: edges,
    patterns: candidates.values.toList(),
    tripCount: trips.length,
    stopTimeCount: stopTimeTable.rows.length,
    serviceStart: serviceStart,
    serviceEnd: serviceEnd,
  );
}

List<_Edge> _buildTransfers(List<_Stop> stops) {
  const cellSize = 0.001;
  final cells = <String, List<_Stop>>{};
  for (final stop in stops) {
    if (stop.routeIds.isEmpty) continue;
    final x = (stop.latitude / cellSize).floor();
    final y = (stop.longitude / cellSize).floor();
    cells.putIfAbsent('$x:$y', () => <_Stop>[]).add(stop);
  }
  final result = <_Edge>[];
  final seen = <String>{};
  for (final stop in stops) {
    if (stop.routeIds.isEmpty) continue;
    final x = (stop.latitude / cellSize).floor();
    final y = (stop.longitude / cellSize).floor();
    for (var dx = -2; dx <= 2; dx++) {
      for (var dy = -2; dy <= 2; dy++) {
        for (final other in cells['${x + dx}:${y + dy}'] ?? const <_Stop>[]) {
          if (stop.id == other.id ||
              stop.routeIds.intersection(other.routeIds).isNotEmpty) {
            continue;
          }
          final distance = _distance(stop, other);
          final sameName = _normalName(stop.name) == _normalName(other.name);
          if (distance > (sameName ? 450 : 110)) continue;
          final key = '${stop.id}|${other.id}';
          if (!seen.add(key)) continue;
          final minutes = max(2, (distance / 75).ceil());
          result.add(_Edge(stop.id, other.id, null, minutes, distance.round()));
        }
      }
    }
  }
  return result;
}

double _distance(_Stop a, _Stop b) {
  const radius = 6371000.0;
  final lat1 = a.latitude * pi / 180;
  final lat2 = b.latitude * pi / 180;
  final dLat = (b.latitude - a.latitude) * pi / 180;
  final dLon = (b.longitude - a.longitude) * pi / 180;
  final value =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  return radius * 2 * atan2(sqrt(value), sqrt(1 - value));
}

List<List<num>> _sampleShape(List<_ShapePoint> points, int maximum) {
  if (points.length <= maximum) {
    return [
      for (final point in points) [point.latitude, point.longitude],
    ];
  }
  final sampled = <List<num>>[];
  for (var index = 0; index < maximum; index++) {
    final sourceIndex = (index * (points.length - 1) / (maximum - 1)).round();
    final point = points[sourceIndex];
    sampled.add([point.latitude, point.longitude]);
  }
  return sampled;
}

String _modeFor(String category, String id, String name, String type) {
  if (category != 'rapid-rail-kl') return 'bus';
  final value = '$id $name'.toLowerCase();
  if (value.contains('monorail') || id.toLowerCase() == 'mr') return 'monorail';
  if (value.contains('brt')) return 'brt';
  if (value.contains('lrt')) return 'lrt';
  if (value.contains('mrt') ||
      id.toLowerCase() == 'kgl' ||
      id.toLowerCase() == 'pyl') {
    return 'mrt';
  }
  return type == '1' ? 'mrt' : 'lrt';
}

String _color(String value) {
  final normalized = value.trim().toUpperCase();
  return RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized)
      ? '#$normalized'
      : '#6B7280';
}

String _cleanName(String value) {
  final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.isEmpty) return 'Unnamed stop';
  if (trimmed != trimmed.toUpperCase()) return trimmed;
  return trimmed
      .toLowerCase()
      .split(' ')
      .map((part) {
        if (part.isEmpty) return part;
        return '${part[0].toUpperCase()}${part.substring(1)}';
      })
      .join(' ');
}

String _normalName(String value) => value
    .toLowerCase()
    .replaceAll(
      RegExp(r'\b(lrt|mrt|monorail|brt|station|stesen|hub|terminal)\b'),
      '',
    )
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

int? _time(String value) {
  final parts = value.split(':');
  if (parts.length != 3) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  final second = int.tryParse(parts[2]);
  if (hour == null || minute == null || second == null) return null;
  return hour * 3600 + minute * 60 + second;
}

class _CsvTable {
  final Map<String, int> columns;
  final List<List<String>> rows;

  const _CsvTable(this.columns, this.rows);

  factory _CsvTable.read(File file) {
    final records = _parseCsv(file.readAsStringSync());
    if (records.isEmpty) return const _CsvTable({}, []);
    final columns = <String, int>{};
    for (var index = 0; index < records.first.length; index++) {
      columns[records.first[index].trim()] = index;
    }
    return _CsvTable(
      columns,
      records.skip(1).where((row) => row.isNotEmpty).toList(),
    );
  }

  String value(List<String> row, String column) {
    final index = columns[column];
    return index == null || index >= row.length ? '' : row[index].trim();
  }
}

List<List<String>> _parseCsv(String source) {
  final records = <List<String>>[];
  var record = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (character == '"') {
      if (quoted && index + 1 < source.length && source[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      record.add(field.toString());
      field.clear();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      if (character == '\r' &&
          index + 1 < source.length &&
          source[index + 1] == '\n') {
        index++;
      }
      record.add(field.toString());
      field.clear();
      if (record.any((value) => value.isNotEmpty)) records.add(record);
      record = <String>[];
    } else {
      field.write(character);
    }
  }
  if (field.isNotEmpty || record.isNotEmpty) {
    record.add(field.toString());
    records.add(record);
  }
  return records;
}

class _Feed {
  final Map<String, _Route> routes;
  final Map<String, _Stop> stops;
  final List<_Edge> edges;
  final List<_Pattern> patterns;
  final int tripCount;
  final int stopTimeCount;
  final String? serviceStart;
  final String? serviceEnd;

  const _Feed({
    required this.routes,
    required this.stops,
    required this.edges,
    required this.patterns,
    required this.tripCount,
    required this.stopTimeCount,
    required this.serviceStart,
    required this.serviceEnd,
  });
}

class _Route {
  final String id;
  final String gtfsId;
  final String source;
  final String shortName;
  final String longName;
  final String mode;
  final String color;

  const _Route({
    required this.id,
    required this.gtfsId,
    required this.source,
    required this.shortName,
    required this.longName,
    required this.mode,
    required this.color,
  });

  String get displayName => longName.isNotEmpty ? longName : shortName;

  Map<String, Object?> toJson(List<List<num>>? shape) => {
    'id': id,
    'gtfsId': gtfsId,
    'source': source,
    'shortName': shortName,
    'longName': displayName,
    'mode': mode,
    'color': color,
    'operator': 'Rapid KL',
    'shape': shape ?? const <List<num>>[],
  };
}

class _Stop {
  final String id;
  final String gtfsId;
  final String source;
  final String name;
  final double latitude;
  final double longitude;
  final Set<String> routeIds = <String>{};

  _Stop({
    required this.id,
    required this.gtfsId,
    required this.source,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'gtfsId': gtfsId,
    'source': source,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'routeIds': routeIds.toList()..sort(),
  };
}

class _Trip {
  final String id;
  final String routeId;
  final int direction;
  final String shapeKey;
  final String headsign;

  const _Trip({
    required this.id,
    required this.routeId,
    required this.direction,
    required this.shapeKey,
    required this.headsign,
  });
}

class _StopTime {
  final String stopId;
  final int sequence;
  final int arrival;
  final int departure;

  const _StopTime(this.stopId, this.sequence, this.arrival, this.departure);
}

class _Frequency {
  final int start;
  final int end;
  final int headway;

  const _Frequency(this.start, this.end, this.headway);
}

class _Edge {
  final String from;
  final String to;
  final String? routeId;
  final int minutes;
  final int walkingMetres;

  const _Edge(
    this.from,
    this.to,
    this.routeId,
    this.minutes,
    this.walkingMetres,
  );

  Map<String, Object?> toJson() => {
    'from': from,
    'to': to,
    if (routeId != null) 'routeId': routeId,
    'minutes': minutes,
    'walkingMetres': walkingMetres,
  };
}

class _Pattern {
  final String id;
  final String routeId;
  final String gtfsTripId;
  final int direction;
  final String headsign;
  final String shapeKey;
  final List<String> stopIds;
  final List<int> offsets;
  final int startSeconds;
  final int endSeconds;
  final int? headwaySeconds;

  const _Pattern({
    required this.id,
    required this.routeId,
    required this.gtfsTripId,
    required this.direction,
    required this.headsign,
    required this.shapeKey,
    required this.stopIds,
    required this.offsets,
    required this.startSeconds,
    required this.endSeconds,
    required this.headwaySeconds,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'routeId': routeId,
    'gtfsTripId': gtfsTripId,
    'direction': direction,
    'headsign': headsign,
    'stopIds': stopIds,
    'offsetMinutes': offsets,
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
    if (headwaySeconds != null) 'headwaySeconds': headwaySeconds,
  };
}

class _ShapePoint {
  final int sequence;
  final double latitude;
  final double longitude;

  const _ShapePoint(this.sequence, this.latitude, this.longitude);
}

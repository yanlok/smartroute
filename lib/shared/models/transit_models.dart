enum TransitMode { lrt, mrt, monorail, brt, bus }

extension TransitModeDisplay on TransitMode {
  String get label => switch (this) {
    TransitMode.lrt => 'LRT',
    TransitMode.mrt => 'MRT',
    TransitMode.monorail => 'Monorail',
    TransitMode.brt => 'BRT',
    TransitMode.bus => 'Bus',
  };

  static TransitMode parse(String value) => switch (value.toLowerCase()) {
    'lrt' => TransitMode.lrt,
    'mrt' => TransitMode.mrt,
    'monorail' => TransitMode.monorail,
    'brt' => TransitMode.brt,
    _ => TransitMode.bus,
  };
}

class TransitCoordinate {
  final double latitude;
  final double longitude;

  const TransitCoordinate(this.latitude, this.longitude);

  factory TransitCoordinate.fromJson(List<Object?> json) => TransitCoordinate(
    (json[0] as num).toDouble(),
    (json[1] as num).toDouble(),
  );
}

class TransitRoute {
  final String id;
  final String gtfsId;
  final String source;
  final String shortName;
  final String longName;
  final TransitMode mode;
  final String colorHex;
  final String operatorName;
  final List<TransitCoordinate> shape;

  const TransitRoute({
    required this.id,
    required this.gtfsId,
    required this.source,
    required this.shortName,
    required this.longName,
    required this.mode,
    required this.colorHex,
    required this.operatorName,
    required this.shape,
  });

  String get displayName => longName.isNotEmpty ? longName : shortName;

  factory TransitRoute.fromJson(Map<String, Object?> json) => TransitRoute(
    id: json['id']! as String,
    gtfsId: json['gtfsId']! as String,
    source: json['source']! as String,
    shortName: json['shortName']! as String,
    longName: json['longName']! as String,
    mode: TransitModeDisplay.parse(json['mode']! as String),
    colorHex: json['color']! as String,
    operatorName: json['operator']! as String,
    shape: [
      for (final point in json['shape']! as List<Object?>)
        TransitCoordinate.fromJson(point! as List<Object?>),
    ],
  );
}

class TransitStop {
  final String id;
  final String gtfsId;
  final String source;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> routeIds;

  const TransitStop({
    required this.id,
    required this.gtfsId,
    required this.source,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.routeIds,
  });

  TransitCoordinate get coordinate => TransitCoordinate(latitude, longitude);

  factory TransitStop.fromJson(Map<String, Object?> json) => TransitStop(
    id: json['id']! as String,
    gtfsId: json['gtfsId']! as String,
    source: json['source']! as String,
    name: json['name']! as String,
    latitude: (json['latitude']! as num).toDouble(),
    longitude: (json['longitude']! as num).toDouble(),
    routeIds: List<String>.from(json['routeIds']! as List<Object?>),
  );
}

class TransitEdge {
  final String fromStopId;
  final String toStopId;
  final String? routeId;
  final int minutes;
  final int walkingMetres;

  const TransitEdge({
    required this.fromStopId,
    required this.toStopId,
    required this.routeId,
    required this.minutes,
    required this.walkingMetres,
  });

  bool get isWalking => routeId == null;

  factory TransitEdge.fromJson(Map<String, Object?> json) => TransitEdge(
    fromStopId: json['from']! as String,
    toStopId: json['to']! as String,
    routeId: json['routeId'] as String?,
    minutes: json['minutes']! as int,
    walkingMetres: json['walkingMetres']! as int,
  );
}

class TransitPattern {
  final String id;
  final String routeId;
  final String gtfsTripId;
  final int direction;
  final String headsign;
  final List<String> stopIds;
  final List<int> offsetMinutes;
  final int startSeconds;
  final int endSeconds;
  final int? headwaySeconds;

  const TransitPattern({
    required this.id,
    required this.routeId,
    required this.gtfsTripId,
    required this.direction,
    required this.headsign,
    required this.stopIds,
    required this.offsetMinutes,
    required this.startSeconds,
    required this.endSeconds,
    required this.headwaySeconds,
  });

  factory TransitPattern.fromJson(Map<String, Object?> json) => TransitPattern(
    id: json['id']! as String,
    routeId: json['routeId']! as String,
    gtfsTripId: json['gtfsTripId']! as String,
    direction: json['direction']! as int,
    headsign: json['headsign']! as String,
    stopIds: List<String>.from(json['stopIds']! as List<Object?>),
    offsetMinutes: List<int>.from(json['offsetMinutes']! as List<Object?>),
    startSeconds: json['startSeconds']! as int,
    endSeconds: json['endSeconds']! as int,
    headwaySeconds: json['headwaySeconds'] as int?,
  );

  DateTime? nextDeparture(String stopId, DateTime now) {
    final stopIndex = stopIds.indexOf(stopId);
    if (stopIndex < 0) return null;
    final offset = offsetMinutes[stopIndex] * 60;
    final midnight = DateTime(now.year, now.month, now.day);
    final first = midnight.add(Duration(seconds: startSeconds + offset));
    final last = midnight.add(Duration(seconds: endSeconds + offset));
    if (now.isBefore(first)) return first;
    if (now.isAfter(last)) return null;
    final headway = headwaySeconds;
    if (headway == null || headway <= 0) {
      return first.isAfter(now) ? first : null;
    }
    final elapsed = now.difference(first).inSeconds;
    final intervals = (elapsed / headway).ceil();
    final result = first.add(Duration(seconds: intervals * headway));
    return result.isAfter(last) ? null : result;
  }
}

class TransitMetadata {
  final DateTime generatedAt;
  final String publisher;
  final String licence;
  final int routeCount;
  final int stopCount;
  final int edgeCount;
  final int patternCount;
  final int shapeRouteCount;
  final List<Map<String, Object?>> sources;

  const TransitMetadata({
    required this.generatedAt,
    required this.publisher,
    required this.licence,
    required this.routeCount,
    required this.stopCount,
    required this.edgeCount,
    required this.patternCount,
    required this.shapeRouteCount,
    required this.sources,
  });

  factory TransitMetadata.fromJson(Map<String, Object?> json) =>
      TransitMetadata(
        generatedAt: DateTime.parse(json['generatedAt']! as String),
        publisher: json['publisher']! as String,
        licence: json['licence']! as String,
        routeCount: json['routeCount']! as int,
        stopCount: json['stopCount']! as int,
        edgeCount: json['edgeCount']! as int,
        patternCount: json['patternCount']! as int,
        shapeRouteCount: json['shapeRouteCount']! as int,
        sources: [
          for (final source in json['sources']! as List<Object?>)
            Map<String, Object?>.from(source! as Map<Object?, Object?>),
        ],
      );
}

class TransitNetwork {
  final TransitMetadata metadata;
  final List<TransitRoute> routes;
  final List<TransitStop> stops;
  final List<TransitEdge> edges;
  final List<TransitPattern> patterns;
  late final Map<String, TransitRoute> routesById = {
    for (final route in routes) route.id: route,
  };
  late final Map<String, TransitStop> stopsById = {
    for (final stop in stops) stop.id: stop,
  };
  late final Map<String, List<TransitEdge>> outgoingEdges = _indexEdges();

  TransitNetwork({
    required this.metadata,
    required this.routes,
    required this.stops,
    required this.edges,
    required this.patterns,
  });

  Map<String, List<TransitEdge>> _indexEdges() {
    final result = <String, List<TransitEdge>>{};
    for (final edge in edges) {
      result.putIfAbsent(edge.fromStopId, () => <TransitEdge>[]).add(edge);
    }
    return result;
  }

  TransitPattern? patternForRouteAndStop(String routeId, String stopId) {
    for (final pattern in patterns) {
      if (pattern.routeId == routeId && pattern.stopIds.contains(stopId)) {
        return pattern;
      }
    }
    return null;
  }
}

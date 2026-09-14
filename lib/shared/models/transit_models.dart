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

  /// The end of service relative to the operating day.
  ///
  /// GTFS permits times after midnight. Some feeds represent an overnight
  /// service as a smaller clock value instead (for example 23:30 to 06:00),
  /// so normalise that case before using the timetable.
  int get effectiveEndSeconds => endSeconds < startSeconds
      ? endSeconds + Duration.secondsPerDay
      : endSeconds;

  DateTime? nextDeparture(String stopId, DateTime now) {
    // `nextDeparture` is used by route progress and tracking. It permits a
    // departure exactly at [now], but must not promote tomorrow's timetable
    // as a current arrival once today's service has ended.
    final departures = upcomingDepartures(
      stopId,
      now.subtract(const Duration(microseconds: 1)),
      limit: 1,
    );
    return departures.isEmpty ? null : departures.first;
  }

  /// Returns future arrivals at [stopId] from this pattern's static GTFS
  /// schedule. By default the next operating day is excluded so station
  /// details can accurately say when no more service remains today.
  List<DateTime> upcomingDepartures(
    String stopId,
    DateTime now, {
    int limit = 5,
  }) {
    final stopIndex = stopIds.indexOf(stopId);
    if (stopIndex < 0 || limit <= 0) return const [];
    final offset = offsetMinutes[stopIndex] * 60;
    final midnight = DateTime(now.year, now.month, now.day);
    final departures = <DateTime>[];

    // The previous operating day covers services that run after midnight.
    // Do not manufacture a tomorrow arrival after today's service ends.
    for (var dayOffset = -1; dayOffset <= 0; dayOffset++) {
      departures.addAll(
        _upcomingDeparturesOnServiceDay(
          serviceMidnight: midnight.add(Duration(days: dayOffset)),
          offsetSeconds: offset,
          now: now,
          limit: limit,
        ),
      );
    }
    departures.sort();
    final seen = <int>{};
    return [
      for (final departure in departures)
        if (departure.isAfter(now) &&
            seen.add(departure.microsecondsSinceEpoch))
          departure,
    ].take(limit).toList();
  }

  List<DateTime> _upcomingDeparturesOnServiceDay({
    required DateTime serviceMidnight,
    required int offsetSeconds,
    required DateTime now,
    required int limit,
  }) {
    final first = serviceMidnight.add(
      Duration(seconds: startSeconds + offsetSeconds),
    );
    final last = serviceMidnight.add(
      Duration(seconds: effectiveEndSeconds + offsetSeconds),
    );
    if (now.isAfter(last) || limit <= 0) return const [];
    final headway = headwaySeconds;
    if (headway == null || headway <= 0) {
      return first.isAfter(now) ? [first] : const [];
    }
    final firstInterval = now.isBefore(first)
        ? 0
        : now.difference(first).inSeconds ~/ headway + 1;
    final departures = <DateTime>[];
    for (var interval = firstInterval; departures.length < limit; interval++) {
      final departure = first.add(Duration(seconds: interval * headway));
      if (departure.isAfter(last)) break;
      if (departure.isAfter(now)) departures.add(departure);
    }
    return departures;
  }
}

class ScheduledStationArrival {
  final String stationId;
  final TransitPattern pattern;
  final DateTime scheduledArrival;

  const ScheduledStationArrival({
    required this.stationId,
    required this.pattern,
    required this.scheduledArrival,
  });

  String get routeId => pattern.routeId;
  String get tripId => pattern.gtfsTripId;
  String get dedupeKey =>
      '$routeId|$stationId|${scheduledArrival.microsecondsSinceEpoch}';

  int etaMinutesAt(DateTime now) {
    final seconds = scheduledArrival.difference(now).inSeconds;
    if (seconds <= 0) return 0;
    return (seconds / Duration.secondsPerMinute).ceil();
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

  List<ScheduledStationArrival> upcomingArrivalsForStop(
    String stationId, {
    required DateTime now,
    int limit = 5,
  }) {
    if (limit <= 0) return const [];
    final arrivals = <ScheduledStationArrival>[];
    for (final pattern in patterns) {
      if (!pattern.stopIds.contains(stationId)) continue;
      for (final scheduledArrival in pattern.upcomingDepartures(
        stationId,
        now,
        limit: limit,
      )) {
        arrivals.add(
          ScheduledStationArrival(
            stationId: stationId,
            pattern: pattern,
            scheduledArrival: scheduledArrival,
          ),
        );
      }
    }
    arrivals.sort(
      (first, second) =>
          first.scheduledArrival.compareTo(second.scheduledArrival),
    );
    final seen = <String>{};
    return [
      for (final arrival in arrivals)
        if (seen.add(arrival.dedupeKey)) arrival,
    ].take(limit).toList();
  }
}

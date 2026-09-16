enum TrackingSessionStatus { inProgress, completed, cancelled }

extension TrackingSessionStatusValue on TrackingSessionStatus {
  String get value => switch (this) {
    TrackingSessionStatus.inProgress => 'in_progress',
    TrackingSessionStatus.completed => 'completed',
    TrackingSessionStatus.cancelled => 'cancelled',
  };
}

TrackingSessionStatus trackingSessionStatusFromValue(String value) =>
    TrackingSessionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () =>
          throw ArgumentError.value(value, 'status', 'Unknown session status'),
    );

class TrackingSession {
  final String id;
  final String userId;
  final String routeId;
  final String routeName;
  final String mode;
  final String originStopId;
  final String originStopName;
  final String? destinationStopId;
  final String? destinationStopName;
  final TrackingSessionStatus status;
  final String? currentStationName;
  final int stopsCompleted;
  final int totalStops;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final String? notes;

  const TrackingSession({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.routeName,
    required this.mode,
    required this.originStopId,
    required this.originStopName,
    required this.status,
    required this.startedAt,
    this.destinationStopId,
    this.destinationStopName,
    this.currentStationName,
    this.stopsCompleted = 0,
    this.totalStops = 0,
    this.endedAt,
    this.durationMinutes,
    this.notes,
  }) : assert(stopsCompleted >= 0),
       assert(totalStops >= 0);

  bool get isActive => status == TrackingSessionStatus.inProgress;

  TrackingSession copyWith({
    String? destinationStopId,
    String? destinationStopName,
    String? currentStationName,
    int? stopsCompleted,
    TrackingSessionStatus? status,
    DateTime? endedAt,
    int? durationMinutes,
    String? notes,
  }) => TrackingSession(
    id: id,
    userId: userId,
    routeId: routeId,
    routeName: routeName,
    mode: mode,
    originStopId: originStopId,
    originStopName: originStopName,
    destinationStopId: destinationStopId ?? this.destinationStopId,
    destinationStopName: destinationStopName ?? this.destinationStopName,
    status: status ?? this.status,
    currentStationName: currentStationName ?? this.currentStationName,
    stopsCompleted: stopsCompleted ?? this.stopsCompleted,
    totalStops: totalStops,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    notes: notes ?? this.notes,
  );
}

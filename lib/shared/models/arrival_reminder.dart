enum ArrivalReminderStatus { active, triggered, expired, disabled }

class ArrivalReminder {
  final String id;
  final String userId;
  final String stationId;
  final String routeId;
  final DateTime expectedArrival;
  final int leadTimeMinutes;
  final ArrivalReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArrivalReminder({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.routeId,
    required this.expectedArrival,
    required this.leadTimeMinutes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(leadTimeMinutes > 0);

  DateTime get remindAt =>
      expectedArrival.subtract(Duration(minutes: leadTimeMinutes));

  bool get isDemo => id.startsWith('demo:arrival:');

  ArrivalReminderStatus statusAt(DateTime time) {
    if (status == ArrivalReminderStatus.disabled) {
      return ArrivalReminderStatus.disabled;
    }
    if (!expectedArrival.isAfter(time)) return ArrivalReminderStatus.expired;
    if (status == ArrivalReminderStatus.triggered || !remindAt.isAfter(time)) {
      return ArrivalReminderStatus.triggered;
    }
    return ArrivalReminderStatus.active;
  }

  ArrivalReminder copyWith({
    ArrivalReminderStatus? status,
    DateTime? updatedAt,
  }) => ArrivalReminder(
    id: id,
    userId: userId,
    stationId: stationId,
    routeId: routeId,
    expectedArrival: expectedArrival,
    leadTimeMinutes: leadTimeMinutes,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

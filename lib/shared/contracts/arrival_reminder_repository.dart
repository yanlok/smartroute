import '../models/arrival_reminder.dart';

abstract class ArrivalReminderRepository {
  Future<List<ArrivalReminder>> getReminders(String userId);

  Future<ArrivalReminder> createReminder({
    required String userId,
    required String stationId,
    required String routeId,
    required DateTime expectedArrival,
    required int leadTimeMinutes,
  });

  Future<void> updateStatus({
    required String reminderId,
    required ArrivalReminderStatus status,
  });

  Future<void> deleteReminder(String reminderId);
}

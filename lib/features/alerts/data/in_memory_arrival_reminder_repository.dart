import '../../../shared/contracts/arrival_reminder_repository.dart';
import '../../../shared/models/arrival_reminder.dart';

/// Process-local reminder storage for the demonstration build.
///
/// It fulfils the same contract as the Supabase repository, so replacing it
/// with persistent remote storage does not affect the controller or UI.
class InMemoryArrivalReminderRepository implements ArrivalReminderRepository {
  final DateTime Function() _clock;
  final List<ArrivalReminder> _reminders = [];
  int _nextId = 0;

  InMemoryArrivalReminderRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  @override
  Future<List<ArrivalReminder>> getReminders(String userId) async => _sorted([
    for (final reminder in _reminders)
      if (reminder.userId == userId) reminder,
  ]);

  @override
  Future<ArrivalReminder> createReminder({
    required String userId,
    required String stationId,
    required String routeId,
    required DateTime expectedArrival,
    required int leadTimeMinutes,
  }) async {
    final now = _clock();
    final reminder = ArrivalReminder(
      id: 'local:arrival:${++_nextId}',
      userId: userId,
      stationId: stationId,
      routeId: routeId,
      expectedArrival: expectedArrival,
      leadTimeMinutes: leadTimeMinutes,
      status: ArrivalReminderStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    _reminders.add(reminder);
    return reminder;
  }

  @override
  Future<void> updateStatus({
    required String reminderId,
    required ArrivalReminderStatus status,
  }) async {
    final index = _reminders.indexWhere((item) => item.id == reminderId);
    if (index < 0) return;
    _reminders[index] = _reminders[index].copyWith(
      status: status,
      updatedAt: _clock(),
    );
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    _reminders.removeWhere((item) => item.id == reminderId);
  }

  List<ArrivalReminder> _sorted(List<ArrivalReminder> reminders) {
    reminders.sort((a, b) => a.expectedArrival.compareTo(b.expectedArrival));
    return reminders;
  }
}

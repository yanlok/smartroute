import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/arrival_reminder_controller.dart';
import 'package:smartroute/shared/contracts/arrival_reminder_repository.dart';
import 'package:smartroute/shared/models/arrival_reminder.dart';

void main() {
  final now = DateTime(2026, 9, 13, 10);
  late _MemoryReminderRepository repository;
  late ArrivalReminderController controller;

  setUp(() {
    repository = _MemoryReminderRepository(now);
    controller = ArrivalReminderController(
      repository: repository,
      clock: () => now,
    );
  });

  tearDown(() => controller.dispose());

  test('creates and retains a persistent station arrival reminder', () async {
    await controller.load('user-a');

    final created = await controller.create(
      stationId: 'rapid-rail-kl:KJ21',
      routeId: 'rapid-rail-kl:KJ',
      expectedArrival: now.add(const Duration(minutes: 20)),
      leadTimeMinutes: 5,
    );

    expect(created, isTrue);
    expect(repository.reminders, hasLength(1));
    expect(controller.reminders.single.stationId, 'rapid-rail-kl:KJ21');
    expect(controller.reminders.single.status, ArrivalReminderStatus.active);
  });

  test(
    'refresh persists triggered and expired statuses from schedule time',
    () async {
      repository.reminders.addAll([
        _reminder(
          id: 'triggered',
          expectedArrival: now.add(const Duration(minutes: 8)),
          leadTimeMinutes: 10,
        ),
        _reminder(
          id: 'expired',
          expectedArrival: now.subtract(const Duration(minutes: 1)),
          leadTimeMinutes: 5,
        ),
      ]);

      await controller.load('user-a');

      expect(
        controller.reminders
            .firstWhere((item) => item.id == 'triggered')
            .status,
        ArrivalReminderStatus.triggered,
      );
      expect(
        controller.reminders.firstWhere((item) => item.id == 'expired').status,
        ArrivalReminderStatus.expired,
      );
      expect(repository.updatedStatuses, {
        'triggered': ArrivalReminderStatus.triggered,
        'expired': ArrivalReminderStatus.expired,
      });
    },
  );

  test('disables and deletes only the selected persisted reminder', () async {
    final reminder = _reminder(
      id: 'reminder-a',
      expectedArrival: now.add(const Duration(minutes: 20)),
      leadTimeMinutes: 5,
    );
    repository.reminders.add(reminder);
    await controller.load('user-a');

    expect(await controller.disable(reminder), isTrue);
    expect(
      repository.updatedStatuses['reminder-a'],
      ArrivalReminderStatus.disabled,
    );

    expect(await controller.delete(controller.reminders.single), isTrue);
    expect(repository.deletedIds, ['reminder-a']);
    expect(controller.reminders, isEmpty);
  });

  test('creates a removable triggered demo arrival notification', () async {
    final reminder = controller.showDemoArrivalNotification(
      stationId: 'station-a',
      routeId: 'route-a',
      expectedArrival: now.add(const Duration(minutes: 1)),
    );

    expect(reminder.isDemo, isTrue);
    expect(reminder.status, ArrivalReminderStatus.triggered);
    expect(controller.reminders, contains(reminder));
    expect(await controller.disable(reminder), isTrue);
    expect(controller.reminders.single.status, ArrivalReminderStatus.disabled);
    expect(await controller.delete(controller.reminders.single), isTrue);
    expect(controller.reminders, isEmpty);
  });
}

class _MemoryReminderRepository implements ArrivalReminderRepository {
  final DateTime now;
  final List<ArrivalReminder> reminders = [];
  final Map<String, ArrivalReminderStatus> updatedStatuses = {};
  final List<String> deletedIds = [];

  _MemoryReminderRepository(this.now);

  @override
  Future<ArrivalReminder> createReminder({
    required String userId,
    required String stationId,
    required String routeId,
    required DateTime expectedArrival,
    required int leadTimeMinutes,
  }) async {
    final reminder = ArrivalReminder(
      id: 'reminder-${reminders.length}',
      userId: userId,
      stationId: stationId,
      routeId: routeId,
      expectedArrival: expectedArrival,
      leadTimeMinutes: leadTimeMinutes,
      status: ArrivalReminderStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    reminders.add(reminder);
    return reminder;
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    deletedIds.add(reminderId);
    reminders.removeWhere((item) => item.id == reminderId);
  }

  @override
  Future<List<ArrivalReminder>> getReminders(String userId) async => [
    for (final reminder in reminders)
      if (reminder.userId == userId) reminder,
  ];

  @override
  Future<void> updateStatus({
    required String reminderId,
    required ArrivalReminderStatus status,
  }) async {
    updatedStatuses[reminderId] = status;
    final index = reminders.indexWhere((item) => item.id == reminderId);
    reminders[index] = reminders[index].copyWith(
      status: status,
      updatedAt: now,
    );
  }
}

ArrivalReminder _reminder({
  required String id,
  required DateTime expectedArrival,
  required int leadTimeMinutes,
}) => ArrivalReminder(
  id: id,
  userId: 'user-a',
  stationId: 'rapid-rail-kl:KJ21',
  routeId: 'rapid-rail-kl:KJ',
  expectedArrival: expectedArrival,
  leadTimeMinutes: leadTimeMinutes,
  status: ArrivalReminderStatus.active,
  createdAt: expectedArrival.subtract(const Duration(minutes: 30)),
  updatedAt: expectedArrival.subtract(const Duration(minutes: 30)),
);

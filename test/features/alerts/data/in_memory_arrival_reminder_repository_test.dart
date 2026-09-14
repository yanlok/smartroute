import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/data/in_memory_arrival_reminder_repository.dart';
import 'package:smartroute/shared/models/arrival_reminder.dart';

void main() {
  test('keeps reminder lifecycle changes for the active app session', () async {
    final now = DateTime(2026, 9, 14, 10);
    final repository = InMemoryArrivalReminderRepository(clock: () => now);

    final firstReminder = await repository.createReminder(
      userId: 'user-a',
      stationId: 'rapid-rail-kl:KJ21',
      routeId: 'rapid-rail-kl:KJ',
      expectedArrival: now.add(const Duration(minutes: 20)),
      leadTimeMinutes: 5,
    );
    await repository.createReminder(
      userId: 'user-b',
      stationId: 'rapid-rail-kl:KJ22',
      routeId: 'rapid-rail-kl:KJ',
      expectedArrival: now.add(const Duration(minutes: 10)),
      leadTimeMinutes: 5,
    );

    expect(await repository.getReminders('user-a'), [firstReminder]);

    await repository.updateStatus(
      reminderId: firstReminder.id,
      status: ArrivalReminderStatus.disabled,
    );
    expect(
      (await repository.getReminders('user-a')).single.status,
      ArrivalReminderStatus.disabled,
    );

    await repository.deleteReminder(firstReminder.id);
    expect(await repository.getReminders('user-a'), isEmpty);
    expect(await repository.getReminders('user-b'), hasLength(1));
  });
}

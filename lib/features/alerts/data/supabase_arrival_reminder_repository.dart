import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/contracts/arrival_reminder_repository.dart';
import '../../../shared/models/arrival_reminder.dart';

class SupabaseArrivalReminderRepository implements ArrivalReminderRepository {
  final SupabaseClient _client;

  const SupabaseArrivalReminderRepository({required SupabaseClient client})
    : _client = client;

  static const _columns =
      'id, user_id, station_id, route_id, expected_arrival, '
      'lead_time_minutes, status, created_at, updated_at';

  @override
  Future<List<ArrivalReminder>> getReminders(String userId) async {
    try {
      final rows = await _client
          .from('arrival_reminders')
          .select(_columns)
          .eq('user_id', userId)
          .order('expected_arrival');
      return [for (final row in rows) _reminder(row)];
    } catch (_) {
      throw const ArrivalReminderRepositoryException(
        'Arrival reminders could not be loaded.',
      );
    }
  }

  @override
  Future<ArrivalReminder> createReminder({
    required String userId,
    required String stationId,
    required String routeId,
    required DateTime expectedArrival,
    required int leadTimeMinutes,
  }) async {
    try {
      final row = await _client
          .from('arrival_reminders')
          .insert({
            'user_id': userId,
            'station_id': stationId,
            'route_id': routeId,
            'expected_arrival': expectedArrival.toUtc().toIso8601String(),
            'lead_time_minutes': leadTimeMinutes,
            'status': ArrivalReminderStatus.active.name,
          })
          .select(_columns)
          .single();
      return _reminder(row);
    } catch (_) {
      throw const ArrivalReminderRepositoryException(
        'Arrival reminder could not be saved.',
      );
    }
  }

  @override
  Future<void> updateStatus({
    required String reminderId,
    required ArrivalReminderStatus status,
  }) async {
    try {
      await _client
          .from('arrival_reminders')
          .update({'status': status.name})
          .eq('id', reminderId);
    } catch (_) {
      throw const ArrivalReminderRepositoryException(
        'Arrival reminder status could not be updated.',
      );
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _client.from('arrival_reminders').delete().eq('id', reminderId);
    } catch (_) {
      throw const ArrivalReminderRepositoryException(
        'Arrival reminder could not be deleted.',
      );
    }
  }

  ArrivalReminder _reminder(Map<String, dynamic> row) => ArrivalReminder(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    stationId: row['station_id']! as String,
    routeId: row['route_id']! as String,
    expectedArrival: DateTime.parse(row['expected_arrival']! as String),
    leadTimeMinutes: row['lead_time_minutes']! as int,
    status: ArrivalReminderStatus.values.byName(row['status']! as String),
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );
}

class ArrivalReminderRepositoryException implements Exception {
  final String message;

  const ArrivalReminderRepositoryException(this.message);
}

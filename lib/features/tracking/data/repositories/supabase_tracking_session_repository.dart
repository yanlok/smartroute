import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/tracking_session.dart';
import '../../domain/repositories/tracking_session_repository.dart';

class SupabaseTrackingSessionRepository implements TrackingSessionRepository {
  final SupabaseClient _client;

  const SupabaseTrackingSessionRepository({required SupabaseClient client})
    : _client = client;

  static const _columns =
      'id, user_id, route_id, route_name, mode, origin_stop_id, '
      'origin_stop_name, destination_stop_id, destination_stop_name, status, '
      'current_station_name, stops_completed, total_stops, started_at, '
      'ended_at, duration_minutes, notes';

  @override
  Future<TrackingSession> startSession({
    required String userId,
    required String routeId,
    required String routeName,
    required String mode,
    required String originStopId,
    required String originStopName,
    String? destinationStopId,
    String? destinationStopName,
    required int totalStops,
  }) async {
    try {
      final row = await _client
          .from('tracking_sessions')
          .insert({
            'user_id': userId,
            'route_id': routeId,
            'route_name': routeName,
            'mode': mode,
            'origin_stop_id': originStopId,
            'origin_stop_name': originStopName,
            'destination_stop_id': destinationStopId,
            'destination_stop_name': destinationStopName,
            'status': TrackingSessionStatus.inProgress.value,
            'total_stops': totalStops,
          })
          .select(_columns)
          .single();
      return _session(row);
    } catch (_) {
      throw const TrackingSessionRepositoryException(
        'Tracking session could not be started.',
      );
    }
  }

  @override
  Future<TrackingSession> updateProgress({
    required String sessionId,
    required String currentStationName,
    required int stopsCompleted,
  }) async {
    try {
      final row = await _client
          .from('tracking_sessions')
          .update({
            'current_station_name': currentStationName,
            'stops_completed': stopsCompleted,
          })
          .eq('id', sessionId)
          .select(_columns)
          .single();
      return _session(row);
    } catch (_) {
      throw const TrackingSessionRepositoryException(
        'Tracking progress could not be updated.',
      );
    }
  }

  @override
  Future<TrackingSession> completeSession({
    required String sessionId,
    required DateTime endedAt,
    required int durationMinutes,
    String? notes,
    String? destinationStopId,
    String? destinationStopName,
  }) async {
    try {
      final row = await _client
          .from('tracking_sessions')
          .update({
            'status': TrackingSessionStatus.completed.value,
            'ended_at': endedAt.toUtc().toIso8601String(),
            'duration_minutes': durationMinutes,
            if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
            'destination_stop_id': ?destinationStopId,
            'destination_stop_name': ?destinationStopName,
          })
          .eq('id', sessionId)
          .select(_columns)
          .single();
      return _session(row);
    } catch (_) {
      throw const TrackingSessionRepositoryException(
        'Tracking session could not be completed.',
      );
    }
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    try {
      await _client
          .from('tracking_sessions')
          .update({'status': TrackingSessionStatus.cancelled.value})
          .eq('id', sessionId);
    } catch (_) {
      throw const TrackingSessionRepositoryException(
        'Tracking session could not be cancelled.',
      );
    }
  }

  @override
  Future<List<TrackingSession>> getSessionsForUser(String userId) async {
    try {
      final rows = await _client
          .from('tracking_sessions')
          .select(_columns)
          .eq('user_id', userId)
          .order('started_at', ascending: false);
      return [for (final row in rows) _session(row)];
    } catch (_) {
      throw const TrackingSessionRepositoryException(
        'Tracking history could not be loaded.',
      );
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _client.from('tracking_sessions').delete().eq('id', sessionId);
    } catch (_) {
      throw const TrackingSessionRepositoryException(
        'Tracking session could not be deleted.',
      );
    }
  }

  TrackingSession _session(Map<String, dynamic> row) => TrackingSession(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    routeId: row['route_id']! as String,
    routeName: row['route_name']! as String,
    mode: row['mode']! as String,
    originStopId: row['origin_stop_id']! as String,
    originStopName: row['origin_stop_name']! as String,
    destinationStopId: row['destination_stop_id'] as String?,
    destinationStopName: row['destination_stop_name'] as String?,
    status: trackingSessionStatusFromValue(row['status']! as String),
    currentStationName: row['current_station_name'] as String?,
    stopsCompleted: row['stops_completed']! as int,
    totalStops: row['total_stops']! as int,
    startedAt: DateTime.parse(row['started_at']! as String),
    endedAt: row['ended_at'] == null
        ? null
        : DateTime.parse(row['ended_at']! as String),
    durationMinutes: row['duration_minutes'] as int?,
    notes: row['notes'] as String?,
  );
}

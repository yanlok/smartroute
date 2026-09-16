import '../models/tracking_session.dart';

abstract class TrackingSessionRepository {
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
  });

  Future<TrackingSession> updateProgress({
    required String sessionId,
    required String currentStationName,
    required int stopsCompleted,
  });

  Future<TrackingSession> completeSession({
    required String sessionId,
    required DateTime endedAt,
    required int durationMinutes,
    String? notes,
    String? destinationStopId,
    String? destinationStopName,
  });

  Future<void> cancelSession(String sessionId);

  /// Returns the user's sessions ordered by most recent start, one page at
  /// a time. [limit] caps each page and [offset] skips already-fetched rows,
  /// so history never requires one unbounded query.
  Future<List<TrackingSession>> getSessionsForUser(
    String userId, {
    int limit = 10,
    int offset = 0,
  });

  Future<void> deleteSession(String sessionId);
}

class TrackingSessionRepositoryException implements Exception {
  final String message;

  const TrackingSessionRepositoryException(this.message);
}

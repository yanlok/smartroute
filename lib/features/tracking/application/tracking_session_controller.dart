import 'package:flutter/foundation.dart';

import '../domain/models/tracking_session.dart';
import '../domain/repositories/tracking_session_repository.dart';

class TrackingSessionController extends ChangeNotifier {
  final TrackingSessionRepository _repository;
  final DateTime Function() _clock;

  /// Number of past sessions fetched per repository page.
  static const int historyPageSize = 10;

  TrackingSession? _activeSession;
  List<TrackingSession> _pastSessions = const <TrackingSession>[];
  String? _userId;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingMore = false;
  bool _hasMoreSessions = false;
  int _fetchedSessionCount = 0;
  String? _errorMessage;

  TrackingSessionController({
    required TrackingSessionRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  TrackingSession? get activeSession => _activeSession;
  List<TrackingSession> get pastSessions => List.unmodifiable(_pastSessions);
  String? get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoadingMoreSessions => _isLoadingMore;
  bool get hasMoreSessions => _hasMoreSessions;
  String? get errorMessage => _errorMessage;

  Future<void> load(String userId) async {
    if (_isLoading) return;
    _isLoading = true;
    _userId = userId;
    _errorMessage = null;
    notifyListeners();
    try {
      // The active session is the most recently started session, so it is
      // always contained in the first history page.
      final page = await _repository.getSessionsForUser(
        userId,
        limit: historyPageSize,
      );
      _fetchedSessionCount = page.length;
      _hasMoreSessions = page.length >= historyPageSize;
      _activeSession = page.where((session) => session.isActive).firstOrNull;
      _pastSessions = page
          .where((session) => !session.isActive)
          .toList(growable: false);
    } catch (_) {
      _errorMessage = 'Tracking history could not be loaded. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    final userId = _userId;
    if (userId != null) await load(userId);
  }

  /// Fetches the next page of past sessions. Rows already known locally are
  /// skipped so an offset shift caused by newly recorded sessions cannot
  /// duplicate history entries.
  Future<void> loadMoreSessions() async {
    if (_isLoadingMore || !_hasMoreSessions) return;
    final userId = _userId;
    if (userId == null) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.getSessionsForUser(
        userId,
        limit: historyPageSize,
        offset: _fetchedSessionCount,
      );
      _fetchedSessionCount += page.length;
      _hasMoreSessions = page.length >= historyPageSize;
      final knownIds = {for (final session in _pastSessions) session.id};
      final fresh = page
          .where(
            (session) => !session.isActive && !knownIds.contains(session.id),
          )
          .toList(growable: false);
      if (fresh.isNotEmpty) {
        _pastSessions = [..._pastSessions, ...fresh];
      }
    } catch (_) {
      _errorMessage = 'Older session history could not be loaded. Try again.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Creates a session for [routeId], or adopts the already active session
  /// for the same route. An active session on a different route is cancelled
  /// first so only one live session exists per user.
  Future<TrackingSession?> ensureActiveSession({
    required String routeId,
    required String routeName,
    required String mode,
    required String originStopId,
    required String originStopName,
    String? destinationStopId,
    String? destinationStopName,
    required int totalStops,
  }) async {
    final userId = _userId;
    if (userId == null || _isSaving) return null;

    final active = _activeSession;
    if (active != null) {
      if (active.routeId == routeId) return active;
      _isSaving = true;
      notifyListeners();
      try {
        await _repository.cancelSession(active.id);
        _pastSessions = [
          active.copyWith(status: TrackingSessionStatus.cancelled),
          ..._pastSessions,
        ];
      } catch (_) {
        _errorMessage = 'The previous session could not be closed.';
        _isSaving = false;
        notifyListeners();
        return null;
      }
      _isSaving = false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final session = await _repository.startSession(
        userId: userId,
        routeId: routeId,
        routeName: routeName,
        mode: mode,
        originStopId: originStopId,
        originStopName: originStopName,
        destinationStopId: destinationStopId,
        destinationStopName: destinationStopName,
        totalStops: totalStops,
      );
      _activeSession = session;
      // The repository gained one new (newest) row, so shift the next
      // history page window to keep offset-based paging aligned.
      _fetchedSessionCount += 1;
      return session;
    } catch (_) {
      _errorMessage = 'Tracking session could not be started. Try again.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Records a station arrival on the active session. Automatically completes
  /// the session when the arrived stop is the session destination.
  Future<void> recordStationArrival({
    required String stopId,
    required String stationName,
    required int stopsCompleted,
  }) async {
    final session = _activeSession;
    if (session == null) return;
    if (session.currentStationName == stationName &&
        session.stopsCompleted == stopsCompleted) {
      return;
    }

    if (session.destinationStopId != null &&
        session.destinationStopId == stopId) {
      await _complete(session, notes: null);
      return;
    }

    final updated = session.copyWith(
      currentStationName: stationName,
      stopsCompleted: stopsCompleted,
    );
    _activeSession = updated;
    notifyListeners();
    try {
      final saved = await _repository.updateProgress(
        sessionId: session.id,
        currentStationName: stationName,
        stopsCompleted: stopsCompleted,
      );
      if (_activeSession?.id == saved.id) {
        _activeSession = saved;
        notifyListeners();
      }
    } catch (_) {
      // Keep the optimistic local progress; the next station arrival retries.
    }
  }

  /// Ends the active session. When [endStopId]/[endStopName] describe where
  /// the commute actually finished (e.g. the train's current station when the
  /// rider got off early), they override the session's planned destination in
  /// the completed record.
  Future<bool> endCommute({
    String? notes,
    String? endStopId,
    String? endStopName,
  }) async {
    final session = _activeSession;
    if (session == null) return true;
    return _complete(
      session,
      notes: notes,
      endStopId: endStopId,
      endStopName: endStopName,
    );
  }

  Future<bool> _complete(
    TrackingSession session, {
    String? notes,
    String? endStopId,
    String? endStopName,
  }) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    final endedAt = _clock();
    final durationMinutes = endedAt.difference(session.startedAt).inMinutes;
    try {
      final saved = await _repository.completeSession(
        sessionId: session.id,
        endedAt: endedAt,
        durationMinutes: durationMinutes < 0 ? 0 : durationMinutes,
        notes: notes,
        destinationStopId: endStopId ?? session.destinationStopId,
        destinationStopName: endStopName ?? session.destinationStopName,
      );
      if (_activeSession?.id == saved.id) _activeSession = null;
      _pastSessions = [saved, ..._pastSessions];
      return true;
    } catch (_) {
      _errorMessage = 'The commute could not be completed. Try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSession(TrackingSession session) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteSession(session.id);
      _pastSessions = _pastSessions
          .where((item) => item.id != session.id)
          .toList(growable: false);
      return true;
    } catch (_) {
      _errorMessage = 'Tracking session could not be deleted. Try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _activeSession = null;
    _pastSessions = const [];
    _userId = null;
    _isLoading = false;
    _isSaving = false;
    _isLoadingMore = false;
    _hasMoreSessions = false;
    _fetchedSessionCount = 0;
    _errorMessage = null;
    notifyListeners();
  }
}

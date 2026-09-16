import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/tracking_session_controller.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_session.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_session_repository.dart';

class InMemoryTrackingSessionRepository implements TrackingSessionRepository {
  final List<Map<String, dynamic>> store = [];
  final List<Map<String, dynamic>> updateCalls = [];
  final List<String> cancelCalls = [];
  final List<String> deleteCalls = [];
  bool failNextOperation = false;
  int idCounter = 0;

  TrackingSession _fromRow(Map<String, dynamic> row) => TrackingSession(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    routeId: row['route_id']! as String,
    routeName: row['route_name']! as String,
    mode: row['mode']! as String,
    originStopId: row['origin_stop_id']! as String,
    originStopName: row['origin_stop_name']! as String,
    destinationStopId: row['destination_stop_id'] as String?,
    destinationStopName: row['destination_stop_name'] as String?,
    status: TrackingSessionStatus.values.byName(row['status']! as String),
    currentStationName: row['current_station_name'] as String?,
    stopsCompleted: row['stops_completed']! as int,
    totalStops: row['total_stops']! as int,
    startedAt: row['started_at']! as DateTime,
    endedAt: row['ended_at'] as DateTime?,
    durationMinutes: row['duration_minutes'] as int?,
    notes: row['notes'] as String?,
  );

  Map<String, dynamic>? _find(String id) {
    for (final row in store) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  void _failIfNeeded() {
    if (failNextOperation) {
      failNextOperation = false;
      throw const TrackingSessionRepositoryException('Injected failure');
    }
  }

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
    _failIfNeeded();
    final row = {
      'id': 'session-${++idCounter}',
      'user_id': userId,
      'route_id': routeId,
      'route_name': routeName,
      'mode': mode,
      'origin_stop_id': originStopId,
      'origin_stop_name': originStopName,
      'destination_stop_id': destinationStopId,
      'destination_stop_name': destinationStopName,
      'status': TrackingSessionStatus.inProgress.name,
      'current_station_name': null,
      'stops_completed': 0,
      'total_stops': totalStops,
      'started_at': DateTime(2026, 9, 15, 8),
      'ended_at': null,
      'duration_minutes': null,
      'notes': null,
    };
    store.add(row);
    return _fromRow(row);
  }

  @override
  Future<TrackingSession> updateProgress({
    required String sessionId,
    required String currentStationName,
    required int stopsCompleted,
  }) async {
    _failIfNeeded();
    updateCalls.add({
      'sessionId': sessionId,
      'station': currentStationName,
      'stops': stopsCompleted,
    });
    final row = _find(sessionId)!;
    row['current_station_name'] = currentStationName;
    row['stops_completed'] = stopsCompleted;
    return _fromRow(row);
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
    _failIfNeeded();
    final row = _find(sessionId)!;
    row['status'] = TrackingSessionStatus.completed.name;
    row['ended_at'] = endedAt;
    row['duration_minutes'] = durationMinutes;
    row['notes'] = notes;
    if (destinationStopId != null) {
      row['destination_stop_id'] = destinationStopId;
    }
    if (destinationStopName != null) {
      row['destination_stop_name'] = destinationStopName;
    }
    return _fromRow(row);
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    _failIfNeeded();
    cancelCalls.add(sessionId);
    _find(sessionId)!['status'] = TrackingSessionStatus.cancelled.name;
  }

  @override
  Future<List<TrackingSession>> getSessionsForUser(String userId) async {
    _failIfNeeded();
    return [
      for (final row in store.where((row) => row['user_id'] == userId))
        _fromRow(row),
    ];
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _failIfNeeded();
    deleteCalls.add(sessionId);
    store.removeWhere((row) => row['id'] == sessionId);
  }
}

InMemoryTrackingSessionRepository _repoWithHistory() {
  final repository = InMemoryTrackingSessionRepository();
  repository.store.addAll([
    {
      'id': 'done-1',
      'user_id': 'user-1',
      'route_id': 'rapid-rail-kl:KJ',
      'route_name': 'Kelana Jaya Line',
      'mode': 'lrt',
      'origin_stop_id': 'rapid-rail-kl:KJ14',
      'origin_stop_name': 'Pasar Seni',
      'destination_stop_id': 'rapid-rail-kl:KJ24',
      'destination_stop_name': 'Kelana Jaya',
      'status': TrackingSessionStatus.completed.name,
      'current_station_name': 'Kelana Jaya',
      'stops_completed': 17,
      'total_stops': 18,
      'started_at': DateTime(2026, 9, 14, 8),
      'ended_at': DateTime(2026, 9, 14, 8, 25),
      'duration_minutes': 25,
      'notes': 'Morning commute',
    },
    {
      'id': 'active-1',
      'user_id': 'user-1',
      'route_id': 'rapid-rail-kl:KJ',
      'route_name': 'Kelana Jaya Line',
      'mode': 'lrt',
      'origin_stop_id': 'rapid-rail-kl:KJ14',
      'origin_stop_name': 'Pasar Seni',
      'destination_stop_id': 'rapid-rail-kl:KJ24',
      'destination_stop_name': 'Kelana Jaya',
      'status': TrackingSessionStatus.inProgress.name,
      'current_station_name': 'Pasar Seni',
      'stops_completed': 0,
      'total_stops': 18,
      'started_at': DateTime(2026, 9, 15, 8),
      'ended_at': null,
      'duration_minutes': null,
      'notes': null,
    },
    {
      'id': 'other-user',
      'user_id': 'user-2',
      'route_id': 'rapid-rail-kl:KJ',
      'route_name': 'Kelana Jaya Line',
      'mode': 'lrt',
      'origin_stop_id': 'rapid-rail-kl:KJ14',
      'origin_stop_name': 'Pasar Seni',
      'status': TrackingSessionStatus.inProgress.name,
      'current_station_name': null,
      'stops_completed': 0,
      'total_stops': 18,
      'started_at': DateTime(2026, 9, 15, 9),
      'ended_at': null,
      'duration_minutes': null,
      'notes': null,
    },
  ]);
  return repository;
}

void main() {
  late InMemoryTrackingSessionRepository repository;
  late TrackingSessionController controller;

  setUp(() {
    repository = _repoWithHistory();
    controller = TrackingSessionController(
      repository: repository,
      clock: () => DateTime(2026, 9, 15, 8, 25),
    );
  });

  group('TrackingSessionController - load', () {
    test(
      'splits active session from past sessions and hides other users',
      () async {
        await controller.load('user-1');

        expect(controller.isLoading, isFalse);
        expect(controller.activeSession?.id, 'active-1');
        expect(controller.pastSessions.map((s) => s.id), ['done-1']);
      },
    );

    test('sets a friendly error message when loading fails', () async {
      repository.failNextOperation = true;

      await controller.load('user-1');

      expect(controller.activeSession, isNull);
      expect(
        controller.errorMessage,
        'Tracking history could not be loaded. Try again.',
      );
    });
  });

  group('TrackingSessionController - ensureActiveSession', () {
    test(
      'adopts the existing in-progress session for the same route',
      () async {
        await controller.load('user-1');

        final session = await controller.ensureActiveSession(
          routeId: 'rapid-rail-kl:KJ',
          routeName: 'Kelana Jaya Line',
          mode: 'lrt',
          originStopId: 'rapid-rail-kl:KJ14',
          originStopName: 'Pasar Seni',
          totalStops: 18,
        );

        expect(session?.id, 'active-1');
        expect(repository.store, hasLength(3));
      },
    );

    test('creates a new session when none is active', () async {
      await controller.load('user-1');
      controller.reset();
      await controller.load('user-1');
      await controller.endCommute();

      final session = await controller.ensureActiveSession(
        routeId: 'rapid-rail-kl:KJ',
        routeName: 'Kelana Jaya Line',
        mode: 'lrt',
        originStopId: 'rapid-rail-kl:KJ14',
        originStopName: 'Pasar Seni',
        destinationStopId: 'rapid-rail-kl:KJ24',
        destinationStopName: 'Kelana Jaya',
        totalStops: 18,
      );

      expect(session, isNotNull);
      expect(controller.activeSession?.id, session?.id);
      expect(
        controller.activeSession?.status,
        TrackingSessionStatus.inProgress,
      );
    });

    test(
      'cancels the active session on another route before starting',
      () async {
        await controller.load('user-1');

        final session = await controller.ensureActiveSession(
          routeId: 'rapid-bus-kl:300',
          routeName: 'Bus 300',
          mode: 'bus',
          originStopId: 'rapid-bus-kl:100',
          originStopName: 'Kotaraya',
          totalStops: 10,
        );

        expect(repository.cancelCalls, ['active-1']);
        expect(session?.routeId, 'rapid-bus-kl:300');
        expect(controller.activeSession?.routeId, 'rapid-bus-kl:300');
        expect(
          controller.pastSessions.any(
            (item) =>
                item.id == 'active-1' &&
                item.status == TrackingSessionStatus.cancelled,
          ),
          isTrue,
        );
      },
    );

    test('exposes an error message when starting fails', () async {
      await controller.load('user-1');
      await controller.endCommute();
      repository.failNextOperation = true;

      final session = await controller.ensureActiveSession(
        routeId: 'rapid-rail-kl:KJ',
        routeName: 'Kelana Jaya Line',
        mode: 'lrt',
        originStopId: 'rapid-rail-kl:KJ14',
        originStopName: 'Pasar Seni',
        totalStops: 18,
      );

      expect(session, isNull);
      expect(controller.activeSession, isNull);
      expect(
        controller.errorMessage,
        'Tracking session could not be started. Try again.',
      );
    });

    test(
      'ignores overlapping ensure calls while a switch is in flight',
      () async {
        await controller.load('user-1');

        // First call switches the active session to another route; while it
        // awaits the repository, a second call must not adopt the stale
        // session or start a duplicate one.
        final first = controller.ensureActiveSession(
          routeId: 'rapid-bus-kl:300',
          routeName: 'Bus 300',
          mode: 'bus',
          originStopId: 'rapid-bus-kl:100',
          originStopName: 'Kotaraya',
          totalStops: 10,
        );
        final second = await controller.ensureActiveSession(
          routeId: 'rapid-mrt-kl:SBK',
          routeName: 'Kajang Line',
          mode: 'mrt',
          originStopId: 'rapid-mrt-kl:SBK1',
          originStopName: 'Sungai Buloh',
          totalStops: 8,
        );

        expect(second, isNull);
        expect(
          controller.pastSessions.any(
            (item) =>
                item.id == 'active-1' &&
                item.status == TrackingSessionStatus.cancelled,
          ),
          isTrue,
        );

        final switched = await first;
        expect(switched?.routeId, 'rapid-bus-kl:300');
        expect(controller.activeSession?.routeId, 'rapid-bus-kl:300');
        expect(
          repository.store.where(
            (row) =>
                row['user_id'] == 'user-1' &&
                row['status'] == TrackingSessionStatus.inProgress.name,
          ),
          hasLength(1),
        );
      },
    );
  });

  group('TrackingSessionController - recordStationArrival', () {
    test('optimistically updates and persists progress', () async {
      await controller.load('user-1');
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.recordStationArrival(
        stopId: 'rapid-rail-kl:KJ15',
        stationName: 'Masjid Jamek',
        stopsCompleted: 1,
      );

      expect(controller.activeSession?.currentStationName, 'Masjid Jamek');
      expect(controller.activeSession?.stopsCompleted, 1);
      expect(repository.updateCalls, hasLength(1));
      expect(notified, greaterThan(0));
    });

    test('ignores repeated arrivals for the same station', () async {
      await controller.load('user-1');

      await controller.recordStationArrival(
        stopId: 'rapid-rail-kl:KJ15',
        stationName: 'Masjid Jamek',
        stopsCompleted: 1,
      );
      await controller.recordStationArrival(
        stopId: 'rapid-rail-kl:KJ15',
        stationName: 'Masjid Jamek',
        stopsCompleted: 1,
      );

      expect(repository.updateCalls, hasLength(1));
    });

    test('auto-completes when arriving at the destination stop', () async {
      await controller.load('user-1');

      await controller.recordStationArrival(
        stopId: 'rapid-rail-kl:KJ24',
        stationName: 'Kelana Jaya',
        stopsCompleted: 17,
      );

      expect(controller.activeSession, isNull);
      expect(
        controller.pastSessions.first.status,
        TrackingSessionStatus.completed,
      );
      expect(controller.pastSessions.first.id, 'active-1');
      expect(repository.updateCalls, isEmpty);
    });

    test('does nothing without an active session', () async {
      await controller.recordStationArrival(
        stopId: 'rapid-rail-kl:KJ15',
        stationName: 'Masjid Jamek',
        stopsCompleted: 1,
      );

      expect(repository.updateCalls, isEmpty);
    });
  });

  group('TrackingSessionController - endCommute', () {
    test('completes the active session with duration and notes', () async {
      await controller.load('user-1');

      final success = await controller.endCommute(notes: 'Arrived early');

      expect(success, isTrue);
      expect(controller.activeSession, isNull);
      expect(controller.pastSessions.first.id, 'active-1');
      expect(controller.pastSessions.first.notes, 'Arrived early');
      expect(controller.pastSessions.first.durationMinutes, 25);
    });

    test('returns true when there is nothing to end', () async {
      final success = await controller.endCommute();

      expect(success, isTrue);
    });

    test('keeps the session active and reports an error on failure', () async {
      await controller.load('user-1');
      repository.failNextOperation = true;

      final success = await controller.endCommute();

      expect(success, isFalse);
      expect(controller.activeSession?.id, 'active-1');
      expect(
        controller.errorMessage,
        'The commute could not be completed. Try again.',
      );
    });
  });

  group('TrackingSessionController - deleteSession', () {
    test('removes the session from history and the store', () async {
      await controller.load('user-1');
      final target = controller.pastSessions.first;

      final success = await controller.deleteSession(target);

      expect(success, isTrue);
      expect(controller.pastSessions, isEmpty);
      expect(repository.deleteCalls, ['done-1']);
    });

    test('reports an error when deletion fails', () async {
      await controller.load('user-1');
      repository.failNextOperation = true;

      final success = await controller.deleteSession(
        controller.pastSessions.first,
      );

      expect(success, isFalse);
      expect(
        controller.errorMessage,
        'Tracking session could not be deleted. Try again.',
      );
      expect(controller.pastSessions, hasLength(1));
    });
  });

  test('reset clears all state', () async {
    await controller.load('user-1');

    controller.reset();

    expect(controller.activeSession, isNull);
    expect(controller.pastSessions, isEmpty);
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });
}

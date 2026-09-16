import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/data/repositories/supabase_tracking_session_repository.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_session.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final FakeTrackingSessionsQuery trackingQuery;

  FakeSupabaseClient(this.trackingQuery);

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'tracking_sessions') return trackingQuery;
    throw UnimplementedError('Table $table not configured');
  }
}

class _FakeQueryState {
  Map<String, dynamic>? singleRow;
  List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  bool shouldThrow = false;
  Map<String, dynamic>? lastInsertPayload;
  Map<String, dynamic>? lastUpdatePayload;
  int deleteCallCount = 0;
  int? lastRangeStart;
  int? lastRangeEnd;
}

class FakeTrackingSessionsQuery extends Fake implements SupabaseQueryBuilder {
  final _FakeQueryState _state = _FakeQueryState();

  Map<String, dynamic>? get singleRow => _state.singleRow;
  set singleRow(Map<String, dynamic>? value) => _state.singleRow = value;
  List<Map<String, dynamic>> get rows => _state.rows;
  set rows(List<Map<String, dynamic>> value) => _state.rows = value;
  bool get shouldThrow => _state.shouldThrow;
  set shouldThrow(bool value) => _state.shouldThrow = value;
  Map<String, dynamic>? get lastInsertPayload => _state.lastInsertPayload;
  Map<String, dynamic>? get lastUpdatePayload => _state.lastUpdatePayload;
  int get deleteCallCount => _state.deleteCallCount;
  int? get lastRangeStart => _state.lastRangeStart;
  int? get lastRangeEnd => _state.lastRangeEnd;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return _FakePostgrestFilterBuilder(state: _state);
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    _state.lastInsertPayload = Map<String, dynamic>.from(values as Map);
    return _FakePostgrestFilterBuilder(state: _state);
  }

  @override
  PostgrestFilterBuilder<dynamic> update(Map<dynamic, dynamic> values) {
    _state.lastUpdatePayload = Map<String, dynamic>.from(values);
    return _FakePostgrestFilterBuilder(state: _state);
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() {
    _state.deleteCallCount++;
    return _FakePostgrestFilterBuilder(state: _state);
  }
}

class _FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final _FakeQueryState _state;

  _FakePostgrestFilterBuilder({required _FakeQueryState state})
    : _state = state;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return _FakeListTransformBuilder(state: _state);
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return _FakeListTransformBuilder(state: _state);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    final future = _state.shouldThrow
        ? Future<List<Map<String, dynamic>>>.error(
            Exception('Postgrest query error'),
          )
        : Future.value(_state.rows);
    return future.then(onValue, onError: onError);
  }
}

class _FakeListTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final _FakeQueryState _state;

  _FakeListTransformBuilder({required _FakeQueryState state}) : _state = state;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> range(
    int start,
    int end, {
    String? referencedTable,
  }) {
    _state.lastRangeStart = start;
    _state.lastRangeEnd = end;
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return _FakeSingleTransformBuilder(state: _state);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    final future = _state.shouldThrow
        ? Future<List<Map<String, dynamic>>>.error(
            Exception('Postgrest query error'),
          )
        : Future.value(_state.rows);
    return future.then(onValue, onError: onError);
  }
}

class _FakeSingleTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final _FakeQueryState _state;

  _FakeSingleTransformBuilder({required _FakeQueryState state})
    : _state = state;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic> value) onValue, {
    Function? onError,
  }) {
    final row = _state.singleRow;
    final future = _state.shouldThrow
        ? Future<Map<String, dynamic>>.error(Exception('Postgrest error'))
        : row == null
        ? Future<Map<String, dynamic>>.error(
            Exception('Expected a single row but got none'),
          )
        : Future.value(row);
    return future.then(onValue, onError: onError);
  }
}

Map<String, dynamic> _row({
  String id = 'session-1',
  String status = 'in_progress',
  String? currentStationName,
  int stopsCompleted = 0,
  String? notes,
  String? destinationStopId,
  String? destinationStopName,
}) => {
  'id': id,
  'user_id': 'user-1',
  'route_id': 'rapid-rail-kl:KJ',
  'route_name': 'Kelana Jaya Line',
  'mode': 'lrt',
  'origin_stop_id': 'rapid-rail-kl:KJ14',
  'origin_stop_name': 'Pasar Seni',
  'destination_stop_id': destinationStopId ?? 'rapid-rail-kl:KJ24',
  'destination_stop_name': destinationStopName ?? 'Kelana Jaya',
  'status': status,
  'current_station_name': currentStationName,
  'stops_completed': stopsCompleted,
  'total_stops': 18,
  'started_at': '2026-09-15T00:00:00.000Z',
  'ended_at': null,
  'duration_minutes': null,
  'notes': notes,
};

void main() {
  late FakeSupabaseClient fakeClient;
  late FakeTrackingSessionsQuery fakeQuery;
  late SupabaseTrackingSessionRepository repository;

  setUp(() {
    fakeQuery = FakeTrackingSessionsQuery();
    fakeClient = FakeSupabaseClient(fakeQuery);
    repository = SupabaseTrackingSessionRepository(client: fakeClient);
  });

  group('SupabaseTrackingSessionRepository - startSession', () {
    test(
      'inserts an in-progress session row and maps the returned entity',
      () async {
        fakeQuery.singleRow = _row();

        final session = await repository.startSession(
          userId: 'user-1',
          routeId: 'rapid-rail-kl:KJ',
          routeName: 'Kelana Jaya Line',
          mode: 'lrt',
          originStopId: 'rapid-rail-kl:KJ14',
          originStopName: 'Pasar Seni',
          destinationStopId: 'rapid-rail-kl:KJ24',
          destinationStopName: 'Kelana Jaya',
          totalStops: 18,
        );

        expect(session.id, 'session-1');
        expect(session.status, TrackingSessionStatus.inProgress);
        expect(session.routeName, 'Kelana Jaya Line');
        expect(session.totalStops, 18);
        expect(fakeQuery.lastInsertPayload?['user_id'], 'user-1');
        expect(fakeQuery.lastInsertPayload?['status'], 'in_progress');
        expect(fakeQuery.lastInsertPayload?['total_stops'], 18);
      },
    );

    test('throws a safe repository exception on database failure', () async {
      fakeQuery.shouldThrow = true;

      await expectLater(
        repository.startSession(
          userId: 'user-1',
          routeId: 'rapid-rail-kl:KJ',
          routeName: 'Kelana Jaya Line',
          mode: 'lrt',
          originStopId: 'rapid-rail-kl:KJ14',
          originStopName: 'Pasar Seni',
          totalStops: 18,
        ),
        throwsA(
          isA<TrackingSessionRepositoryException>().having(
            (e) => e.message,
            'message',
            'Tracking session could not be started.',
          ),
        ),
      );
    });
  });

  group('SupabaseTrackingSessionRepository - updateProgress', () {
    test('updates station and stop count and maps the saved row', () async {
      fakeQuery.singleRow = _row(
        currentStationName: 'Asia Jaya',
        stopsCompleted: 6,
      );

      final session = await repository.updateProgress(
        sessionId: 'session-1',
        currentStationName: 'Asia Jaya',
        stopsCompleted: 6,
      );

      expect(session.currentStationName, 'Asia Jaya');
      expect(session.stopsCompleted, 6);
      expect(fakeQuery.lastUpdatePayload?['current_station_name'], 'Asia Jaya');
      expect(fakeQuery.lastUpdatePayload?['stops_completed'], 6);
    });

    test('throws a safe repository exception on failure', () async {
      fakeQuery.shouldThrow = true;

      await expectLater(
        repository.updateProgress(
          sessionId: 'session-1',
          currentStationName: 'Asia Jaya',
          stopsCompleted: 6,
        ),
        throwsA(
          isA<TrackingSessionRepositoryException>().having(
            (e) => e.message,
            'message',
            'Tracking progress could not be updated.',
          ),
        ),
      );
    });
  });

  group('SupabaseTrackingSessionRepository - completeSession', () {
    test('writes completed status, end time, duration and notes', () async {
      fakeQuery.singleRow = _row(
        status: 'completed',
        currentStationName: 'Kelana Jaya',
        stopsCompleted: 17,
        notes: 'Smooth ride',
      );

      final session = await repository.completeSession(
        sessionId: 'session-1',
        endedAt: DateTime(2026, 9, 15, 8, 24),
        durationMinutes: 24,
        notes: '  Smooth ride  ',
      );

      expect(session.status, TrackingSessionStatus.completed);
      expect(session.notes, 'Smooth ride');
      expect(fakeQuery.lastUpdatePayload?['status'], 'completed');
      expect(fakeQuery.lastUpdatePayload?['duration_minutes'], 24);
      expect(fakeQuery.lastUpdatePayload?['notes'], 'Smooth ride');
      expect(fakeQuery.lastUpdatePayload?['ended_at'], isNotNull);
    });

    test('omits notes when none are provided', () async {
      fakeQuery.singleRow = _row(status: 'completed');

      await repository.completeSession(
        sessionId: 'session-1',
        endedAt: DateTime(2026, 9, 15, 8, 24),
        durationMinutes: 24,
      );

      expect(fakeQuery.lastUpdatePayload?.containsKey('notes'), isFalse);
    });

    test(
      'persists the actual end station when the commute ends early',
      () async {
        fakeQuery.singleRow = _row(
          status: 'completed',
          currentStationName: 'Bandaraya',
          stopsCompleted: 12,
          destinationStopId: 'rapid-rail-kl:KJ12',
          destinationStopName: 'Bandaraya',
        );

        final session = await repository.completeSession(
          sessionId: 'session-1',
          endedAt: DateTime(2026, 9, 15, 8, 24),
          durationMinutes: 24,
          destinationStopId: 'rapid-rail-kl:KJ12',
          destinationStopName: 'Bandaraya',
        );

        expect(session.destinationStopName, 'Bandaraya');
        expect(
          fakeQuery.lastUpdatePayload?['destination_stop_id'],
          'rapid-rail-kl:KJ12',
        );
        expect(
          fakeQuery.lastUpdatePayload?['destination_stop_name'],
          'Bandaraya',
        );
      },
    );

    test('throws a safe repository exception on failure', () async {
      fakeQuery.shouldThrow = true;

      await expectLater(
        repository.completeSession(
          sessionId: 'session-1',
          endedAt: DateTime(2026, 9, 15, 8, 24),
          durationMinutes: 24,
        ),
        throwsA(
          isA<TrackingSessionRepositoryException>().having(
            (e) => e.message,
            'message',
            'Tracking session could not be completed.',
          ),
        ),
      );
    });
  });

  group('SupabaseTrackingSessionRepository - cancelSession', () {
    test('writes the cancelled status', () async {
      await repository.cancelSession('session-1');

      expect(fakeQuery.lastUpdatePayload?['status'], 'cancelled');
    });
  });

  group('SupabaseTrackingSessionRepository - getSessionsForUser', () {
    test(
      'applies the default first-page range and maps rows in server order',
      () async {
        fakeQuery.rows = [
          _row(id: 'session-2', status: 'completed'),
          _row(id: 'session-1'),
        ];

        final sessions = await repository.getSessionsForUser('user-1');

        expect(fakeQuery.lastRangeStart, 0);
        expect(fakeQuery.lastRangeEnd, 9);
        expect(sessions, hasLength(2));
        expect(sessions[0].id, 'session-2');
        expect(sessions[0].status, TrackingSessionStatus.completed);
        expect(sessions[1].id, 'session-1');
        expect(
          sessions[1].startedAt,
          DateTime.parse('2026-09-15T00:00:00.000Z'),
        );
      },
    );

    test('applies the requested limit and offset window', () async {
      await repository.getSessionsForUser('user-1', limit: 5, offset: 10);

      expect(fakeQuery.lastRangeStart, 10);
      expect(fakeQuery.lastRangeEnd, 14);
    });

    test('throws a safe repository exception on failure', () async {
      fakeQuery.shouldThrow = true;

      await expectLater(
        repository.getSessionsForUser('user-1'),
        throwsA(
          isA<TrackingSessionRepositoryException>().having(
            (e) => e.message,
            'message',
            'Tracking history could not be loaded.',
          ),
        ),
      );
    });
  });

  group('SupabaseTrackingSessionRepository - deleteSession', () {
    test('issues a delete filtered by session id', () async {
      await repository.deleteSession('session-1');

      expect(fakeQuery.deleteCallCount, 1);
    });

    test('throws a safe repository exception on failure', () async {
      fakeQuery.shouldThrow = true;

      await expectLater(
        repository.deleteSession('session-1'),
        throwsA(
          isA<TrackingSessionRepositoryException>().having(
            (e) => e.message,
            'message',
            'Tracking session could not be deleted.',
          ),
        ),
      );
    });
  });
}

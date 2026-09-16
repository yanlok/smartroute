import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_session.dart';

TrackingSession _session({
  TrackingSessionStatus status = TrackingSessionStatus.inProgress,
  int stopsCompleted = 0,
  String? currentStationName,
}) => TrackingSession(
  id: 'session-1',
  userId: 'user-1',
  routeId: 'rapid-rail-kl:KJ',
  routeName: 'Kelana Jaya Line',
  mode: 'lrt',
  originStopId: 'rapid-rail-kl:KJ14',
  originStopName: 'Pasar Seni',
  destinationStopId: 'rapid-rail-kl:KJ24',
  destinationStopName: 'Kelana Jaya',
  status: status,
  totalStops: 18,
  stopsCompleted: stopsCompleted,
  currentStationName: currentStationName,
  startedAt: DateTime(2026, 9, 15, 8),
);

void main() {
  group('TrackingSessionStatus mapping', () {
    test('maps enum values to database strings and back', () {
      expect(TrackingSessionStatus.inProgress.value, 'in_progress');
      expect(TrackingSessionStatus.completed.value, 'completed');
      expect(TrackingSessionStatus.cancelled.value, 'cancelled');

      expect(
        trackingSessionStatusFromValue('in_progress'),
        TrackingSessionStatus.inProgress,
      );
      expect(
        trackingSessionStatusFromValue('completed'),
        TrackingSessionStatus.completed,
      );
      expect(
        trackingSessionStatusFromValue('cancelled'),
        TrackingSessionStatus.cancelled,
      );
    });

    test('rejects unknown database status values', () {
      expect(
        () => trackingSessionStatusFromValue('archived'),
        throwsArgumentError,
      );
    });
  });

  group('TrackingSession', () {
    test('isActive is only true for in-progress sessions', () {
      expect(
        _session(status: TrackingSessionStatus.inProgress).isActive,
        isTrue,
      );
      expect(
        _session(status: TrackingSessionStatus.completed).isActive,
        isFalse,
      );
      expect(
        _session(status: TrackingSessionStatus.cancelled).isActive,
        isFalse,
      );
    });

    test('copyWith keeps untouched fields and updates the given ones', () {
      final original = _session(
        currentStationName: 'Pasar Seni',
        stopsCompleted: 0,
      );

      final updated = original.copyWith(
        currentStationName: 'Asia Jaya',
        stopsCompleted: 6,
      );

      expect(updated.currentStationName, 'Asia Jaya');
      expect(updated.stopsCompleted, 6);
      expect(updated.id, original.id);
      expect(updated.routeId, original.routeId);
      expect(updated.totalStops, original.totalStops);
      expect(updated.status, original.status);
      expect(updated.startedAt, original.startedAt);
      expect(updated.destinationStopName, 'Kelana Jaya');
    });

    test('copyWith can transition status without clearing fields', () {
      final completed =
          _session(
            currentStationName: 'Kelana Jaya',
            stopsCompleted: 17,
          ).copyWith(
            status: TrackingSessionStatus.completed,
            endedAt: DateTime(2026, 9, 15, 8, 24),
            durationMinutes: 24,
            notes: 'Smooth ride',
          );

      expect(completed.status, TrackingSessionStatus.completed);
      expect(completed.endedAt, DateTime(2026, 9, 15, 8, 24));
      expect(completed.durationMinutes, 24);
      expect(completed.notes, 'Smooth ride');
      expect(completed.currentStationName, 'Kelana Jaya');
    });

    test('defaults are safe for progress-free sessions', () {
      final minimal = TrackingSession(
        id: 'session-2',
        userId: 'user-1',
        routeId: 'rapid-bus-kl:300',
        routeName: 'Bus 300',
        mode: 'bus',
        originStopId: 'rapid-bus-kl:100',
        originStopName: 'Kotaraya',
        status: TrackingSessionStatus.inProgress,
        startedAt: DateTime(2026, 9, 15, 12),
      );

      expect(minimal.destinationStopId, isNull);
      expect(minimal.currentStationName, isNull);
      expect(minimal.stopsCompleted, 0);
      expect(minimal.totalStops, 0);
      expect(minimal.endedAt, isNull);
      expect(minimal.durationMinutes, isNull);
      expect(minimal.notes, isNull);
      expect(minimal.isActive, isTrue);
    });
  });
}

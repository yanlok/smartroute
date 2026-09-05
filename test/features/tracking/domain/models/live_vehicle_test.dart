import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';
import 'package:smartroute/features/tracking/domain/models/transit_direction.dart';

void main() {
  LiveVehicle makeVehicle({
    String vehicleId = 'KJL-2847',
    String lineId = 'kj',
    TransitDirection direction = TransitDirection.forward,
    double positionFraction = 0.28,
    int etaMinutes = 13,
    bool isLive = false,
  }) {
    return LiveVehicle(
      vehicleId: vehicleId,
      lineId: lineId,
      direction: direction,
      positionFraction: positionFraction,
      etaMinutes: etaMinutes,
      lastUpdated: DateTime.utc(2026, 1, 1, 12, 0, 0),
      isLive: isLive,
    );
  }

  group('LiveVehicle', () {
    group('const constructor', () {
      test('accepts fraction exactly at 0.0 and 1.0', () {
        expect(() => makeVehicle(positionFraction: 0.0), returnsNormally);
        expect(() => makeVehicle(positionFraction: 1.0), returnsNormally);
      });

      test('throws an AssertionError when fraction is below 0.0', () {
        expect(
          () => makeVehicle(positionFraction: -0.01),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws an AssertionError when fraction is above 1.0', () {
        expect(
          () => makeVehicle(positionFraction: 1.01),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('LiveVehicle.clamped', () {
      test('clamps a value below 0.0 to 0.0', () {
        final v = LiveVehicle.clamped(
          vehicleId: 'X',
          lineId: 'kj',
          direction: TransitDirection.forward,
          rawPositionFraction: -0.5,
          etaMinutes: 5,
          lastUpdated: DateTime.utc(2026),
          isLive: false,
        );
        expect(v.positionFraction, 0.0);
      });

      test('clamps a value above 1.0 to 1.0', () {
        final v = LiveVehicle.clamped(
          vehicleId: 'X',
          lineId: 'kj',
          direction: TransitDirection.forward,
          rawPositionFraction: 1.7,
          etaMinutes: 5,
          lastUpdated: DateTime.utc(2026),
          isLive: false,
        );
        expect(v.positionFraction, 1.0);
      });

      test('leaves a value inside the range untouched', () {
        final v = LiveVehicle.clamped(
          vehicleId: 'X',
          lineId: 'kj',
          direction: TransitDirection.forward,
          rawPositionFraction: 0.42,
          etaMinutes: 5,
          lastUpdated: DateTime.utc(2026),
          isLive: false,
        );
        expect(v.positionFraction, 0.42);
      });

      test('clamps a negative etaMinutes to 0', () {
        final v = LiveVehicle.clamped(
          vehicleId: 'X',
          lineId: 'kj',
          direction: TransitDirection.forward,
          rawPositionFraction: 0.5,
          etaMinutes: -3,
          lastUpdated: DateTime.utc(2026),
          isLive: false,
        );
        expect(v.etaMinutes, 0);
      });
    });

    test('copyWith updates only the specified fields', () {
      final original = makeVehicle();
      final updated = original.copyWith(
        positionFraction: 0.6,
        etaMinutes: 7,
        isLive: true,
      );
      expect(updated.vehicleId, original.vehicleId);
      expect(updated.lineId, original.lineId);
      expect(updated.direction, original.direction);
      expect(updated.positionFraction, 0.6);
      expect(updated.etaMinutes, 7);
      expect(updated.isLive, isTrue);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('equality is value-based across all fields', () {
      expect(makeVehicle(), equals(makeVehicle()));
      expect(makeVehicle(vehicleId: 'OTHER'), isNot(equals(makeVehicle())));
      expect(
        makeVehicle(direction: TransitDirection.reverse),
        isNot(equals(makeVehicle(direction: TransitDirection.forward))),
      );
      expect(
        makeVehicle(isLive: true),
        isNot(equals(makeVehicle(isLive: false))),
      );
    });

    test('hashCode is consistent with equality', () {
      expect(makeVehicle().hashCode, makeVehicle().hashCode);
    });

    test('toString includes vehicleId, lineId, and isLive', () {
      final s = makeVehicle().toString();
      expect(s, contains('KJL-2847'));
      expect(s, contains('kj'));
      expect(s, contains('isLive: false'));
    });
  });
}

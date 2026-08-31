import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/arrival_estimate.dart';

void main() {
  ArrivalEstimate makeEstimate({
    String stationId = 'kj-kl-sentral',
    String platformCode = 'Platform 2',
    String lineId = 'kj',
    String vehicleId = 'KJL-2847',
    int etaMinutes = 5,
    bool isLive = false,
  }) {
    return ArrivalEstimate(
      stationId: stationId,
      platformCode: platformCode,
      lineId: lineId,
      vehicleId: vehicleId,
      etaMinutes: etaMinutes,
      isLive: isLive,
    );
  }

  group('ArrivalEstimate', () {
    test('accepts etaMinutes of 0', () {
      expect(() => makeEstimate(etaMinutes: 0), returnsNormally);
    });

    test('throws an AssertionError when etaMinutes is negative', () {
      expect(
        () => makeEstimate(etaMinutes: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith updates only the specified fields', () {
      final original = makeEstimate();
      final updated = original.copyWith(etaMinutes: 9, isLive: true);
      expect(updated.stationId, original.stationId);
      expect(updated.platformCode, original.platformCode);
      expect(updated.lineId, original.lineId);
      expect(updated.vehicleId, original.vehicleId);
      expect(updated.etaMinutes, 9);
      expect(updated.isLive, isTrue);
    });

    test('equality is value-based across all fields', () {
      expect(makeEstimate(), equals(makeEstimate()));
      expect(
        makeEstimate(platformCode: 'Platform 1'),
        isNot(equals(makeEstimate(platformCode: 'Platform 2'))),
      );
      expect(
        makeEstimate(etaMinutes: 5),
        isNot(equals(makeEstimate(etaMinutes: 6))),
      );
      expect(
        makeEstimate(isLive: true),
        isNot(equals(makeEstimate(isLive: false))),
      );
    });

    test('hashCode is consistent with equality', () {
      expect(makeEstimate().hashCode, makeEstimate().hashCode);
    });

    test(
      'toString includes stationId, platformCode, vehicleId, and isLive',
      () {
        final s = makeEstimate().toString();
        expect(s, contains('kj-kl-sentral'));
        expect(s, contains('Platform 2'));
        expect(s, contains('KJL-2847'));
        expect(s, contains('isLive: false'));
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/line_operational_status.dart';
import 'package:smartroute/features/tracking/domain/models/line_status.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 1, 1, 12);

  group('LineOperationalStatus labels', () {
    test('onTime label is "On Time"', () {
      expect(LineOperationalStatus.onTime.label, 'On Time');
    });
    test('minorDelay label is "Minor Delay"', () {
      expect(LineOperationalStatus.minorDelay.label, 'Minor Delay');
    });
    test('majorDelay label is "Major Delay"', () {
      expect(LineOperationalStatus.majorDelay.label, 'Major Delay');
    });
    test('suspended label is "Suspended"', () {
      expect(LineOperationalStatus.suspended.label, 'Suspended');
    });
  });

  group('LineStatus', () {
    test('throws an AssertionError when delayMinutes is negative', () {
      expect(
        () => LineStatus(
          lineId: 'kj',
          status: LineOperationalStatus.minorDelay,
          delayMinutes: -1,
          lastUpdated: fixedTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    group('convenience constructors', () {
      test('onTime factory produces onTime with 0 delay', () {
        final s = LineStatus.onTime(lineId: 'kj', at: fixedTime);
        expect(s.lineId, 'kj');
        expect(s.status, LineOperationalStatus.onTime);
        expect(s.delayMinutes, 0);
        expect(s.lastUpdated, fixedTime);
      });

      test('delayed factory rejects onTime', () {
        expect(
          () => LineStatus.delayed(
            lineId: 'kj',
            status: LineOperationalStatus.onTime,
            delayMinutes: 5,
            at: fixedTime,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('delayed factory accepts minorDelay with positive delay', () {
        final s = LineStatus.delayed(
          lineId: 'kj',
          status: LineOperationalStatus.minorDelay,
          delayMinutes: 4,
          at: fixedTime,
        );
        expect(s.status, LineOperationalStatus.minorDelay);
        expect(s.delayMinutes, 4);
      });

      test('delayed factory accepts majorDelay with positive delay', () {
        final s = LineStatus.delayed(
          lineId: 'kj',
          status: LineOperationalStatus.majorDelay,
          delayMinutes: 15,
          at: fixedTime,
        );
        expect(s.status, LineOperationalStatus.majorDelay);
        expect(s.delayMinutes, 15);
      });

      test('suspended factory produces suspended with 0 delay', () {
        final s = LineStatus.suspended(lineId: 'kj', at: fixedTime);
        expect(s.status, LineOperationalStatus.suspended);
        expect(s.delayMinutes, 0);
      });
    });

    test('copyWith updates only the specified fields', () {
      final original = LineStatus.onTime(lineId: 'kj', at: fixedTime);
      final updated = original.copyWith(
        status: LineOperationalStatus.majorDelay,
        delayMinutes: 12,
      );
      expect(updated.lineId, original.lineId);
      expect(updated.status, LineOperationalStatus.majorDelay);
      expect(updated.delayMinutes, 12);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('equality is value-based across all fields', () {
      final a = LineStatus.onTime(lineId: 'kj', at: fixedTime);
      final b = LineStatus.onTime(lineId: 'kj', at: fixedTime);
      expect(a, equals(b));
      expect(
        LineStatus.onTime(lineId: 'kj', at: fixedTime),
        isNot(equals(LineStatus.onTime(lineId: 'mk', at: fixedTime))),
      );
    });

    test('hashCode is consistent with equality', () {
      final a = LineStatus.onTime(lineId: 'kj', at: fixedTime);
      expect(a.hashCode, a.hashCode);
    });
  });
}

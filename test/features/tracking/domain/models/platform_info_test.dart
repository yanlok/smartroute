import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/platform_info.dart';

void main() {
  PlatformInfo makePlatform({
    String stationId = 'kj-kl-sentral',
    String platformCode = 'Platform 2',
    String lineId = 'kj',
    bool isAccessible = true,
    String? notes = 'Use lift from concourse',
  }) {
    return PlatformInfo(
      stationId: stationId,
      platformCode: platformCode,
      lineId: lineId,
      isAccessible: isAccessible,
      notes: notes,
    );
  }

  group('PlatformInfo', () {
    test('notes is null by default', () {
      final p = PlatformInfo(
        stationId: 'a',
        platformCode: 'Platform 1',
        lineId: 'kj',
        isAccessible: false,
      );
      expect(p.notes, isNull);
    });

    test('copyWith updates only the specified fields', () {
      final original = makePlatform();
      final updated = original.copyWith(
        isAccessible: false,
        notes: 'Under maintenance',
      );
      expect(updated.stationId, original.stationId);
      expect(updated.platformCode, original.platformCode);
      expect(updated.lineId, original.lineId);
      expect(updated.isAccessible, isFalse);
      expect(updated.notes, 'Under maintenance');
    });

    test('copyWith can clear notes by passing null explicitly', () {
      final original = makePlatform();
      final updated = original.copyWith(notes: null);
      expect(updated.notes, isNull);
    });

    test('equality is value-based across all fields', () {
      expect(makePlatform(), equals(makePlatform()));
      expect(
        makePlatform(platformCode: 'Platform 1'),
        isNot(equals(makePlatform(platformCode: 'Platform 2'))),
      );
      expect(
        makePlatform(isAccessible: false),
        isNot(equals(makePlatform(isAccessible: true))),
      );
      expect(makePlatform(notes: 'A'), isNot(equals(makePlatform(notes: 'B'))));
    });

    test('hashCode is consistent with equality', () {
      expect(makePlatform().hashCode, makePlatform().hashCode);
    });

    test('toString includes stationId, platformCode, and lineId', () {
      final s = makePlatform().toString();
      expect(s, contains('kj-kl-sentral'));
      expect(s, contains('Platform 2'));
      expect(s, contains('kj'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart';

void main() {
  TransitLine makeLine({
    String id = 'kj',
    String code = 'KJ',
    String name = 'Kelana Jaya Line',
    TransitMode mode = TransitMode.lrt,
    String colorToken = 'kjLine',
    List<String>? stationIds,
  }) {
    return TransitLine(
      id: id,
      code: code,
      name: name,
      mode: mode,
      colorToken: colorToken,
      orderedStationIds:
          stationIds ?? const ['kj-a', 'kj-b', 'kj-c', 'kj-d', 'kj-e'],
    );
  }

  group('TransitLine', () {
    test('stores all required fields', () {
      final line = makeLine();
      expect(line.id, 'kj');
      expect(line.code, 'KJ');
      expect(line.name, 'Kelana Jaya Line');
      expect(line.mode, TransitMode.lrt);
      expect(line.colorToken, 'kjLine');
      expect(line.orderedStationIds, hasLength(5));
    });

    test('stationCount returns the ordered station list length', () {
      expect(makeLine().stationCount, 5);
      expect(makeLine(stationIds: const ['a']).stationCount, 1);
    });

    test('copyWith updates only the specified fields', () {
      final original = makeLine();
      final updated = original.copyWith(
        name: 'KJ Renamed',
        colorToken: 'mkLine',
      );
      expect(updated.id, original.id);
      expect(updated.code, original.code);
      expect(updated.name, 'KJ Renamed');
      expect(updated.colorToken, 'mkLine');
      expect(updated.mode, original.mode);
      expect(updated.orderedStationIds, original.orderedStationIds);
    });

    test('equality is value-based across all fields', () {
      expect(makeLine(), equals(makeLine()));
      expect(makeLine(id: 'mk'), isNot(equals(makeLine(id: 'kj'))));
      expect(
        makeLine(mode: TransitMode.mrt),
        isNot(equals(makeLine(mode: TransitMode.lrt))),
      );
      expect(
        makeLine(stationIds: const ['x', 'y']),
        isNot(equals(makeLine(stationIds: const ['x', 'z']))),
      );
    });

    test('hashCode is consistent with equality', () {
      expect(makeLine().hashCode, makeLine().hashCode);
    });

    test('toString includes the id, code, name, mode, and station count', () {
      final s = makeLine().toString();
      expect(s, contains('kj'));
      expect(s, contains('KJ'));
      expect(s, contains('Kelana Jaya Line'));
      expect(s, contains('lrt'));
      expect(s, contains('5'));
    });
  });
}

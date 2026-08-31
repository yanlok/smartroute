import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/data/datasources/transit_line_static_data.dart';

void main() {
  group('kTransitLines', () {
    test('is non-empty', () {
      expect(kTransitLines, isNotEmpty);
    });

    test('every line has a unique id', () {
      final ids = kTransitLines.map((l) => l.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'Duplicate line ids: $ids',
      );
    });

    test('every line has at least 2 stations (origin + terminal)', () {
      for (final line in kTransitLines) {
        expect(
          line.orderedStationIds.length,
          greaterThanOrEqualTo(2),
          reason: 'Line ${line.id} has too few stations',
        );
      }
    });

    test('every line has a colorToken matching one of the design tokens', () {
      const known = <String>{
        'kjLine',
        'spLine',
        'mkLine',
        'mpLine',
        'mlLine',
        'brLine',
        'busLine',
        'secondary',
        'primary',
      };
      for (final line in kTransitLines) {
        expect(
          known.contains(line.colorToken),
          isTrue,
          reason:
              'Line ${line.id} uses unknown colorToken '
              '${line.colorToken}',
        );
      }
    });
  });

  group('kAllStations', () {
    test('is non-empty', () {
      expect(kAllStations, isNotEmpty);
    });

    test('contains a row for every station in every line', () {
      for (final line in kTransitLines) {
        for (var i = 0; i < line.orderedStationIds.length; i++) {
          final stationId = line.orderedStationIds[i];
          final matches = kAllStations.where(
            (s) => s.id == stationId && s.lineId == line.id,
          );
          expect(
            matches,
            isNotEmpty,
            reason:
                'Line ${line.id} index $i references missing '
                'station $stationId',
          );
        }
      }
    });

    test('every station lineId matches a known line id', () {
      final knownLineIds = kTransitLines.map((l) => l.id).toSet();
      for (final station in kAllStations) {
        expect(
          knownLineIds.contains(station.lineId),
          isTrue,
          reason:
              'Station ${station.id} has unknown lineId '
              '${station.lineId}',
        );
      }
    });

    test('every station sequence matches its index in orderedStationIds', () {
      for (final line in kTransitLines) {
        for (var i = 0; i < line.orderedStationIds.length; i++) {
          final stationId = line.orderedStationIds[i];
          final station = kAllStations.firstWhere(
            (s) => s.id == stationId && s.lineId == line.id,
            orElse: () => throw StateError('Missing station $stationId'),
          );
          expect(
            station.sequence,
            i,
            reason:
                'Station ${station.id} on line ${line.id} has '
                'sequence ${station.sequence} but appears at index $i',
          );
        }
      }
    });

    test('every station has a non-empty name', () {
      for (final station in kAllStations) {
        expect(
          station.name,
          isNotEmpty,
          reason:
              'Station ${station.id} on line ${station.lineId} '
              'has empty name',
        );
      }
    });

    test('lat/long are present and non-zero for at least 90% of stations', () {
      var withCoords = 0;
      for (final station in kAllStations) {
        if (station.latitude != 0.0 || station.longitude != 0.0) {
          withCoords++;
        }
      }
      final ratio = withCoords / kAllStations.length;
      expect(
        ratio,
        greaterThanOrEqualTo(0.9),
        reason:
            'Only ${(ratio * 100).toStringAsFixed(1)}% of stations '
            'have coordinates',
      );
    });
  });

  group('kLineShapes', () {
    test('is non-empty', () {
      expect(kLineShapes, isNotEmpty);
    });

    test('has a shape for every line that has stops', () {
      for (final line in kTransitLines) {
        expect(
          kLineShapes.containsKey(line.id),
          isTrue,
          reason: 'Missing shape for line ${line.id}',
        );
        expect(
          kLineShapes[line.id]!.length,
          greaterThan(10),
          reason: 'Line ${line.id} has suspiciously few shape points',
        );
      }
    });
  });

  group('kLineIdAlias', () {
    test('has an alias for every line', () {
      for (final line in kTransitLines) {
        expect(
          kLineIdAlias.containsKey(line.id),
          isTrue,
          reason: 'Missing alias for line ${line.id}',
        );
      }
    });
  });
}

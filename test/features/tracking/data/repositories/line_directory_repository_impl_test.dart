import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/data/datasources/mock_line_directory_data_source.dart';
import 'package:smartroute/features/tracking/data/repositories/line_directory_repository_impl.dart';
import 'package:smartroute/features/tracking/domain/exceptions/tracking_repository_exception.dart';

void main() {
  group('LineDirectoryRepositoryImpl', () {
    final repo = LineDirectoryRepositoryImpl();

    test('getLines returns a non-empty list of real lines', () async {
      final lines = await repo.getLines();
      expect(lines, isNotEmpty);
      // We expect at least KJ and MRT lines.
      final ids = lines.map((l) => l.id).toSet();
      expect(ids.contains('kj'), isTrue);
      expect(ids.contains('kgl'), isTrue);
    });

    test('getStationsForLine returns ordered stations for kj', () async {
      final stations = await repo.getStationsForLine('kj');
      expect(stations, isNotEmpty);
      expect(stations.first.lineId, 'kj');
      for (var i = 0; i < stations.length - 1; i++) {
        expect(
          stations[i].sequence,
          lessThan(stations[i + 1].sequence),
          reason: 'Stations must be in ascending sequence order',
        );
      }
    });

    test('getStationsForLine returns empty for an unknown line', () async {
      final stations = await repo.getStationsForLine('no-such-line');
      expect(stations, isEmpty);
    });

    test('getLineById returns the line for a known id', () async {
      final line = await repo.getLineById('kj');
      expect(line, isNotNull);
      expect(line!.id, 'kj');
      expect(line.name, contains('Kelana Jaya'));
    });

    test('getLineById returns null for an unknown id', () async {
      final line = await repo.getLineById('zzz');
      expect(line, isNull);
    });

    test('getStationById finds a known station', () async {
      final station = await repo.getStationById(
        lineId: 'kj',
        stationId: 'kj10',
      );
      expect(station, isNotNull);
      expect(station!.id, 'kj10');
      expect(station.lineId, 'kj');
    });

    test('getStationById returns null for an unknown station', () async {
      final station = await repo.getStationById(
        lineId: 'kj',
        stationId: 'nope',
      );
      expect(station, isNull);
    });

    test('getAllStations returns rows for every line', () async {
      final all = await repo.getAllStations();
      expect(all, isNotEmpty);
      final lineIds = all.map((s) => s.lineId).toSet();
      expect(
        lineIds.length,
        greaterThan(1),
        reason: 'Should cover multiple lines',
      );
    });
  });

  group('LineDirectoryRepositoryImpl error wrapping', () {
    test('getLines wraps unexpected errors from the data source', () async {
      // Inject a data source whose getLinesSync throws — the
      // repository's _safe wrapper should catch it and rethrow
      // as TrackingRepositoryException.
      final repo = LineDirectoryRepositoryImpl(
        dataSource: _ThrowingDataSource(),
      );
      await expectLater(
        repo.getLines(),
        throwsA(isA<TrackingRepositoryException>()),
      );
    });
  });
}

class _ThrowingDataSource extends MockLineDirectoryDataSource {
  @override
  List<Never> getLinesSync() {
    throw StateError('synthetic failure');
  }
}

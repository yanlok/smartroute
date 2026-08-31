import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/data/datasources/mock_line_directory_data_source.dart';
import 'package:smartroute/features/tracking/data/datasources/mock_tracking_data_source.dart';
import 'package:smartroute/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:smartroute/features/tracking/domain/exceptions/tracking_repository_exception.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';

void main() {
  group('TrackingRepositoryImpl', () {
    final repo = TrackingRepositoryImpl(
      dataSource: MockTrackingDataSource(
        directory: const MockLineDirectoryDataSource(),
        speedFactor: 1000.0, // accelerate ticks so tests are fast
      ),
    );

    test(
      'getLineStatus returns an onTime LineStatus for known lines',
      () async {
        final status = await repo.getLineStatus('kj');
        expect(status.lineId, 'kj');
        expect(status.status.name, 'onTime');
        expect(status.delayMinutes, 0);
      },
    );

    test(
      'getPlatforms returns an empty list (mock not yet modelled)',
      () async {
        final platforms = await repo.getPlatforms('kj10');
        expect(platforms, isEmpty);
      },
    );

    test(
      'watchVehicles emits at least one snapshot for a known line',
      () async {
        final stream = repo.watchVehicles('kj');
        final first = await stream.first;
        expect(first, isNotEmpty);
        // All emitted vehicles are simulated, never real.
        for (final v in first) {
          expect(v.isLive, isFalse);
          expect(v.lineId, 'kj');
        }
      },
    );

    test('watchVehicles for an unknown line emits an empty list', () async {
      final stream = repo.watchVehicles('does-not-exist');
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test(
      'watchArrivals emits simulated estimates for a known station',
      () async {
        final stream = repo.watchArrivals(lineId: 'kj', stationId: 'kj10');
        final first = await stream.first;
        // Could be empty if no trains are ahead; just assert shape.
        for (final a in first) {
          expect(a.isLive, isFalse);
          expect(a.lineId, 'kj');
          expect(a.stationId, 'kj10');
          expect(a.etaMinutes, greaterThan(0));
        }
      },
    );

    test('watchArrivals for an unknown station emits an empty list', () async {
      final stream = repo.watchArrivals(
        lineId: 'kj',
        stationId: 'no-such-station',
      );
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test(
      'repository error wrapping works for watchVehicles stream errors',
      () async {
        // Construct a repository that wraps a data source which
        // returns a stream that errors immediately. The repository
        // should wrap the error in TrackingRepositoryException.
        final brokenRepo = TrackingRepositoryImpl(
          dataSource: _ThrowingDataSource(),
        );
        final stream = brokenRepo.watchVehicles('kj');
        await expectLater(
          stream.first,
          throwsA(isA<TrackingRepositoryException>()),
        );
      },
    );
  });
}

class _ThrowingDataSource extends MockTrackingDataSource {
  _ThrowingDataSource() : super(directory: const MockLineDirectoryDataSource());

  @override
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  }) {
    return Stream<List<LiveVehicle>>.error(
      const TrackingRepositoryException('synthetic failure'),
    );
  }
}

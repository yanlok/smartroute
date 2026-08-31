import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/data/datasources/mock_line_directory_data_source.dart';
import 'package:smartroute/features/tracking/data/datasources/mock_tracking_data_source.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';
import 'package:smartroute/features/tracking/domain/models/transit_direction.dart';

void main() {
  group('MockTrackingDataSource.watchVehicles', () {
    test('emits multiple vehicles for kj and all are simulated', () async {
      final source = MockTrackingDataSource(
        directory: const MockLineDirectoryDataSource(),
        speedFactor: 1000.0,
      );

      final stream = source.watchVehicles('kj');
      final first = await stream.first;
      expect(first.length, greaterThanOrEqualTo(2));
      for (final v in first) {
        expect(v.isLive, isFalse);
        expect(v.lineId, 'kj');
      }
    });

    test('cancelling the subscription stops further emissions', () async {
      final source = MockTrackingDataSource(
        directory: const MockLineDirectoryDataSource(),
        speedFactor: 1000.0,
      );

      final emitted = <List<LiveVehicle>>[];
      final sub = source.watchVehicles('kj').listen(emitted.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      final countAfterCancel = emitted.length;

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        emitted.length,
        countAfterCancel,
        reason: 'No emissions after cancel',
      );
    });

    test('positions are clamped to [0.0, 1.0] across many ticks', () async {
      final source = MockTrackingDataSource(
        directory: const MockLineDirectoryDataSource(),
        speedFactor: 10000.0,
      );

      final sub = source.watchVehicles('kj').listen((snapshot) {
        for (final v in snapshot) {
          expect(v.positionFraction, greaterThanOrEqualTo(0.0));
          expect(v.positionFraction, lessThanOrEqualTo(1.0));
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await sub.cancel();
    });

    test('forward-direction vehicles eventually flip to reverse', () async {
      final source = MockTrackingDataSource(
        directory: const MockLineDirectoryDataSource(),
        speedFactor: 10000.0,
      );

      var sawReverse = false;
      final sub = source.watchVehicles('kj').listen((snapshot) {
        for (final v in snapshot) {
          if (v.direction == TransitDirection.reverse) {
            sawReverse = true;
          }
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await sub.cancel();
      expect(
        sawReverse,
        isTrue,
        reason: 'High speedFactor should produce a direction flip',
      );
    });
  });

  group('MockTrackingDataSource.watchArrivals', () {
    test(
      'emits a (possibly empty) list with isLive=false for a known station',
      () async {
        final source = MockTrackingDataSource(
          directory: const MockLineDirectoryDataSource(),
          speedFactor: 1000.0,
        );
        final stream = source.watchArrivals(lineId: 'kj', stationId: 'kj10');
        final first = await stream.first;
        for (final a in first) {
          expect(a.isLive, isFalse);
          expect(a.lineId, 'kj');
          expect(a.stationId, 'kj10');
        }
      },
    );

    test('emits an empty list for an unknown station', () async {
      final source = MockTrackingDataSource(
        directory: const MockLineDirectoryDataSource(),
      );
      final stream = source.watchArrivals(lineId: 'kj', stationId: 'nope');
      final first = await stream.first;
      expect(first, isEmpty);
    });
  });
}

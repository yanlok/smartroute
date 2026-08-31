import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/arrivals_controller.dart';
import 'package:smartroute/features/tracking/domain/exceptions/tracking_repository_exception.dart';
import 'package:smartroute/features/tracking/domain/models/arrival_estimate.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';

class FakeTrackingRepository implements TrackingRepository {
  StreamController<List<ArrivalEstimate>>? controller;
  int watchArrivalsCallCount = 0;
  String? lastLineId;
  String? lastStationId;

  @override
  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  }) {
    watchArrivalsCallCount++;
    lastLineId = lineId;
    lastStationId = stationId;
    controller ??= StreamController<List<ArrivalEstimate>>.broadcast();
    return controller!.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTrackingRepository repo;
  late ArrivalsController controller;

  setUp(() {
    repo = FakeTrackingRepository();
    controller = ArrivalsController(
      trackingRepository: repo,
      lineId: 'kj',
      stationId: 'kj10',
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('ArrivalsController', () {
    test('initial state is empty and not loading', () {
      expect(controller.arrivals, isEmpty);
      expect(controller.station, isNull);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.isMockData, isTrue);
      expect(controller.lineId, 'kj');
      expect(controller.stationId, 'kj10');
    });

    test('start subscribes and exposes arrivals', () async {
      controller.start();
      await Future<void>.delayed(Duration.zero);

      repo.controller!.add([
        const ArrivalEstimate(
          stationId: 'kj10',
          platformCode: 'Platform 1',
          lineId: 'kj',
          vehicleId: 'KJ-1000',
          etaMinutes: 3,
          isLive: false,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.arrivals, hasLength(1));
      expect(controller.arrivals.first.etaMinutes, 3);
      expect(controller.isLoading, isFalse);
      expect(repo.lastLineId, 'kj');
      expect(repo.lastStationId, 'kj10');
    });

    test('stream error sets errorMessage', () async {
      controller.start();
      await Future<void>.delayed(Duration.zero);

      repo.controller!.addError(
        const TrackingRepositoryException('arrivals boom'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.errorMessage, 'arrivals boom');
      expect(controller.isLoading, isFalse);
    });

    test(
      'start called twice resubscribes (only the latest is honoured)',
      () async {
        // First start. The fake stream never emits on its own so
        // isLoading stays true; we just verify it does not throw
        // and that the watchArrivals call was made.
        controller.start();
        expect(controller.isLoading, isTrue);
        expect(repo.watchArrivalsCallCount, 1);

        // Calling start again should increment the call count
        // and leave the controller in loading state.
        controller.start();
        expect(repo.watchArrivalsCallCount, 2);
        expect(controller.isLoading, isTrue);
      },
    );

    test('retry is an alias for start', () {
      controller.retry();
      // does not throw and exposes initial loading
      expect(controller.isLoading, isTrue);
    });
  });
}

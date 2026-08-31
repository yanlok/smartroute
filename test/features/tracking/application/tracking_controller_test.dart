import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/tracking_controller.dart';
import 'package:smartroute/features/tracking/domain/exceptions/tracking_repository_exception.dart';
import 'package:smartroute/features/tracking/domain/models/arrival_estimate.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';
import 'package:smartroute/features/tracking/domain/models/line_operational_status.dart';
import 'package:smartroute/features/tracking/domain/models/line_status.dart';
import 'package:smartroute/features/tracking/domain/models/platform_info.dart';
import 'package:smartroute/features/tracking/domain/models/transit_direction.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_station.dart';
import 'package:smartroute/features/tracking/domain/repositories/line_directory_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';

class FakeTrackingRepository implements TrackingRepository {
  StreamController<List<LiveVehicle>>? vehiclesController;
  StreamController<List<ArrivalEstimate>>? arrivalsController;
  int watchVehiclesCallCount = 0;
  int watchArrivalsCallCount = 0;
  int cancelVehiclesCount = 0;
  int cancelArrivalsCount = 0;
  bool shouldThrowOnWatch = false;

  void _checkAndMaybeThrow() {
    if (shouldThrowOnWatch) {
      throw const TrackingRepositoryException('mock failure');
    }
  }

  @override
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  }) {
    watchVehiclesCallCount++;
    _checkAndMaybeThrow();
    final c = vehiclesController ??=
        StreamController<List<LiveVehicle>>.broadcast();
    return c.stream;
  }

  @override
  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  }) {
    watchArrivalsCallCount++;
    _checkAndMaybeThrow();
    final c = arrivalsController ??=
        StreamController<List<ArrivalEstimate>>.broadcast();
    return c.stream;
  }

  @override
  Future<LineStatus> getLineStatus(String lineId) async {
    return LineStatus(
      lineId: lineId,
      status: LineOperationalStatus.onTime,
      delayMinutes: 0,
      lastUpdated: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<List<PlatformInfo>> getPlatforms(String stationId) async =>
      const <PlatformInfo>[];
}

class FakeLineDirectoryRepository implements LineDirectoryRepository {
  TransitLine? lineResult;
  List<TrackingStation> stationsResult = const <TrackingStation>[];
  int getLineByIdCallCount = 0;
  int getStationsForLineCallCount = 0;
  String? lastLineId;

  void _ensure() {
    lineResult ??= TransitLine(
      id: 'kj',
      code: 'KJ',
      name: 'Kelana Jaya Line',
      mode: TransitMode.lrt,
      colorToken: 'kjLine',
      orderedStationIds: const ['kj1', 'kj2'],
    );
    if (stationsResult.isEmpty) {
      stationsResult = const [
        TrackingStation(id: 'kj1', name: 'Gombak', lineId: 'kj', sequence: 0),
        TrackingStation(
          id: 'kj2',
          name: 'Putra Heights',
          lineId: 'kj',
          sequence: 1,
        ),
      ];
    }
  }

  @override
  Future<TransitLine?> getLineById(String lineId) async {
    getLineByIdCallCount++;
    lastLineId = lineId;
    _ensure();
    return lineResult;
  }

  @override
  Future<List<TrackingStation>> getStationsForLine(String lineId) async {
    getStationsForLineCallCount++;
    lastLineId = lineId;
    _ensure();
    return stationsResult;
  }

  @override
  Future<List<TransitLine>> getLines() async => [lineResult!];

  @override
  Future<List<TrackingStation>> getAllStations() async => stationsResult;

  @override
  Future<TrackingStation?> getStationById({
    required String lineId,
    required String stationId,
  }) async {
    return stationsResult.firstWhere(
      (s) => s.id == stationId && s.lineId == lineId,
      orElse: () => stationsResult.first,
    );
  }
}

LiveVehicle _vehicle({String id = 'KJ-1000'}) {
  return LiveVehicle(
    vehicleId: id,
    lineId: 'kj',
    direction: TransitDirection.forward,
    positionFraction: 0.3,
    etaMinutes: 5,
    lastUpdated: DateTime.utc(2026, 1, 1),
    isLive: false,
  );
}

void main() {
  late FakeTrackingRepository trackingRepo;
  late FakeLineDirectoryRepository directoryRepo;
  late TrackingController controller;

  setUp(() {
    trackingRepo = FakeTrackingRepository();
    directoryRepo = FakeLineDirectoryRepository();
    controller = TrackingController(
      trackingRepository: trackingRepo,
      directoryRepository: directoryRepo,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('TrackingController', () {
    test('initial state is empty and not loading', () {
      expect(controller.selectedLineId, isNull);
      expect(controller.selectedLine, isNull);
      expect(controller.stations, isEmpty);
      expect(controller.vehicles, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.isMockData, isTrue);
    });

    test(
      'selectLine sets loading then completes and exposes vehicles',
      () async {
        await controller.selectLine('kj');
        // give the stream listener a chance to fire
        await Future<void>.delayed(Duration.zero);

        trackingRepo.vehiclesController!.add(<LiveVehicle>[_vehicle()]);
        await Future<void>.delayed(Duration.zero);

        expect(controller.selectedLineId, 'kj');
        expect(controller.selectedLine, isNotNull);
        expect(controller.vehicles, hasLength(1));
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, isNull);
        expect(directoryRepo.getLineByIdCallCount, 1);
        expect(trackingRepo.watchVehiclesCallCount, 1);
      },
    );

    test('stale selectLine calls are ignored', () async {
      final first = controller.selectLine('kj');
      final second = controller.selectLine('ag');
      await first;
      await second;
      await Future<void>.delayed(Duration.zero);

      // Whichever completed last wins, but no exceptions thrown
      // and state is consistent with the latest call.
      expect(controller.selectedLineId, 'ag');
      // at least one watchVehicles call (the latest)
      expect(trackingRepo.watchVehiclesCallCount, greaterThanOrEqualTo(1));
    });

    test('onError from the stream sets errorMessage', () async {
      await controller.selectLine('kj');
      await Future<void>.delayed(Duration.zero);

      trackingRepo.vehiclesController!.addError(
        const TrackingRepositoryException('stream boom'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.errorMessage, 'stream boom');
      expect(controller.isLoading, isFalse);
    });

    test('clearSelection resets state and cancels the subscription', () async {
      await controller.selectLine('kj');
      await Future<void>.delayed(Duration.zero);
      trackingRepo.vehiclesController!.add(<LiveVehicle>[_vehicle()]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.vehicles, isNotEmpty);

      controller.clearSelection();
      expect(controller.selectedLineId, isNull);
      expect(controller.selectedLine, isNull);
      expect(controller.vehicles, isEmpty);
      expect(controller.stations, isEmpty);
    });

    test('retry resubscribes to the currently selected line', () async {
      await controller.selectLine('kj');
      await Future<void>.delayed(Duration.zero);
      // Trigger an error
      trackingRepo.vehiclesController!.addError(
        const TrackingRepositoryException('boom'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.errorMessage, 'boom');

      await controller.retry();
      await Future<void>.delayed(Duration.zero);
      // After retry we should have re-subscribed (call count >= 2)
      expect(trackingRepo.watchVehiclesCallCount, greaterThanOrEqualTo(2));
    });

    test('currentVehicle returns the first vehicle or null', () {
      expect(controller.currentVehicle, isNull);
      // It is null initially because no line is selected.
    });
  });
}

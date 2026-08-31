import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/tracking_controller.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';
import 'package:smartroute/features/tracking/domain/models/transit_direction.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_station.dart';
import 'package:smartroute/features/tracking/domain/repositories/line_directory_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:smartroute/features/tracking/presentation/screens/tracking_screen.dart';

class FakeTracking implements TrackingRepository {
  StreamController<List<LiveVehicle>>? controller;
  int callCount = 0;

  @override
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  }) {
    callCount++;
    controller ??= StreamController<List<LiveVehicle>>.broadcast();
    return controller!.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDirectory implements LineDirectoryRepository {
  final TransitLine line = const TransitLine(
    id: 'kj',
    code: 'KJ',
    name: 'Kelana Jaya Line',
    mode: TransitMode.lrt,
    colorToken: 'kjLine',
    orderedStationIds: <String>['kj1', 'kj2', 'kj3'],
  );
  final List<TrackingStation> stations = const [
    TrackingStation(id: 'kj1', name: 'A', lineId: 'kj', sequence: 0),
    TrackingStation(id: 'kj2', name: 'B', lineId: 'kj', sequence: 1),
    TrackingStation(id: 'kj3', name: 'C', lineId: 'kj', sequence: 2),
  ];

  @override
  Future<TransitLine?> getLineById(String lineId) async => line;

  @override
  Future<List<TrackingStation>> getStationsForLine(String lineId) async =>
      stations;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LiveVehicle makeVehicle() => LiveVehicle(
  vehicleId: 'KJ-1',
  lineId: 'kj',
  direction: TransitDirection.forward,
  positionFraction: 0.3,
  etaMinutes: 5,
  lastUpdated: DateTime.utc(2026, 1, 1),
  isLive: false,
);

void main() {
  group('TrackingScreen', () {
    testWidgets('renders a Simulated pill in the header (not LIVE)', (
      tester,
    ) async {
      final trk = FakeTracking();
      final dir = FakeDirectory();
      final controller = TrackingController(
        trackingRepository: trk,
        directoryRepository: dir,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackingScreen(
              lineId: 'kj',
              onBack: () {},
              onNavigate: (_) {},
              controller: controller,
            ),
          ),
        ),
      );
      // Use a tall surface so the column doesn't overflow.
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // Let the controller's selectLine() resolve.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('SIM'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
    });

    testWidgets('renders the vehicle card once a vehicle arrives', (
      tester,
    ) async {
      final trk = FakeTracking();
      final dir = FakeDirectory();
      final controller = TrackingController(
        trackingRepository: trk,
        directoryRepository: dir,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackingScreen(
              lineId: 'kj',
              onBack: () {},
              onNavigate: (_) {},
              controller: controller,
            ),
          ),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pump();
      trk.controller!.add(<LiveVehicle>[makeVehicle()]);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Train KJ-1'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
    });
  });
}

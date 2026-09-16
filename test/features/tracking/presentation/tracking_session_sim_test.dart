// Regression: session origin/destination must follow the simulated vehicle
// position at the moment the session is (re)started.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/tracking_controller.dart';
import 'package:smartroute/features/tracking/application/tracking_session_controller.dart';
import 'package:smartroute/features/tracking/domain/models/arrival_estimate.dart';
import 'package:smartroute/features/tracking/domain/models/line_status.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';
import 'package:smartroute/features/tracking/domain/models/platform_info.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_session.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_station.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart'
    as tracking;
import 'package:smartroute/features/tracking/domain/repositories/line_directory_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_session_repository.dart';
import 'package:smartroute/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  testWidgets('session created at open captures sim start and line terminus; '
      'restart captures the current sim position and direction terminus', (
    tester,
  ) async {
    final network = _network();
    final recordingRepo = _RecordingSessionRepository();
    final sessionController = TrackingSessionController(
      repository: recordingRepo,
    );
    await sessionController.load('user-1');
    final controller = TrackingController(
      trackingRepository: _TrackingRepository(const []),
      directoryRepository: _DirectoryRepository(network),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackingScreen(
            lineId: network.routes.first.id,
            controller: controller,
            sessionController: sessionController,
            network: network,
            onBack: () {},
          ),
        ),
      ),
    );
    // First frames: post-frame hook creates the session at sim progress 0.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(recordingRepo.started, isNotEmpty, reason: 'auto-start on open');
    var last = recordingRepo.started.last;
    expect(last.originStopName, 'Stop 1');
    expect(last.destinationStopName, 'Stop 5');

    // Let the simulation run ~30s so vehicle 0 is mid-line, outbound.
    await tester.pump(const Duration(seconds: 30));

    // End the commute and restart from the current sim position.
    await tester.tap(find.text('End Commute').first);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('End Commute'),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.tap(find.text('Start Tracking'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The ended commute must record the station the train was actually at
    // (Stop 4 after 30s), not the planned outbound terminus (Stop 5).
    expect(recordingRepo.completed, isNotEmpty, reason: 'session ended');
    expect(
      recordingRepo.completed.last.destinationStopName,
      'Stop 4',
      reason: 'log must record where the commute actually ended',
    );

    expect(recordingRepo.started.length, greaterThan(1));
    last = recordingRepo.started.last;
    expect(
      last.originStopName,
      anyOf('Stop 3', 'Stop 4'),
      reason: 'origin must follow the sim position after 30s',
    );
    expect(
      last.destinationStopName,
      'Stop 5',
      reason: 'outbound terminus while train heads toward Stop 5',
    );

    // Let the sim pass the midpoint (return trip) and restart again.
    // The session may have auto-completed when the train reached Stop 5.
    await tester.pump(const Duration(seconds: 40));
    if (!tester.any(find.text('Start Tracking'))) {
      await tester.tap(find.text('End Commute').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('End Commute'),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('Start Tracking'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(recordingRepo.started.length, greaterThan(2));
    last = recordingRepo.started.last;
    expect(
      last.destinationStopName,
      'Stop 1',
      reason: 'return-trip train heads toward the origin terminus',
    );

    controller.dispose();
  });
}

class _RecordingSessionRepository implements TrackingSessionRepository {
  final List<TrackingSession> started = [];
  final List<TrackingSession> completed = [];

  @override
  Future<TrackingSession> startSession({
    required String userId,
    required String routeId,
    required String routeName,
    required String mode,
    required String originStopId,
    required String originStopName,
    String? destinationStopId,
    String? destinationStopName,
    required int totalStops,
  }) async {
    final session = TrackingSession(
      id: 'session-${started.length + 1}',
      userId: userId,
      routeId: routeId,
      routeName: routeName,
      mode: mode,
      originStopId: originStopId,
      originStopName: originStopName,
      destinationStopId: destinationStopId,
      destinationStopName: destinationStopName,
      status: TrackingSessionStatus.inProgress,
      totalStops: totalStops,
      startedAt: DateTime.now(),
    );
    started.add(session);
    return session;
  }

  @override
  Future<TrackingSession> updateProgress({
    required String sessionId,
    required String currentStationName,
    required int stopsCompleted,
  }) async => throw UnimplementedError();

  @override
  Future<TrackingSession> completeSession({
    required String sessionId,
    required DateTime endedAt,
    required int durationMinutes,
    String? notes,
    String? destinationStopId,
    String? destinationStopName,
  }) async {
    final session = TrackingSession(
      id: sessionId,
      userId: 'user-1',
      routeId: 'rapid-rail-kl:KJ',
      routeName: 'Kelana Jaya Line',
      mode: 'LRT',
      originStopId: 'rapid-rail-kl:S1',
      originStopName: 'Stop 1',
      destinationStopId: destinationStopId ?? 'rapid-rail-kl:S5',
      destinationStopName: destinationStopName ?? 'Stop 5',
      status: TrackingSessionStatus.completed,
      totalStops: 4,
      durationMinutes: durationMinutes,
      startedAt: DateTime.now(),
      endedAt: endedAt,
      notes: notes,
    );
    completed.add(session);
    return session;
  }

  @override
  Future<void> cancelSession(String sessionId) async {}

  @override
  Future<List<TrackingSession>> getSessionsForUser(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async => [];

  @override
  Future<void> deleteSession(String sessionId) async {}
}

class _TrackingRepository implements TrackingRepository {
  final List<LiveVehicle> vehicles;

  const _TrackingRepository(this.vehicles);

  @override
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  }) => Stream.value(vehicles);

  @override
  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  }) => const Stream.empty();

  @override
  Future<LineStatus> getLineStatus(String lineId) async =>
      LineStatus.onTime(lineId: lineId, at: DateTime.now());

  @override
  Future<List<PlatformInfo>> getPlatforms(String stationId) async => const [];
}

class _DirectoryRepository implements LineDirectoryRepository {
  final TransitNetwork network;

  const _DirectoryRepository(this.network);

  TransitLine get _line => TransitLine(
    id: network.routes.first.id,
    code: network.routes.first.shortName,
    name: network.routes.first.displayName,
    mode: network.routes.first.mode == TransitMode.bus
        ? tracking.TransitMode.bus
        : tracking.TransitMode.lrt,
    colorToken: network.routes.first.colorHex,
    orderedStationIds: network.patterns.first.stopIds,
  );

  @override
  Future<List<TransitLine>> getLines() async => [_line];

  @override
  Future<TransitLine?> getLineById(String lineId) async => _line;

  @override
  Future<List<TrackingStation>> getAllStations() async =>
      getStationsForLine(_line.id);

  @override
  Future<List<TrackingStation>> getStationsForLine(String lineId) async => [
    for (var index = 0; index < network.stops.length; index++)
      TrackingStation(
        id: network.stops[index].id,
        name: network.stops[index].name,
        lineId: lineId,
        sequence: index,
        latitude: network.stops[index].latitude,
        longitude: network.stops[index].longitude,
      ),
  ];

  @override
  Future<TrackingStation?> getStationById({
    required String lineId,
    required String stationId,
  }) async => (await getStationsForLine(lineId)).first;
}

TransitNetwork _network() {
  const routeId = 'rapid-rail-kl:KJ';
  const source = 'rapid-rail-kl';
  final stopIds = <String>[for (var i = 1; i <= 5; i++) '$source:S$i'];
  return TransitNetwork(
    metadata: TransitMetadata(
      generatedAt: DateTime.now(),
      publisher: 'probe',
      licence: '',
      routeCount: 1,
      stopCount: 5,
      edgeCount: 4,
      patternCount: 1,
      shapeRouteCount: 1,
      sources: const [],
    ),
    routes: [
      TransitRoute(
        id: routeId,
        gtfsId: 'KJ',
        source: source,
        shortName: 'KJ',
        longName: 'Kelana Jaya Line',
        mode: TransitMode.lrt,
        colorHex: 'E31E24',
        operatorName: 'Rapid KL',
        shape: const [
          TransitCoordinate(3.00, 101.00),
          TransitCoordinate(3.05, 101.05),
          TransitCoordinate(3.10, 101.10),
          TransitCoordinate(3.15, 101.15),
          TransitCoordinate(3.20, 101.20),
        ],
      ),
    ],
    stops: [
      for (var i = 1; i <= 5; i++)
        TransitStop(
          id: '$source:S$i',
          gtfsId: 'S$i',
          source: source,
          name: 'Stop $i',
          latitude: 3.0 + (i - 1) * 0.05,
          longitude: 101.0 + (i - 1) * 0.05,
          routeIds: const [routeId],
        ),
    ],
    edges: const [],
    patterns: [
      TransitPattern(
        id: '$routeId:pattern',
        routeId: routeId,
        gtfsTripId: 'trip-1',
        direction: 0,
        headsign: 'Stop 5',
        stopIds: stopIds,
        offsetMinutes: const [0, 3, 6, 9, 12],
        startSeconds: 0,
        endSeconds: 86399,
        headwaySeconds: 300,
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/tracking_controller.dart';
import 'package:smartroute/features/tracking/domain/models/arrival_estimate.dart';
import 'package:smartroute/features/tracking/domain/models/line_status.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';
import 'package:smartroute/features/tracking/domain/models/platform_info.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_station.dart';
import 'package:smartroute/features/tracking/domain/models/transit_direction.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart'
    as tracking;
import 'package:smartroute/features/tracking/domain/repositories/line_directory_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:smartroute/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:smartroute/shared/models/arrival_reminder.dart';
import 'package:smartroute/shared/models/transit_models.dart';
import 'package:smartroute/shared/widgets/transit_google_map.dart';

void main() {
  testWidgets('rail is presented as scheduled without a realtime dead end', (
    tester,
  ) async {
    final network = _network(TransitMode.lrt);
    final controller = TrackingController(
      trackingRepository: _TrackingRepository(const []),
      directoryRepository: _DirectoryRepository(network),
    );

    await tester.pumpWidget(_app(network, controller));
    await tester.pumpAndSettle();

    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(find.textContaining('Realtime unavailable'), findsNothing);
    expect(find.text('Scheduled times shown'), findsOneWidget);
    expect(
      find.text('STATION / STOP SEQUENCE', skipOffstage: false),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('only an official live vehicle enables the LIVE presentation', (
    tester,
  ) async {
    final network = _network(TransitMode.bus);
    final vehicle = LiveVehicle(
      vehicleId: 'vehicle-1',
      lineId: 'rapid-bus-kl:B10',
      direction: TransitDirection.forward,
      positionFraction: 0.5,
      etaMinutes: 0,
      lastUpdated: DateTime.now(),
      isLive: true,
      latitude: 3.05,
      longitude: 101.05,
      tripId: 'trip-1',
      label: 'Bus 1',
    );
    final controller = TrackingController(
      trackingRepository: _TrackingRepository([vehicle]),
      directoryRepository: _DirectoryRepository(network),
    );

    await tester.pumpWidget(_app(network, controller));
    await tester.pumpAndSettle();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('SCHEDULED'), findsNothing);
    expect(find.text('Live vehicle positions'), findsOneWidget);
    expect(find.textContaining('1 official vehicle position'), findsOneWidget);
    expect(find.text('Bus 1'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('shows only the selected scheduled bus on the map', (
    tester,
  ) async {
    final network = _network(TransitMode.bus);
    final controller = TrackingController(
      trackingRepository: _TrackingRepository(const []),
      directoryRepository: _DirectoryRepository(network),
    );

    await tester.pumpWidget(_app(network, controller));
    await tester.pumpAndSettle();

    expect(find.text('Scheduled times shown'), findsOneWidget);
    expect(find.text('Bus 1'), findsOneWidget);
    expect(find.text('Bus 2'), findsOneWidget);
    expect(_simulatedVehicleLabels(tester), hasLength(1));
    expect(_simulatedVehicleLabels(tester).single, startsWith('Bus 1'));

    await tester.tap(find.text('Bus 2'));
    await tester.pump();

    expect(_simulatedVehicleLabels(tester), hasLength(1));
    expect(_simulatedVehicleLabels(tester).single, startsWith('Bus 2'));
    controller.dispose();
  });

  testWidgets('shows the triggered demo reminder for the next stop', (
    tester,
  ) async {
    final network = _network(TransitMode.lrt);
    final controller = TrackingController(
      trackingRepository: _TrackingRepository(const []),
      directoryRepository: _DirectoryRepository(network),
    );
    final reminder = ArrivalReminder(
      id: 'demo:arrival:rapid-rail-kl:KJ:rapid-rail-kl:S2',
      userId: 'demo-passenger',
      stationId: 'rapid-rail-kl:S2',
      routeId: 'rapid-rail-kl:KJ',
      expectedArrival: DateTime.now().add(const Duration(minutes: 1)),
      leadTimeMinutes: 5,
      status: ArrivalReminderStatus.triggered,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(_app(network, controller, reminder));
    await tester.pumpAndSettle();

    expect(find.text('Demo arrival notification'), findsOneWidget);
    expect(find.textContaining('Stop 2 is the next stop'), findsOneWidget);
    controller.dispose();
  });
}

Widget _app(
  TransitNetwork network,
  TrackingController controller, [
  ArrivalReminder? demoArrivalReminder,
]) => MaterialApp(
  home: Scaffold(
    body: TrackingScreen(
      lineId: network.routes.first.id,
      controller: controller,
      network: network,
      onBack: () {},
      demoArrivalReminder: demoArrivalReminder,
    ),
  ),
);

List<String> _simulatedVehicleLabels(WidgetTester tester) {
  final map = tester.widget<TransitGoogleMap>(find.byType(TransitGoogleMap));
  return [
    for (final marker in map.markers)
      if (marker.kind == TransitMapMarkerKind.simulatedVehicle) marker.label,
  ];
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

TransitNetwork _network(TransitMode mode) {
  final routeId = mode == TransitMode.bus
      ? 'rapid-bus-kl:B10'
      : 'rapid-rail-kl:KJ';
  final source = mode == TransitMode.bus ? 'rapid-bus-kl' : 'rapid-rail-kl';
  return TransitNetwork(
    metadata: TransitMetadata(
      generatedAt: DateTime.now(),
      publisher: 'data.gov.my',
      licence: 'Open',
      routeCount: 1,
      stopCount: 2,
      edgeCount: 1,
      patternCount: 1,
      shapeRouteCount: 1,
      sources: const [],
    ),
    routes: [
      TransitRoute(
        id: routeId,
        gtfsId: mode == TransitMode.bus ? 'B10' : 'KJ',
        source: source,
        shortName: mode == TransitMode.bus ? 'B10' : 'KJ',
        longName: mode == TransitMode.bus ? 'Bus 10' : 'Kelana Jaya Line',
        mode: mode,
        colorHex: 'E31E24',
        operatorName: 'Rapid KL',
        shape: const [TransitCoordinate(3, 101), TransitCoordinate(3.1, 101.1)],
      ),
    ],
    stops: [
      TransitStop(
        id: '$source:S1',
        gtfsId: 'S1',
        source: source,
        name: 'Stop 1',
        latitude: 3,
        longitude: 101,
        routeIds: [routeId],
      ),
      TransitStop(
        id: '$source:S2',
        gtfsId: 'S2',
        source: source,
        name: 'Stop 2',
        latitude: 3.1,
        longitude: 101.1,
        routeIds: [routeId],
      ),
    ],
    edges: const [],
    patterns: [
      TransitPattern(
        id: '$routeId:pattern',
        routeId: routeId,
        gtfsTripId: 'trip-1',
        direction: 0,
        headsign: 'Stop 2',
        stopIds: ['$source:S1', '$source:S2'],
        offsetMinutes: const [0, 5],
        startSeconds: 0,
        endSeconds: 86399,
        headwaySeconds: 300,
      ),
    ],
  );
}

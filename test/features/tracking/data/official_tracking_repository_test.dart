import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/data/datasources/official_gtfs_realtime_data_source.dart';
import 'package:smartroute/features/tracking/data/repositories/official_tracking_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  final now = DateTime(2026, 8, 31, 12);
  late TransitNetwork network;

  setUp(() {
    network = _network(now);
  });

  test('maps fresh official bus vehicle to canonical route identity', () async {
    final dataSource = _RealtimeDataSource([
      RealtimeVehicleSnapshot(
        routeId: 'B10',
        tripId: 'trip-a',
        vehicleId: 'vehicle-a',
        label: 'Bus A',
        directionId: 0,
        latitude: 3.05,
        longitude: 101.05,
        bearing: 0,
        speedMetresPerSecond: 8,
        timestamp: now,
      ),
    ]);
    final repository = OfficialTrackingRepository(
      networkRepository: _NetworkRepository(network),
      realtimeDataSource: dataSource,
      clock: () => now,
    );

    final vehicles = await repository.watchVehicles('rapid-bus-kl:B10').first;

    expect(dataSource.requestedSource, 'rapid-bus-kl');
    expect(vehicles.single.lineId, 'rapid-bus-kl:B10');
    expect(vehicles.single.tripId, 'trip-a');
    expect(vehicles.single.isLive, isTrue);
    expect(vehicles.single.positionFraction, closeTo(0.5, 0.01));
  });

  test('rejects stale and identity-mismatched vehicle positions', () async {
    final dataSource = _RealtimeDataSource([
      RealtimeVehicleSnapshot(
        routeId: 'OTHER',
        tripId: 'trip-other',
        vehicleId: 'other',
        label: null,
        directionId: 0,
        latitude: 3,
        longitude: 101,
        bearing: null,
        speedMetresPerSecond: null,
        timestamp: now,
      ),
      RealtimeVehicleSnapshot(
        routeId: 'B10',
        tripId: 'stale',
        vehicleId: 'stale',
        label: null,
        directionId: 0,
        latitude: 3,
        longitude: 101,
        bearing: null,
        speedMetresPerSecond: null,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    ]);
    final repository = OfficialTrackingRepository(
      networkRepository: _NetworkRepository(network),
      realtimeDataSource: dataSource,
      clock: () => now,
    );

    expect(await repository.watchVehicles('rapid-bus-kl:B10').first, isEmpty);
  });

  test('maps MRT feeder realtime route code to canonical GTFS route', () async {
    final dataSource = _RealtimeDataSource([
      RealtimeVehicleSnapshot(
        routeId: 'T102',
        tripId: 'feeder-trip',
        vehicleId: 'feeder-vehicle',
        label: 'Feeder',
        directionId: 0,
        latitude: 3.05,
        longitude: 101.05,
        bearing: null,
        speedMetresPerSecond: null,
        timestamp: now,
      ),
    ]);
    final repository = OfficialTrackingRepository(
      networkRepository: _NetworkRepository(network),
      realtimeDataSource: dataSource,
      clock: () => now,
    );

    final vehicles = await repository
        .watchVehicles('rapid-bus-mrtfeeder:30000120')
        .first;

    expect(dataSource.requestedSource, 'rapid-bus-mrtfeeder');
    expect(vehicles.single.lineId, 'rapid-bus-mrtfeeder:30000120');
    expect(vehicles.single.isLive, isTrue);
  });

  test('rail never calls a vehicle feed and returns scheduled state', () async {
    final dataSource = _RealtimeDataSource(const []);
    final repository = OfficialTrackingRepository(
      networkRepository: _NetworkRepository(network),
      realtimeDataSource: dataSource,
      clock: () => now,
    );

    final vehicles = await repository.watchVehicles('rapid-rail-kl:KJ').first;

    expect(vehicles, isEmpty);
    expect(dataSource.requestedSource, isNull);
  });

  test('arrival estimate is schedule-derived and never marked live', () async {
    final repository = OfficialTrackingRepository(
      networkRepository: _NetworkRepository(network),
      realtimeDataSource: _RealtimeDataSource(const []),
      clock: () => now,
    );

    final arrivals = await repository
        .watchArrivals(
          lineId: 'rapid-rail-kl:KJ',
          stationId: 'rapid-rail-kl:S1',
        )
        .first;

    expect(arrivals, hasLength(1));
    expect(arrivals.single.isLive, isFalse);
    expect(arrivals.single.etaMinutes, 0);
  });
}

class _RealtimeDataSource extends OfficialGtfsRealtimeDataSource {
  final List<RealtimeVehicleSnapshot> snapshots;
  String? requestedSource;

  _RealtimeDataSource(this.snapshots)
    : super(fetchBytes: (_) async => Uint8List(0));

  @override
  Stream<List<RealtimeVehicleSnapshot>> watchVehicles(String source) {
    requestedSource = source;
    return Stream.value(snapshots);
  }
}

class _NetworkRepository implements TransitNetworkRepository {
  final TransitNetwork network;

  const _NetworkRepository(this.network);

  @override
  Future<TransitNetwork> loadNetwork() async => network;
}

TransitNetwork _network(DateTime now) => TransitNetwork(
  metadata: TransitMetadata(
    generatedAt: now,
    publisher: 'data.gov.my',
    licence: 'Open',
    routeCount: 3,
    stopCount: 2,
    edgeCount: 2,
    patternCount: 1,
    shapeRouteCount: 2,
    sources: const [],
  ),
  routes: const [
    TransitRoute(
      id: 'rapid-bus-kl:B10',
      gtfsId: 'B10',
      source: 'rapid-bus-kl',
      shortName: 'B10',
      longName: 'Bus 10',
      mode: TransitMode.bus,
      colorHex: 'F59E0B',
      operatorName: 'Rapid KL',
      shape: [
        TransitCoordinate(3, 101),
        TransitCoordinate(3.05, 101.05),
        TransitCoordinate(3.1, 101.1),
      ],
    ),
    TransitRoute(
      id: 'rapid-rail-kl:KJ',
      gtfsId: 'KJ',
      source: 'rapid-rail-kl',
      shortName: 'KJ',
      longName: 'Kelana Jaya Line',
      mode: TransitMode.lrt,
      colorHex: '009FE3',
      operatorName: 'Rapid KL',
      shape: [TransitCoordinate(3, 101), TransitCoordinate(3.1, 101.1)],
    ),
    TransitRoute(
      id: 'rapid-bus-mrtfeeder:30000120',
      gtfsId: '30000120',
      source: 'rapid-bus-mrtfeeder',
      shortName: '',
      longName: 'T102',
      mode: TransitMode.bus,
      colorHex: 'F59E0B',
      operatorName: 'Rapid KL',
      shape: [TransitCoordinate(3, 101), TransitCoordinate(3.1, 101.1)],
    ),
  ],
  stops: const [
    TransitStop(
      id: 'rapid-rail-kl:S1',
      gtfsId: 'S1',
      source: 'rapid-rail-kl',
      name: 'Station 1',
      latitude: 3,
      longitude: 101,
      routeIds: ['rapid-rail-kl:KJ'],
    ),
    TransitStop(
      id: 'rapid-rail-kl:S2',
      gtfsId: 'S2',
      source: 'rapid-rail-kl',
      name: 'Station 2',
      latitude: 3.1,
      longitude: 101.1,
      routeIds: ['rapid-rail-kl:KJ'],
    ),
  ],
  edges: const [],
  patterns: const [
    TransitPattern(
      id: 'pattern',
      routeId: 'rapid-rail-kl:KJ',
      gtfsTripId: 'trip',
      direction: 0,
      headsign: 'Station 2',
      stopIds: ['rapid-rail-kl:S1', 'rapid-rail-kl:S2'],
      offsetMinutes: [0, 5],
      startSeconds: 43200,
      endSeconds: 46800,
      headwaySeconds: 300,
    ),
  ],
);

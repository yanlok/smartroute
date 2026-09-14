import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/planner/domain/route_planner_service.dart';
import 'package:smartroute/features/transit_network/data/bundled_transit_network_repository.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TransitNetwork network;

  setUpAll(() async {
    network = await BundledTransitNetworkRepository().loadNetwork();
  });

  test('loads the complete normalized official snapshot', () {
    expect(network.metadata.publisher, contains('data.gov.my'));
    expect(
      network.metadata.generatedAt,
      DateTime.parse('2026-08-31T12:21:11Z'),
    );
    expect(network.metadata.routeCount, 237);
    expect(network.metadata.stopCount, greaterThan(6000));
    expect(network.metadata.patternCount, greaterThan(250));
    expect(network.metadata.shapeRouteCount, greaterThan(230));
    expect(
      network.routes.map((route) => route.id).toSet().length,
      network.routes.length,
    );
    expect(
      network.stops.map((stop) => stop.id).toSet().length,
      network.stops.length,
    );
  });

  test('contains required Klang Valley modes and real line identities', () {
    expect(
      network.routes.map((route) => route.mode).toSet(),
      containsAll({
        TransitMode.lrt,
        TransitMode.mrt,
        TransitMode.monorail,
        TransitMode.brt,
        TransitMode.bus,
      }),
    );
    final kelanaJaya = network.routesById['rapid-rail-kl:KJ'];
    expect(kelanaJaya, isNotNull);
    expect(kelanaJaya!.gtfsId, 'KJ');
    expect(kelanaJaya.mode, TransitMode.lrt);
    expect(kelanaJaya.shape, hasLength(240));
    expect(
      network.stopsById['rapid-rail-kl:KJ21']!.routeIds,
      contains(kelanaJaya.id),
    );
  });

  test('retains schedule patterns for scheduled rail progress', () {
    final pattern = network.patternForRouteAndStop(
      'rapid-rail-kl:KJ',
      'rapid-rail-kl:KJ21',
    );
    expect(pattern, isNotNull);
    expect(pattern!.gtfsTripId, startsWith('KJL_'));
    expect(pattern.stopIds, hasLength(37));
    expect(pattern.headwaySeconds, greaterThan(0));
    expect(
      pattern.nextDeparture('rapid-rail-kl:KJ21', DateTime(2026, 8, 31, 8)),
      isNotNull,
    );
  });

  test('finds the next departure while overnight service is still running', () {
    const pattern = TransitPattern(
      id: 'overnight',
      routeId: 'night-line',
      gtfsTripId: 'night-trip',
      direction: 0,
      headsign: 'City Centre',
      stopIds: ['night-stop'],
      offsetMinutes: [0],
      startSeconds: 23 * 60 * 60 + 30 * 60,
      endSeconds: 6 * 60 * 60,
      headwaySeconds: 15 * 60,
    );

    expect(pattern.effectiveEndSeconds, 30 * 60 * 60);
    expect(
      pattern.nextDeparture('night-stop', DateTime(2026, 9, 14, 0, 5)),
      DateTime(2026, 9, 14, 0, 15),
    );
  });

  test('plans beyond the old handcrafted location set', () {
    final planner = RoutePlannerService(network);
    final routes = planner.plan(
      originStopId: 'rapid-rail-kl:KJ37',
      destinationStopId: 'rapid-rail-kl:KJ1',
      allowedModes: {TransitMode.lrt},
    );

    expect(routes, isNotEmpty);
    expect(
      routes.first.segments.map((segment) => segment.routeId),
      contains('rapid-rail-kl:KJ'),
    );
    expect(
      routes.first.segments.fold<int>(
        0,
        (total, segment) => total + segment.stopCount,
      ),
      greaterThan(30),
    );
  });
}

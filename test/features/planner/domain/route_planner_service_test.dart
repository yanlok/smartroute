import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/planner/domain/route_planner_service.dart';
import 'package:smartroute/shared/models/journey_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  group('RoutePlannerService', () {
    test('finds a direct rail route', () {
      final planner = RoutePlannerService(_baseNetwork());

      final routes = planner.plan(
        originStopId: 'a',
        destinationStopId: 'c',
        allowedModes: {TransitMode.lrt},
      );

      expect(routes, isNotEmpty);
      expect(routes.first.transferCount, 0);
      expect(routes.first.segments, hasLength(1));
      expect(routes.first.segments.single.routeId, 'lrt');
      expect(routes.first.segments.single.stopCount, 2);
    });

    test('finds a one-transfer rail route', () {
      final planner = RoutePlannerService(_baseNetwork());

      final routes = planner.plan(
        originStopId: 'a',
        destinationStopId: 'd',
        allowedModes: {TransitMode.lrt, TransitMode.mrt},
      );

      expect(routes, isNotEmpty);
      expect(routes.first.transferCount, 1);
      expect(routes.first.segments.map((segment) => segment.routeId), [
        'lrt',
        'mrt',
      ]);
    });

    test('returns distinct multimodal alternatives', () {
      final planner = RoutePlannerService(_baseNetwork());

      final routes = planner.plan(originStopId: 'a', destinationStopId: 'd');
      final usedModes = routes
          .expand((route) => route.segments)
          .map((segment) => segment.mode)
          .whereType<TransitMode>()
          .toSet();

      expect(
        usedModes,
        containsAll({TransitMode.lrt, TransitMode.mrt, TransitMode.bus}),
      );
      expect(
        routes.map((route) => route.signature).toSet().length,
        routes.length,
      );
    });

    test('returns no route for an unreachable destination', () {
      final planner = RoutePlannerService(_baseNetwork());

      final routes = planner.plan(originStopId: 'a', destinationStopId: 'u');

      expect(routes, isEmpty);
    });

    test('handles the same origin and destination', () {
      final planner = RoutePlannerService(_baseNetwork());

      final routes = planner.plan(originStopId: 'a', destinationStopId: 'a');

      expect(routes.single.durationMinutes, 0);
      expect(routes.single.segments, isEmpty);
    });

    test('respects a mode filter', () {
      final planner = RoutePlannerService(_baseNetwork());

      final routes = planner.plan(
        originStopId: 'a',
        destinationStopId: 'd',
        allowedModes: {TransitMode.bus},
      );

      expect(routes, isNotEmpty);
      expect(
        routes
            .expand((route) => route.segments)
            .where((segment) => !segment.isWalking),
        everyElement(
          predicate<JourneySegment>(
            (segment) => segment.mode == TransitMode.bus,
          ),
        ),
      );
    });

    test('fewer transfers can prefer a slower direct service', () {
      final planner = RoutePlannerService(_baseNetwork());

      final routes = planner.plan(originStopId: 'a', destinationStopId: 'd');
      final fastest = routes.firstWhere(
        (route) => route.objective == RouteObjective.fastest,
      );
      final fewerTransfers = routes.firstWhere(
        (route) => route.objective == RouteObjective.fewerTransfers,
      );

      expect(fastest.transferCount, 1);
      expect(fewerTransfers.transferCount, 0);
      expect(
        fewerTransfers.durationMinutes,
        greaterThan(fastest.durationMinutes),
      );
    });

    test('least walking preference avoids a shorter long transfer', () {
      final planner = RoutePlannerService(_walkingNetwork());

      final fastest = planner.planForObjective(
        originStopId: 'a',
        destinationStopId: 'd',
        objective: RouteObjective.fastest,
      )!;
      final leastWalking = planner.planForObjective(
        originStopId: 'a',
        destinationStopId: 'd',
        objective: RouteObjective.leastWalking,
      )!;

      expect(fastest.walkingMetres, 300);
      expect(leastWalking.walkingMetres, 0);
      expect(leastWalking.segments.single.routeId, 'bus');
    });

    test('route ordering and signatures are stable', () {
      final planner = RoutePlannerService(_baseNetwork());

      final first = planner.plan(originStopId: 'a', destinationStopId: 'd');
      final second = planner.plan(originStopId: 'a', destinationStopId: 'd');

      expect(
        second.map((route) => '${route.objective.name}:${route.signature}'),
        first.map((route) => '${route.objective.name}:${route.signature}'),
      );
    });
  });

  test('JourneyMapProjector uses GTFS route shape between stops', () {
    final network = _baseNetwork();
    final journey = RoutePlannerService(network)
        .plan(
          originStopId: 'a',
          destinationStopId: 'c',
          allowedModes: {TransitMode.lrt},
        )
        .first;

    final points = const JourneyMapProjector().coordinatesFor(journey, network);

    expect(points.first.latitude, 3.00);
    expect(points.last.latitude, 3.02);
    expect(points.length, greaterThanOrEqualTo(3));
  });
}

TransitNetwork _baseNetwork() => _network(
  edges: const [
    TransitEdge(
      fromStopId: 'a',
      toStopId: 'b',
      routeId: 'lrt',
      minutes: 5,
      walkingMetres: 0,
    ),
    TransitEdge(
      fromStopId: 'b',
      toStopId: 'c',
      routeId: 'lrt',
      minutes: 5,
      walkingMetres: 0,
    ),
    TransitEdge(
      fromStopId: 'b',
      toStopId: 'd',
      routeId: 'mrt',
      minutes: 5,
      walkingMetres: 0,
    ),
    TransitEdge(
      fromStopId: 'a',
      toStopId: 'e',
      routeId: 'bus',
      minutes: 10,
      walkingMetres: 0,
    ),
    TransitEdge(
      fromStopId: 'e',
      toStopId: 'd',
      routeId: 'bus',
      minutes: 10,
      walkingMetres: 0,
    ),
  ],
);

TransitNetwork _walkingNetwork() => _network(
  stops: const [
    TransitStop(
      id: 'a',
      gtfsId: 'A',
      source: 'test',
      name: 'A',
      latitude: 3,
      longitude: 101,
      routeIds: ['lrt', 'bus'],
    ),
    TransitStop(
      id: 'b',
      gtfsId: 'B',
      source: 'test',
      name: 'B',
      latitude: 3.01,
      longitude: 101,
      routeIds: ['lrt'],
    ),
    TransitStop(
      id: 'x',
      gtfsId: 'X',
      source: 'test',
      name: 'X',
      latitude: 3.011,
      longitude: 101,
      routeIds: ['mrt'],
    ),
    TransitStop(
      id: 'd',
      gtfsId: 'D',
      source: 'test',
      name: 'D',
      latitude: 3.03,
      longitude: 101,
      routeIds: ['mrt', 'bus'],
    ),
  ],
  edges: const [
    TransitEdge(
      fromStopId: 'a',
      toStopId: 'b',
      routeId: 'lrt',
      minutes: 4,
      walkingMetres: 0,
    ),
    TransitEdge(
      fromStopId: 'b',
      toStopId: 'x',
      routeId: null,
      minutes: 4,
      walkingMetres: 300,
    ),
    TransitEdge(
      fromStopId: 'x',
      toStopId: 'd',
      routeId: 'mrt',
      minutes: 3,
      walkingMetres: 0,
    ),
    TransitEdge(
      fromStopId: 'a',
      toStopId: 'd',
      routeId: 'bus',
      minutes: 22,
      walkingMetres: 0,
    ),
  ],
);

TransitNetwork _network({
  List<TransitStop>? stops,
  required List<TransitEdge> edges,
}) {
  return TransitNetwork(
    metadata: TransitMetadata(
      generatedAt: DateTime.utc(2026, 8, 31),
      publisher: 'Test',
      licence: 'Test',
      routeCount: 3,
      stopCount: stops?.length ?? 6,
      edgeCount: edges.length,
      patternCount: 0,
      shapeRouteCount: 3,
      sources: const [],
    ),
    routes: const [
      TransitRoute(
        id: 'lrt',
        gtfsId: 'L',
        source: 'test',
        shortName: 'L',
        longName: 'LRT Line',
        mode: TransitMode.lrt,
        colorHex: '#E31837',
        operatorName: 'Test',
        shape: [
          TransitCoordinate(3.00, 101),
          TransitCoordinate(3.01, 101),
          TransitCoordinate(3.02, 101),
        ],
      ),
      TransitRoute(
        id: 'mrt',
        gtfsId: 'M',
        source: 'test',
        shortName: 'M',
        longName: 'MRT Line',
        mode: TransitMode.mrt,
        colorHex: '#1B4FD8',
        operatorName: 'Test',
        shape: [],
      ),
      TransitRoute(
        id: 'bus',
        gtfsId: 'B',
        source: 'test',
        shortName: 'B',
        longName: 'Bus Route',
        mode: TransitMode.bus,
        colorHex: '#2563EB',
        operatorName: 'Test',
        shape: [],
      ),
    ],
    stops:
        stops ??
        const [
          TransitStop(
            id: 'a',
            gtfsId: 'A',
            source: 'test',
            name: 'A',
            latitude: 3.00,
            longitude: 101,
            routeIds: ['lrt', 'bus'],
          ),
          TransitStop(
            id: 'b',
            gtfsId: 'B',
            source: 'test',
            name: 'B',
            latitude: 3.01,
            longitude: 101,
            routeIds: ['lrt', 'mrt'],
          ),
          TransitStop(
            id: 'c',
            gtfsId: 'C',
            source: 'test',
            name: 'C',
            latitude: 3.02,
            longitude: 101,
            routeIds: ['lrt'],
          ),
          TransitStop(
            id: 'd',
            gtfsId: 'D',
            source: 'test',
            name: 'D',
            latitude: 3.03,
            longitude: 101,
            routeIds: ['mrt', 'bus'],
          ),
          TransitStop(
            id: 'e',
            gtfsId: 'E',
            source: 'test',
            name: 'E',
            latitude: 3.015,
            longitude: 101,
            routeIds: ['bus'],
          ),
          TransitStop(
            id: 'u',
            gtfsId: 'U',
            source: 'test',
            name: 'U',
            latitude: 4,
            longitude: 102,
            routeIds: [],
          ),
        ],
    edges: edges,
    patterns: const [],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/planner/application/planner_controller.dart';
import 'package:smartroute/features/planner/screens/planner_screen.dart';
import 'package:smartroute/features/user_management/application/saved_journey_controller.dart';
import 'package:smartroute/features/user_management/domain/models/saved_journey.dart';
import 'package:smartroute/features/user_management/domain/repositories/saved_journey_repository.dart';
import 'package:smartroute/shared/contracts/location_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/journey_models.dart';
import 'package:smartroute/shared/models/location_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  testWidgets(
    'PlannerScreen renders spatial journey composer, mode rail, and triggers planning',
    (tester) async {
      final network = _network();
      final plannerController = PlannerController(
        networkRepository: _FakeNetworkRepo(network),
        locationRepository: _FakeLocationRepo(),
      );
      final savedJourneys = SavedJourneyController(
        repository: _FakeSavedJourneyRepo(),
      );

      var routesReadyCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PlannerScreen(
            controller: plannerController,
            savedJourneys: savedJourneys,
            userId: 'user-1',
            locationEnabled: true,
            onRoutesReady: () {
              routesReadyCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan journey'), findsOneWidget);
      expect(find.text('FROM'), findsOneWidget);
      expect(find.text('TO'), findsOneWidget);
      expect(find.text('Nearby origin'), findsOneWidget);

      expect(find.text('TRANSPORT MODES'), findsOneWidget);
      expect(find.text('LRT'), findsOneWidget);
      expect(find.text('MRT'), findsOneWidget);
      expect(find.text('Monorail'), findsOneWidget);
      expect(find.text('BRT'), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);

      expect(find.text('Compare SmartRoute options'), findsOneWidget);
      expect(
        find.text('Official Malaysian GTFS · SmartRoute routing'),
        findsOneWidget,
      );

      plannerController.selectOrigin(network.stops[0]);
      plannerController.selectDestination(network.stops[1]);
      await tester.pumpAndSettle();

      expect(find.text('Origin Station'), findsOneWidget);
      expect(find.text('Destination Station'), findsOneWidget);

      await tester.tap(find.text('Compare SmartRoute options'));
      await tester.pumpAndSettle();

      expect(routesReadyCalled, isTrue);

      plannerController.dispose();
      savedJourneys.dispose();
    },
  );
}

class _FakeNetworkRepo implements TransitNetworkRepository {
  final TransitNetwork network;
  _FakeNetworkRepo(this.network);

  @override
  Future<TransitNetwork> loadNetwork() async => network;
}

class _FakeLocationRepo implements LocationRepository {
  @override
  Future<LocationResult> getCurrentLocation({
    required bool preferenceEnabled,
  }) async => const LocationResult.success(
    DeviceLocation(latitude: 3.0, longitude: 101.0),
  );
}

class _FakeSavedJourneyRepo implements SavedJourneyRepository {
  @override
  Future<List<FavoriteJourney>> getFavorites(String userId) async => [];

  @override
  Future<List<RecentJourney>> getRecentSearches(String userId) async => [];

  @override
  Future<void> deleteFavorite(String favoriteId) async {}

  @override
  Future<RecentJourney> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  }) async => RecentJourney(
    id: 'rec-1',
    userId: userId,
    originStopId: originStopId,
    destinationStopId: destinationStopId,
    searchedAt: DateTime.now(),
  );

  @override
  Future<FavoriteJourney> saveFavorite({
    required String userId,
    required String label,
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
  }) => throw UnimplementedError();
}

TransitNetwork _network() => TransitNetwork(
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
  routes: const [
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
  ],
  stops: const [
    TransitStop(
      id: 'rapid-rail-kl:S1',
      gtfsId: 'S1',
      source: 'rapid-rail-kl',
      name: 'Origin Station',
      latitude: 3,
      longitude: 101,
      routeIds: ['rapid-rail-kl:KJ'],
    ),
    TransitStop(
      id: 'rapid-rail-kl:S2',
      gtfsId: 'S2',
      source: 'rapid-rail-kl',
      name: 'Destination Station',
      latitude: 3.1,
      longitude: 101.1,
      routeIds: ['rapid-rail-kl:KJ'],
    ),
  ],
  edges: const [
    TransitEdge(
      fromStopId: 'rapid-rail-kl:S1',
      toStopId: 'rapid-rail-kl:S2',
      routeId: 'rapid-rail-kl:KJ',
      minutes: 10,
      walkingMetres: 0,
    ),
  ],
  patterns: const [],
);

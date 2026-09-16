import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/user_management/application/saved_journey_controller.dart';
import 'package:smartroute/features/user_management/domain/models/saved_journey.dart';
import 'package:smartroute/features/user_management/domain/repositories/saved_journey_repository.dart';
import 'package:smartroute/shared/models/journey_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  late _MemorySavedJourneyRepository repository;
  late SavedJourneyController controller;

  setUp(() {
    repository = _MemorySavedJourneyRepository();
    controller = SavedJourneyController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test('loads persisted favourites and bounded recent searches', () async {
    repository.favorites.add(_favorite('saved'));
    repository.recents.add(_recent('recent'));

    await controller.load('user-a');

    expect(controller.favorites.single.id, 'saved');
    expect(controller.recentSearches.single.id, 'recent');
  });

  test('saving and removing a favourite closes the controller loop', () async {
    final network = _network();
    final journey = _journey();

    expect(
      await controller.saveFavorite(
        userId: 'user-a',
        journey: journey,
        network: network,
      ),
      isTrue,
    );
    expect(controller.containsJourney(journey), isTrue);
    expect(repository.favorites.single.label, 'Origin to Destination');

    expect(
      await controller.removeFavorite(controller.favorites.single),
      isTrue,
    );
    expect(controller.favorites, isEmpty);
    expect(repository.favorites, isEmpty);
  });

  test('saving and removing a favourite station closes the loop', () async {
    final network = _networkWithRoute();
    final station = network.stops.first;
    final route = network.routes.first;

    expect(
      await controller.toggleFavoriteStation(
        userId: 'user-a',
        station: station,
        route: route,
      ),
      isTrue,
    );
    expect(controller.containsStation(station.id, route.id), isTrue);
    expect(controller.containsStationId(station.id), isTrue);
    expect(repository.favoriteStations.single.stationId, station.id);
    expect(controller.favoriteRouteIds, {route.id});

    expect(
      await controller.toggleFavoriteStation(
        userId: 'user-a',
        station: station,
        route: route,
      ),
      isTrue,
    );
    expect(controller.favoriteStations, isEmpty);
    expect(controller.containsStationId(station.id), isFalse);
    expect(controller.favoriteRouteIds, isEmpty);
  });

  test(
    'favourite station state updates before persistence completes',
    () async {
      final network = _networkWithRoute();
      final station = network.stops.first;
      final route = network.routes.first;
      repository.favoriteStationSaveGate = Completer<FavoriteStation>();

      final operation = controller.toggleFavoriteStation(
        userId: 'user-a',
        station: station,
        route: route,
      );

      expect(controller.containsStation(station.id, route.id), isTrue);

      repository.favoriteStationSaveGate!.complete(
        FavoriteStation(
          id: 'persisted-station',
          userId: 'user-a',
          stationId: station.id,
          routeId: route.id,
          label: station.name,
          updatedAt: DateTime(2026, 9, 16),
        ),
      );

      expect(await operation, isTrue);
      expect(controller.favoriteStations.single.id, 'persisted-station');
    },
  );

  test(
    'recent search upsert avoids duplicate origin destination rows',
    () async {
      await controller.recordSearch(
        userId: 'user-a',
        originStopId: 'origin',
        destinationStopId: 'destination',
      );
      await controller.recordSearch(
        userId: 'user-a',
        originStopId: 'origin',
        destinationStopId: 'destination',
      );

      expect(controller.recentSearches, hasLength(1));
      expect(repository.recents, hasLength(1));
    },
  );

  test('reset removes user-owned state at logout', () async {
    repository.favorites.add(_favorite('saved'));
    await controller.load('user-a');

    controller.reset();

    expect(controller.favorites, isEmpty);
    expect(controller.favoriteStations, isEmpty);
    expect(controller.recentSearches, isEmpty);
  });
}

class _MemorySavedJourneyRepository implements SavedJourneyRepository {
  final List<FavoriteJourney> favorites = [];
  final List<FavoriteStation> favoriteStations = [];
  final List<RecentJourney> recents = [];
  var sequence = 0;
  Completer<FavoriteStation>? favoriteStationSaveGate;

  @override
  Future<void> deleteFavorite(String favoriteId) async {
    favorites.removeWhere((item) => item.id == favoriteId);
  }

  @override
  Future<void> deleteFavoriteStation(String favoriteId) async {
    favoriteStations.removeWhere((item) => item.id == favoriteId);
  }

  @override
  Future<List<FavoriteJourney>> getFavorites(String userId) async =>
      List.unmodifiable(favorites);

  @override
  Future<List<FavoriteStation>> getFavoriteStations(String userId) async =>
      List.unmodifiable(favoriteStations);

  @override
  Future<List<RecentJourney>> getRecentSearches(String userId) async =>
      List.unmodifiable(recents);

  @override
  Future<RecentJourney> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  }) async {
    recents.removeWhere(
      (item) =>
          item.userId == userId &&
          item.originStopId == originStopId &&
          item.destinationStopId == destinationStopId,
    );
    final result = RecentJourney(
      id: 'recent-${sequence++}',
      userId: userId,
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      searchedAt: DateTime(2026, 8, 31),
    );
    recents.insert(0, result);
    return result;
  }

  @override
  Future<FavoriteJourney> saveFavorite({
    required String userId,
    required String label,
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
  }) async {
    final result = FavoriteJourney(
      id: 'favorite-${sequence++}',
      userId: userId,
      label: label,
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      objective: objective,
      updatedAt: DateTime(2026, 8, 31),
    );
    favorites.add(result);
    return result;
  }

  @override
  Future<FavoriteStation> saveFavoriteStation({
    required String userId,
    required String stationId,
    required String routeId,
    required String label,
  }) async {
    final gate = favoriteStationSaveGate;
    if (gate != null) return gate.future;
    final result = FavoriteStation(
      id: 'station-${sequence++}',
      userId: userId,
      stationId: stationId,
      routeId: routeId,
      label: label,
      updatedAt: DateTime(2026, 8, 31),
    );
    favoriteStations.add(result);
    return result;
  }
}

FavoriteJourney _favorite(String id) => FavoriteJourney(
  id: id,
  userId: 'user-a',
  label: 'Origin to Destination',
  originStopId: 'origin',
  destinationStopId: 'destination',
  objective: RouteObjective.fastest,
  updatedAt: DateTime(2026, 8, 31),
);

RecentJourney _recent(String id) => RecentJourney(
  id: id,
  userId: 'user-a',
  originStopId: 'origin',
  destinationStopId: 'destination',
  searchedAt: DateTime(2026, 8, 31),
);

JourneyOption _journey() => const JourneyOption(
  id: 'journey',
  objective: RouteObjective.fastest,
  originStopId: 'origin',
  destinationStopId: 'destination',
  durationMinutes: 8,
  transferCount: 0,
  walkingMetres: 0,
  segments: [],
);

TransitNetwork _network() => TransitNetwork(
  metadata: TransitMetadata(
    generatedAt: DateTime(2026, 8, 31),
    publisher: 'data.gov.my',
    licence: 'Open',
    routeCount: 0,
    stopCount: 2,
    edgeCount: 0,
    patternCount: 0,
    shapeRouteCount: 0,
    sources: const [],
  ),
  routes: const [],
  stops: const [
    TransitStop(
      id: 'origin',
      gtfsId: 'origin',
      source: 'test',
      name: 'Origin',
      latitude: 3,
      longitude: 101,
      routeIds: [],
    ),
    TransitStop(
      id: 'destination',
      gtfsId: 'destination',
      source: 'test',
      name: 'Destination',
      latitude: 3.1,
      longitude: 101.1,
      routeIds: [],
    ),
  ],
  edges: const [],
  patterns: const [],
);

TransitNetwork _networkWithRoute() => TransitNetwork(
  metadata: _network().metadata,
  routes: const [
    TransitRoute(
      id: 'route',
      gtfsId: 'route',
      source: 'test',
      shortName: 'R',
      longName: 'Test Route',
      mode: TransitMode.bus,
      colorHex: '000000',
      operatorName: 'Test',
      shape: [],
    ),
  ],
  stops: _network().stops,
  edges: const [],
  patterns: const [],
);

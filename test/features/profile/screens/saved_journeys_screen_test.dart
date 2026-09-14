import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/profile/screens/saved_journeys_screen.dart';
import 'package:smartroute/features/user_management/application/saved_journey_controller.dart';
import 'package:smartroute/features/user_management/domain/models/saved_journey.dart';
import 'package:smartroute/features/user_management/domain/repositories/saved_journey_repository.dart';
import 'package:smartroute/shared/models/journey_models.dart';

class FakeSavedJourneyRepository implements SavedJourneyRepository {
  final List<FavoriteJourney> favorites;
  String? deletedId;

  FakeSavedJourneyRepository(this.favorites);

  @override
  Future<void> deleteFavorite(String favoriteId) async {
    deletedId = favoriteId;
    favorites.removeWhere((item) => item.id == favoriteId);
  }

  @override
  Future<List<FavoriteJourney>> getFavorites(String userId) async => favorites;

  @override
  Future<List<RecentJourney>> getRecentSearches(String userId) async =>
      const [];

  @override
  Future<RecentJourney> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  }) => throw UnimplementedError();

  @override
  Future<FavoriteJourney> saveFavorite({
    required String userId,
    required String label,
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
  }) => throw UnimplementedError();
}

void main() {
  FavoriteJourney favorite() => FavoriteJourney(
    id: 'favorite-1',
    userId: 'user-1',
    label: 'Morning commute',
    originStopId: 'stop-a',
    destinationStopId: 'stop-b',
    objective: RouteObjective.fastest,
    updatedAt: DateTime(2026, 9, 14),
  );

  Widget app({
    required SavedJourneyController controller,
    required Future<void> Function(String, String) onReplan,
  }) => MaterialApp(
    home: Scaffold(
      body: SavedJourneysScreen(
        userId: 'user-1',
        controller: controller,
        network: null,
        onBack: () {},
        onReplan: onReplan,
      ),
    ),
  );

  testWidgets('shows a truthful empty state', (tester) async {
    final controller = SavedJourneyController(
      repository: FakeSavedJourneyRepository([]),
    );
    await controller.load('user-1');

    await tester.pumpWidget(
      app(controller: controller, onReplan: (_, _) async {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved journeys yet'), findsOneWidget);
  });

  testWidgets('opens and removes a saved journey', (tester) async {
    final repository = FakeSavedJourneyRepository([favorite()]);
    final controller = SavedJourneyController(repository: repository);
    await controller.load('user-1');
    String? origin;
    String? destination;

    await tester.pumpWidget(
      app(
        controller: controller,
        onReplan: (from, to) async {
          origin = from;
          destination = to;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Morning commute'), findsOneWidget);
    expect(find.text('stop-a to stop-b'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saved_journey_favorite-1')));
    await tester.pump();
    expect(origin, 'stop-a');
    expect(destination, 'stop-b');

    await tester.tap(find.byKey(const Key('remove_saved_journey_favorite-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_remove_saved_journey')));
    await tester.pumpAndSettle();

    expect(repository.deletedId, 'favorite-1');
    expect(find.text('No saved journeys yet'), findsOneWidget);
  });
}

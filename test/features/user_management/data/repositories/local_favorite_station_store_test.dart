import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartroute/features/user_management/data/repositories/local_favorite_station_store.dart';
import 'package:smartroute/features/user_management/domain/models/saved_journey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists favourite stations by user and supports deletion', () async {
    final store = SharedPreferencesFavoriteStationStore();
    final favorite = FavoriteStation(
      id: 'local:user-a:station-a:route-a',
      userId: 'user-a',
      stationId: 'station-a',
      routeId: 'route-a',
      label: 'Hab Bas AU3',
      updatedAt: DateTime.utc(2026, 9, 16),
    );

    await store.upsert(favorite);

    expect(await store.getForUser('user-a'), hasLength(1));
    expect(await store.getForUser('user-b'), isEmpty);

    await store.delete(favorite.id);

    expect(await store.getForUser('user-a'), isEmpty);
  });

  test('upsert replaces the same station and route pair', () async {
    final store = SharedPreferencesFavoriteStationStore();
    final original = FavoriteStation(
      id: 'local:first',
      userId: 'user-a',
      stationId: 'station-a',
      routeId: 'route-a',
      label: 'Original',
      updatedAt: DateTime.utc(2026, 9, 15),
    );
    final updated = FavoriteStation(
      id: 'remote-id',
      userId: 'user-a',
      stationId: 'station-a',
      routeId: 'route-a',
      label: 'Updated',
      updatedAt: DateTime.utc(2026, 9, 16),
    );

    await store.upsert(original);
    await store.upsert(updated);

    final favorites = await store.getForUser('user-a');
    expect(favorites, hasLength(1));
    expect(favorites.single.id, 'remote-id');
    expect(favorites.single.label, 'Updated');
  });
}

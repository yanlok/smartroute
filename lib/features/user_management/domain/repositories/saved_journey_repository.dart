import '../../../../shared/models/journey_models.dart';
import '../models/saved_journey.dart';

abstract class SavedJourneyRepository {
  Future<List<FavoriteJourney>> getFavorites(String userId);

  Future<List<RecentJourney>> getRecentSearches(String userId);

  Future<FavoriteJourney> saveFavorite({
    required String userId,
    required String label,
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
  });

  Future<void> deleteFavorite(String favoriteId);

  Future<RecentJourney> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  });
}

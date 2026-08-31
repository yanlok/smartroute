import 'package:flutter/foundation.dart';

import '../../../shared/models/journey_models.dart';
import '../../../shared/models/transit_models.dart';
import '../data/repositories/supabase_saved_journey_repository.dart';
import '../domain/models/saved_journey.dart';
import '../domain/repositories/saved_journey_repository.dart';

class SavedJourneyController extends ChangeNotifier {
  final SavedJourneyRepository _repository;
  List<FavoriteJourney> _favorites = const [];
  List<RecentJourney> _recentSearches = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadedUserId;
  String? _errorMessage;

  SavedJourneyController({required SavedJourneyRepository repository})
    : _repository = repository;

  List<FavoriteJourney> get favorites => _favorites;
  List<RecentJourney> get recentSearches => _recentSearches;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load(String userId) async {
    if (_isLoading || (_loadedUserId == userId && _errorMessage == null)) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getFavorites(userId),
        _repository.getRecentSearches(userId),
      ]);
      _favorites = results[0] as List<FavoriteJourney>;
      _recentSearches = results[1] as List<RecentJourney>;
      _loadedUserId = userId;
    } catch (error) {
      _errorMessage = _message(error, 'Journeys could not be loaded.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveFavorite({
    required String userId,
    required JourneyOption journey,
    required TransitNetwork network,
  }) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final origin = network.stopsById[journey.originStopId];
      final destination = network.stopsById[journey.destinationStopId];
      final favorite = await _repository.saveFavorite(
        userId: userId,
        label:
            '${origin?.name ?? 'Origin'} to ${destination?.name ?? 'Destination'}',
        originStopId: journey.originStopId,
        destinationStopId: journey.destinationStopId,
        objective: journey.objective,
      );
      _favorites = [
        favorite,
        ..._favorites.where((item) => item.id != favorite.id),
      ];
      return true;
    } catch (error) {
      _errorMessage = _message(error, 'Journey could not be saved.');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> removeFavorite(FavoriteJourney favorite) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteFavorite(favorite.id);
      _favorites = _favorites.where((item) => item.id != favorite.id).toList();
      return true;
    } catch (error) {
      _errorMessage = _message(error, 'Saved journey could not be removed.');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  }) async {
    try {
      final recent = await _repository.recordSearch(
        userId: userId,
        originStopId: originStopId,
        destinationStopId: destinationStopId,
      );
      _recentSearches = [
        recent,
        ..._recentSearches.where(
          (item) =>
              item.id != recent.id &&
              (item.originStopId != recent.originStopId ||
                  item.destinationStopId != recent.destinationStopId),
        ),
      ].take(20).toList();
      notifyListeners();
    } catch (error) {
      _errorMessage = _message(error, 'Recent journey could not be recorded.');
      notifyListeners();
    }
  }

  bool containsJourney(JourneyOption journey) => _favorites.any(
    (favorite) =>
        favorite.originStopId == journey.originStopId &&
        favorite.destinationStopId == journey.destinationStopId &&
        favorite.objective == journey.objective,
  );

  Set<String> get favoriteRouteIds => const {};

  void reset() {
    _favorites = const [];
    _recentSearches = const [];
    _loadedUserId = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  String _message(Object error, String fallback) =>
      error is SavedJourneyException ? error.message : fallback;
}

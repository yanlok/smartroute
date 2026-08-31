import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/journey_models.dart';
import '../../domain/models/saved_journey.dart';
import '../../domain/repositories/saved_journey_repository.dart';

class SupabaseSavedJourneyRepository implements SavedJourneyRepository {
  final SupabaseClient _client;

  const SupabaseSavedJourneyRepository({required SupabaseClient client})
    : _client = client;

  @override
  Future<List<FavoriteJourney>> getFavorites(String userId) async {
    try {
      final rows = await _client
          .from('favorite_routes')
          .select(
            'id, user_id, label, origin_stop_id, destination_stop_id, objective, updated_at',
          )
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return [for (final row in rows) _favorite(row)];
    } catch (_) {
      throw const SavedJourneyException('Saved journeys could not be loaded.');
    }
  }

  @override
  Future<List<RecentJourney>> getRecentSearches(String userId) async {
    try {
      final rows = await _client
          .from('recent_searches')
          .select(
            'id, user_id, origin_stop_id, destination_stop_id, searched_at',
          )
          .eq('user_id', userId)
          .order('searched_at', ascending: false)
          .limit(20);
      return [for (final row in rows) _recent(row)];
    } catch (_) {
      throw const SavedJourneyException('Recent journeys could not be loaded.');
    }
  }

  @override
  Future<FavoriteJourney> saveFavorite({
    required String userId,
    required String label,
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
  }) async {
    try {
      final row = await _client
          .from('favorite_routes')
          .upsert({
            'user_id': userId,
            'label': label,
            'origin_stop_id': originStopId,
            'destination_stop_id': destinationStopId,
            'objective': _objectiveValue(objective),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,origin_stop_id,destination_stop_id,objective')
          .select(
            'id, user_id, label, origin_stop_id, destination_stop_id, objective, updated_at',
          )
          .single();
      return _favorite(row);
    } catch (_) {
      throw const SavedJourneyException('Journey could not be saved.');
    }
  }

  @override
  Future<void> deleteFavorite(String favoriteId) async {
    try {
      await _client.from('favorite_routes').delete().eq('id', favoriteId);
    } catch (_) {
      throw const SavedJourneyException('Saved journey could not be removed.');
    }
  }

  @override
  Future<RecentJourney> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  }) async {
    try {
      final row = await _client
          .from('recent_searches')
          .upsert({
            'user_id': userId,
            'origin_stop_id': originStopId,
            'destination_stop_id': destinationStopId,
            'searched_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,origin_stop_id,destination_stop_id')
          .select(
            'id, user_id, origin_stop_id, destination_stop_id, searched_at',
          )
          .single();
      return _recent(row);
    } catch (_) {
      throw const SavedJourneyException(
        'Recent journey could not be recorded.',
      );
    }
  }

  FavoriteJourney _favorite(Map<String, dynamic> row) => FavoriteJourney(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    label: row['label']! as String,
    originStopId: row['origin_stop_id']! as String,
    destinationStopId: row['destination_stop_id']! as String,
    objective: _objective(row['objective']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  RecentJourney _recent(Map<String, dynamic> row) => RecentJourney(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    originStopId: row['origin_stop_id']! as String,
    destinationStopId: row['destination_stop_id']! as String,
    searchedAt: DateTime.parse(row['searched_at']! as String),
  );

  RouteObjective _objective(String value) => switch (value) {
    'fewer_transfers' => RouteObjective.fewerTransfers,
    'least_walking' => RouteObjective.leastWalking,
    _ => RouteObjective.fastest,
  };

  String _objectiveValue(RouteObjective objective) => switch (objective) {
    RouteObjective.fastest => 'fastest',
    RouteObjective.fewerTransfers => 'fewer_transfers',
    RouteObjective.leastWalking => 'least_walking',
  };
}

class SavedJourneyException implements Exception {
  final String message;

  const SavedJourneyException(this.message);
}

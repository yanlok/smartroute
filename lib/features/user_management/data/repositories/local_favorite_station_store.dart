import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/saved_journey.dart';

abstract class FavoriteStationStore {
  Future<List<FavoriteStation>> getForUser(String userId);

  Future<void> upsert(FavoriteStation favorite);

  Future<void> delete(String favoriteId);
}

class SharedPreferencesFavoriteStationStore implements FavoriteStationStore {
  static const _storageKey = 'smartroute.favorite_stations.v1';

  @override
  Future<List<FavoriteStation>> getForUser(String userId) async {
    final favorites = await _read();
    return favorites.where((item) => item.userId == userId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> upsert(FavoriteStation favorite) async {
    final favorites = await _read();
    final updated = [
      favorite,
      ...favorites.where(
        (item) =>
            item.id != favorite.id &&
            (item.userId != favorite.userId ||
                item.stationId != favorite.stationId ||
                item.routeId != favorite.routeId),
      ),
    ];
    await _write(updated);
  }

  @override
  Future<void> delete(String favoriteId) async {
    final favorites = await _read();
    await _write(favorites.where((item) => item.id != favoriteId).toList());
  }

  Future<List<FavoriteStation>> _read() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final rows = jsonDecode(encoded) as List<dynamic>;
      return [
        for (final row in rows)
          _fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> _write(List<FavoriteStation> favorites) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode([for (final favorite in favorites) _toJson(favorite)]),
    );
  }

  FavoriteStation _fromJson(Map<String, dynamic> row) => FavoriteStation(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    stationId: row['station_id']! as String,
    routeId: row['route_id']! as String,
    label: row['label']! as String,
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  Map<String, dynamic> _toJson(FavoriteStation favorite) => {
    'id': favorite.id,
    'user_id': favorite.userId,
    'station_id': favorite.stationId,
    'route_id': favorite.routeId,
    'label': favorite.label,
    'updated_at': favorite.updatedAt.toUtc().toIso8601String(),
  };
}

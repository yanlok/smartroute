import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/profile_repository_exception.dart';
import '../../domain/models/user_preferences.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository({required SupabaseClient client})
    : _client = client;

  @override
  Future<UserProfile> getProfile({required String userId}) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw const ProfileRepositoryException('User ID is required.');
    }

    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, photo_url')
          .eq('id', trimmedUserId)
          .maybeSingle();

      return _mapProfile(
        response,
        trimmedUserId,
        failureMessage: 'Unable to load your profile. Please try again.',
      );
    } on ProfileRepositoryException {
      rethrow;
    } catch (_) {
      throw const ProfileRepositoryException(
        'Unable to load your profile. Please try again.',
      );
    }
  }

  @override
  Future<UserPreferences> getPreferences({required String userId}) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw const ProfileRepositoryException('User ID is required.');
    }

    try {
      final response = await _client
          .from('user_preferences')
          .select('user_id, notifications_enabled, location_enabled, language')
          .eq('user_id', trimmedUserId)
          .maybeSingle();

      return _mapPreferences(
        response,
        expectedUserId: trimmedUserId,
        failureMessage: 'Unable to load your preferences. Please try again.',
      );
    } on ProfileRepositoryException {
      rethrow;
    } catch (_) {
      throw const ProfileRepositoryException(
        'Unable to load your preferences. Please try again.',
      );
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    String? photoUrl,
  }) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw const ProfileRepositoryException('User ID is required.');
    }

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw const ProfileRepositoryException('Full name is required.');
    }

    final rawPhoto = photoUrl?.trim();
    final normalizedPhoto = (rawPhoto == null || rawPhoto.isEmpty)
        ? null
        : rawPhoto;

    try {
      final response = await _client
          .from('profiles')
          .update({
            'full_name': trimmedName,
            'photo_url': normalizedPhoto,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', trimmedUserId)
          .select('id, full_name, photo_url')
          .maybeSingle();

      return _mapProfile(
        response,
        trimmedUserId,
        failureMessage: 'Unable to update your profile. Please try again.',
      );
    } on ProfileRepositoryException {
      rethrow;
    } catch (_) {
      throw const ProfileRepositoryException(
        'Unable to update your profile. Please try again.',
      );
    }
  }

  @override
  Future<UserPreferences> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw const ProfileRepositoryException('User ID is required.');
    }

    if (preferences.language != 'en' && preferences.language != 'ms') {
      throw const ProfileRepositoryException(
        'Language must be English (en) or Bahasa Melayu (ms).',
      );
    }

    try {
      final response = await _client
          .from('user_preferences')
          .update({
            'notifications_enabled': preferences.notificationsEnabled,
            'location_enabled': preferences.locationEnabled,
            'language': preferences.language,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', trimmedUserId)
          .select('user_id, notifications_enabled, location_enabled, language')
          .maybeSingle();

      return _mapPreferences(
        response,
        expectedUserId: trimmedUserId,
        failureMessage: 'Unable to update your preferences. Please try again.',
      );
    } on ProfileRepositoryException {
      rethrow;
    } catch (_) {
      throw const ProfileRepositoryException(
        'Unable to update your preferences. Please try again.',
      );
    }
  }

  UserProfile _mapProfile(
    Map<String, dynamic>? data,
    String expectedUserId, {
    required String failureMessage,
  }) {
    if (data == null) {
      throw ProfileRepositoryException(failureMessage);
    }

    final id = (data['id'] as String?)?.trim();
    if (id == null || id.isEmpty || id != expectedUserId) {
      throw ProfileRepositoryException(failureMessage);
    }

    final rawName = (data['full_name'] as String?)?.trim();
    if (rawName == null || rawName.isEmpty) {
      throw ProfileRepositoryException(failureMessage);
    }

    final rawPhoto = (data['photo_url'] as String?)?.trim();
    final photoUrl = (rawPhoto == null || rawPhoto.isEmpty) ? null : rawPhoto;

    return UserProfile(id: id, fullName: rawName, photoUrl: photoUrl);
  }

  UserPreferences _mapPreferences(
    Map<String, dynamic>? data, {
    String? expectedUserId,
    required String failureMessage,
  }) {
    if (data == null) {
      throw ProfileRepositoryException(failureMessage);
    }

    if (expectedUserId != null && data.containsKey('user_id')) {
      final userId = (data['user_id'] as String?)?.trim();
      if (userId == null || userId.isEmpty || userId != expectedUserId) {
        throw ProfileRepositoryException(failureMessage);
      }
    }

    final rawNotifications = data['notifications_enabled'];
    if (rawNotifications is! bool) {
      throw ProfileRepositoryException(failureMessage);
    }

    final rawLocation = data['location_enabled'];
    if (rawLocation is! bool) {
      throw ProfileRepositoryException(failureMessage);
    }

    final rawLanguage = data['language'];
    if (rawLanguage is! String) {
      throw ProfileRepositoryException(failureMessage);
    }

    final trimmedLanguage = rawLanguage.trim();
    if (trimmedLanguage != 'en' && trimmedLanguage != 'ms') {
      throw ProfileRepositoryException(failureMessage);
    }

    return UserPreferences(
      notificationsEnabled: rawNotifications,
      locationEnabled: rawLocation,
      language: trimmedLanguage,
    );
  }
}

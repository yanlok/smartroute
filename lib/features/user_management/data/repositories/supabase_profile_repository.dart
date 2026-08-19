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

      if (response == null) {
        throw const ProfileRepositoryException(
          'Unable to load your profile. Please try again.',
        );
      }

      final rawName = (response['full_name'] as String?)?.trim();
      if (rawName == null || rawName.isEmpty) {
        throw const ProfileRepositoryException(
          'Unable to load your profile. Please try again.',
        );
      }

      final rawPhoto = (response['photo_url'] as String?)?.trim();
      final photoUrl = (rawPhoto == null || rawPhoto.isEmpty) ? null : rawPhoto;

      return UserProfile(
        id: trimmedUserId,
        fullName: rawName,
        photoUrl: photoUrl,
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
          .select('notifications_enabled, location_enabled, language')
          .eq('user_id', trimmedUserId)
          .maybeSingle();

      if (response == null) {
        throw const ProfileRepositoryException(
          'Unable to load your preferences. Please try again.',
        );
      }

      final notifications = response['notifications_enabled'] as bool? ?? true;
      final location = response['location_enabled'] as bool? ?? true;
      final rawLanguage = (response['language'] as String?)?.trim();

      if (rawLanguage != 'en' && rawLanguage != 'ms') {
        throw const ProfileRepositoryException(
          'Unable to load your preferences. Please try again.',
        );
      }

      return UserPreferences(
        notificationsEnabled: notifications,
        locationEnabled: location,
        language: rawLanguage!,
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
      await _client
          .from('profiles')
          .update({
            'full_name': trimmedName,
            'photo_url': normalizedPhoto,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', trimmedUserId);

      return UserProfile(
        id: trimmedUserId,
        fullName: trimmedName,
        photoUrl: normalizedPhoto,
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
      await _client
          .from('user_preferences')
          .update({
            'notifications_enabled': preferences.notificationsEnabled,
            'location_enabled': preferences.locationEnabled,
            'language': preferences.language,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', trimmedUserId);

      return preferences;
    } on ProfileRepositoryException {
      rethrow;
    } catch (_) {
      throw const ProfileRepositoryException(
        'Unable to update your preferences. Please try again.',
      );
    }
  }
}

import 'package:flutter/foundation.dart';

import '../domain/exceptions/profile_repository_exception.dart';
import '../domain/models/user_preferences.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  UserProfile? _profile;
  UserPreferences? _preferences;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isLoaded = false;

  ProfileController({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  UserProfile? get profile => _profile;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isLoaded => _isLoaded;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> load({required String userId}) async {
    if (_isLoading) return false;

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final prof = await _profileRepository.getProfile(userId: userId);
      final prefs = await _profileRepository.getPreferences(userId: userId);
      _profile = prof;
      _preferences = prefs;
      _isLoaded = true;
      return true;
    } catch (e) {
      _isLoaded = false;
      _errorMessage = _cleanErrorMessage(
        e,
        fallback: 'Unable to load profile. Please try again.',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String userId,
    required String fullName,
    String? photoUrl,
  }) async {
    if (_isSaving || _isLoading) return false;

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Full name is required';
      notifyListeners();
      return false;
    }

    if (trimmedName.length < 2) {
      _errorMessage = 'Full name must be at least 2 characters';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      final updated = await _profileRepository.updateProfile(
        userId: userId,
        fullName: trimmedName,
        photoUrl: photoUrl,
      );
      _profile = updated;
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(
        e,
        fallback: 'Unable to update your profile. Please try again.',
      );
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> setNotificationsEnabled({
    required String userId,
    required bool enabled,
  }) async {
    if (_isSaving || _isLoading) return false;

    final current = _preferences ?? const UserPreferences();
    final updated = current.copyWith(notificationsEnabled: enabled);
    return _savePreferences(userId: userId, preferences: updated);
  }

  Future<bool> setLocationEnabled({
    required String userId,
    required bool enabled,
  }) async {
    if (_isSaving || _isLoading) return false;

    final current = _preferences ?? const UserPreferences();
    final updated = current.copyWith(locationEnabled: enabled);
    return _savePreferences(userId: userId, preferences: updated);
  }

  Future<bool> setLanguage({
    required String userId,
    required String language,
  }) async {
    if (_isSaving || _isLoading) return false;

    if (language != 'en' && language != 'ms') {
      _errorMessage = 'Language must be English (en) or Bahasa Melayu (ms)';
      notifyListeners();
      return false;
    }

    final current = _preferences ?? const UserPreferences();
    final updated = current.copyWith(language: language);
    return _savePreferences(userId: userId, preferences: updated);
  }

  Future<bool> _savePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      final result = await _profileRepository.updatePreferences(
        userId: userId,
        preferences: preferences,
      );
      _preferences = result;
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(
        e,
        fallback: 'Unable to update your preferences. Please try again.',
      );
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object error, {required String fallback}) {
    if (error is ProfileRepositoryException) {
      return error.message;
    }
    return fallback;
  }
}

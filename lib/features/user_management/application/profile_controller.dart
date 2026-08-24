import 'package:flutter/foundation.dart';

import '../domain/exceptions/profile_repository_exception.dart';
import '../domain/models/user_preferences.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  int _generation = 0;
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

  void reset() {
    _generation++;
    _profile = null;
    _preferences = null;
    _errorMessage = null;
    _isLoaded = false;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  bool isLoadedFor(String userId) {
    return _isLoaded && _profile != null && _profile!.id == userId;
  }

  Future<bool> load({required String userId}) async {
    if (_isLoading) return false;

    final operationGeneration = _generation;
    _errorMessage = null;
    _isLoaded = false;
    _isLoading = true;
    notifyListeners();

    try {
      final prof = await _profileRepository.getProfile(userId: userId);
      if (operationGeneration != _generation) return false;

      final prefs = await _profileRepository.getPreferences(userId: userId);
      if (operationGeneration != _generation) return false;

      _profile = prof;
      _preferences = prefs;
      _isLoaded = true;
      return true;
    } catch (e) {
      if (operationGeneration != _generation) return false;
      _profile = null;
      _preferences = null;
      _isLoaded = false;
      _errorMessage = _cleanErrorMessage(
        e,
        fallback: 'Unable to load profile. Please try again.',
      );
      return false;
    } finally {
      if (operationGeneration == _generation) {
        _isLoading = false;
        notifyListeners();
      }
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

    final operationGeneration = _generation;
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      final updated = await _profileRepository.updateProfile(
        userId: userId,
        fullName: trimmedName,
        photoUrl: photoUrl,
      );
      if (operationGeneration != _generation) return false;
      _profile = updated;
      return true;
    } catch (e) {
      if (operationGeneration != _generation) return false;
      _errorMessage = _cleanErrorMessage(
        e,
        fallback: 'Unable to update your profile. Please try again.',
      );
      return false;
    } finally {
      if (operationGeneration == _generation) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> setNotificationsEnabled({
    required String userId,
    required bool enabled,
  }) async {
    if (_isSaving || _isLoading) return false;

    if (_preferences == null || !_isLoaded) {
      _errorMessage = 'Preferences are not loaded. Please try again.';
      notifyListeners();
      return false;
    }

    final updated = _preferences!.copyWith(notificationsEnabled: enabled);
    return _savePreferences(userId: userId, preferences: updated);
  }

  Future<bool> setLocationEnabled({
    required String userId,
    required bool enabled,
  }) async {
    if (_isSaving || _isLoading) return false;

    if (_preferences == null || !_isLoaded) {
      _errorMessage = 'Preferences are not loaded. Please try again.';
      notifyListeners();
      return false;
    }

    final updated = _preferences!.copyWith(locationEnabled: enabled);
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

    if (_preferences == null || !_isLoaded) {
      _errorMessage = 'Preferences are not loaded. Please try again.';
      notifyListeners();
      return false;
    }

    final updated = _preferences!.copyWith(language: language);
    return _savePreferences(userId: userId, preferences: updated);
  }

  Future<bool> _savePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    final operationGeneration = _generation;
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      final result = await _profileRepository.updatePreferences(
        userId: userId,
        preferences: preferences,
      );
      if (operationGeneration != _generation) return false;
      _preferences = result;
      return true;
    } catch (e) {
      if (operationGeneration != _generation) return false;
      _errorMessage = _cleanErrorMessage(
        e,
        fallback: 'Unable to update your preferences. Please try again.',
      );
      return false;
    } finally {
      if (operationGeneration == _generation) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  String _cleanErrorMessage(Object error, {required String fallback}) {
    if (error is ProfileRepositoryException) {
      return error.message;
    }
    return fallback;
  }
}

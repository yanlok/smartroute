import 'package:flutter/foundation.dart';

import '../domain/exceptions/profile_repository_exception.dart';
import '../domain/models/avatar_upload.dart';
import '../domain/models/user_preferences.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/avatar_storage_repository.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final AvatarStorageRepository? _avatarStorageRepository;

  int _generation = 0;
  UserProfile? _profile;
  UserPreferences? _preferences;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isAvatarSaving = false;
  String? _errorMessage;
  bool _isLoaded = false;

  ProfileController({
    required ProfileRepository profileRepository,
    AvatarStorageRepository? avatarStorageRepository,
  }) : _profileRepository = profileRepository,
       _avatarStorageRepository = avatarStorageRepository;

  UserProfile? get profile => _profile;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isAvatarSaving => _isAvatarSaving;
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
    _isAvatarSaving = false;
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

  Future<bool> uploadAvatar({
    required String userId,
    required AvatarUpload image,
  }) async {
    if (_isSaving || _isLoading) return false;
    final storage = _avatarStorageRepository;
    final profile = _profile;
    if (storage == null || profile == null || !_isLoaded) {
      _errorMessage = 'Profile photos are not available yet. Try again later.';
      notifyListeners();
      return false;
    }
    final normalized = _validatedAvatar(image);
    if (normalized == null) {
      notifyListeners();
      return false;
    }

    final operationGeneration = _generation;
    _errorMessage = null;
    _isSaving = true;
    _isAvatarSaving = true;
    notifyListeners();
    try {
      final photoUrl = await storage.uploadAvatar(
        userId: userId,
        image: normalized,
      );
      final updated = await _profileRepository.updateProfile(
        userId: userId,
        fullName: profile.fullName,
        photoUrl: photoUrl,
      );
      if (operationGeneration != _generation) return false;
      _profile = updated;
      return true;
    } catch (error) {
      if (operationGeneration != _generation) return false;
      _errorMessage = _cleanErrorMessage(
        error,
        fallback: 'Profile photo could not be uploaded. Try again.',
      );
      return false;
    } finally {
      if (operationGeneration == _generation) {
        _isSaving = false;
        _isAvatarSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> removeAvatar({required String userId}) async {
    if (_isSaving || _isLoading) return false;
    final storage = _avatarStorageRepository;
    final profile = _profile;
    if (storage == null || profile == null || !_isLoaded) {
      _errorMessage = 'Profile photos are not available yet. Try again later.';
      notifyListeners();
      return false;
    }
    if (profile.photoUrl == null || profile.photoUrl!.trim().isEmpty) {
      return true;
    }

    final operationGeneration = _generation;
    _errorMessage = null;
    _isSaving = true;
    _isAvatarSaving = true;
    notifyListeners();
    try {
      await storage.removeAvatar(userId: userId);
      final updated = await _profileRepository.updateProfile(
        userId: userId,
        fullName: profile.fullName,
        photoUrl: null,
      );
      if (operationGeneration != _generation) return false;
      _profile = updated;
      return true;
    } catch (error) {
      if (operationGeneration != _generation) return false;
      _errorMessage = _cleanErrorMessage(
        error,
        fallback: 'Profile photo could not be removed. Try again.',
      );
      return false;
    } finally {
      if (operationGeneration == _generation) {
        _isSaving = false;
        _isAvatarSaving = false;
        notifyListeners();
      }
    }
  }

  AvatarUpload? _validatedAvatar(AvatarUpload image) {
    const maxBytes = 5 * 1024 * 1024;
    if (image.bytes.isEmpty) {
      _errorMessage = 'Choose a valid profile image.';
      return null;
    }
    if (image.bytes.length > maxBytes) {
      _errorMessage = 'Profile image must be 5 MB or smaller.';
      return null;
    }
    final extension = image.fileName.split('.').last.toLowerCase();
    final mimeType = image.mimeType?.toLowerCase() ?? _mimeFor(extension);
    final validType = switch (extension) {
      'jpg' || 'jpeg' => mimeType == 'image/jpeg' && _isJpeg(image),
      'png' => mimeType == 'image/png' && _isPng(image),
      'webp' => mimeType == 'image/webp' && _isWebp(image),
      _ => false,
    };
    if (!validType) {
      _errorMessage = 'Choose a JPEG, PNG, or WebP image.';
      return null;
    }
    return AvatarUpload(
      bytes: image.bytes,
      fileName: 'avatar.$extension',
      mimeType: mimeType,
    );
  }

  String? _mimeFor(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => null,
  };

  bool _isJpeg(AvatarUpload image) =>
      image.bytes.length >= 3 &&
      image.bytes[0] == 0xff &&
      image.bytes[1] == 0xd8 &&
      image.bytes[2] == 0xff;

  bool _isPng(AvatarUpload image) =>
      image.bytes.length >= 8 &&
      image.bytes[0] == 0x89 &&
      image.bytes[1] == 0x50 &&
      image.bytes[2] == 0x4e &&
      image.bytes[3] == 0x47 &&
      image.bytes[4] == 0x0d &&
      image.bytes[5] == 0x0a &&
      image.bytes[6] == 0x1a &&
      image.bytes[7] == 0x0a;

  bool _isWebp(AvatarUpload image) =>
      image.bytes.length >= 12 &&
      image.bytes[0] == 0x52 &&
      image.bytes[1] == 0x49 &&
      image.bytes[2] == 0x46 &&
      image.bytes[3] == 0x46 &&
      image.bytes[8] == 0x57 &&
      image.bytes[9] == 0x45 &&
      image.bytes[10] == 0x42 &&
      image.bytes[11] == 0x50;

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

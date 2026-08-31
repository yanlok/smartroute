import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/user_management/application/profile_controller.dart';
import 'package:smartroute/features/user_management/domain/exceptions/profile_repository_exception.dart';
import 'package:smartroute/features/user_management/domain/models/user_preferences.dart';
import 'package:smartroute/features/user_management/domain/models/user_profile.dart';
import 'package:smartroute/features/user_management/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  UserProfile? mockProfile;
  UserPreferences? mockPreferences;
  bool shouldThrowError = false;
  String? errorMessage;

  Completer<UserProfile>? getProfileCompleter;
  Completer<UserPreferences>? getPreferencesCompleter;
  Completer<UserProfile>? updateProfileCompleter;
  Completer<UserPreferences>? updatePreferencesCompleter;

  int getProfileCallCount = 0;
  int getPreferencesCallCount = 0;
  int updateProfileCallCount = 0;
  int updatePreferencesCallCount = 0;

  @override
  Future<UserProfile> getProfile({required String userId}) async {
    getProfileCallCount++;
    if (shouldThrowError) {
      throw ProfileRepositoryException(
        errorMessage ?? 'Unable to load profile',
      );
    }
    if (getProfileCompleter != null) {
      return getProfileCompleter!.future;
    }
    return mockProfile ??
        UserProfile(
          id: userId,
          fullName: 'Test User',
          photoUrl: 'https://example.com/p.png',
        );
  }

  @override
  Future<UserPreferences> getPreferences({required String userId}) async {
    getPreferencesCallCount++;
    if (shouldThrowError) {
      throw ProfileRepositoryException(
        errorMessage ?? 'Unable to load preferences',
      );
    }
    if (getPreferencesCompleter != null) {
      return getPreferencesCompleter!.future;
    }
    return mockPreferences ?? const UserPreferences();
  }

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    String? photoUrl,
  }) async {
    updateProfileCallCount++;
    if (shouldThrowError) {
      throw ProfileRepositoryException(
        errorMessage ?? 'Unable to update profile',
      );
    }
    if (updateProfileCompleter != null) {
      return updateProfileCompleter!.future.then((result) {
        mockProfile = result;
        return result;
      });
    }
    final updated = UserProfile(
      id: userId,
      fullName: fullName,
      photoUrl: photoUrl,
    );
    mockProfile = updated;
    return updated;
  }

  @override
  Future<UserPreferences> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    updatePreferencesCallCount++;
    if (shouldThrowError) {
      throw ProfileRepositoryException(
        errorMessage ?? 'Unable to update preferences',
      );
    }
    if (updatePreferencesCompleter != null) {
      return updatePreferencesCompleter!.future.then((result) {
        mockPreferences = result;
        return result;
      });
    }
    mockPreferences = preferences;
    return preferences;
  }
}

void main() {
  group('ProfileController', () {
    late FakeProfileRepository repository;
    late ProfileController controller;

    setUp(() {
      repository = FakeProfileRepository();
      controller = ProfileController(profileRepository: repository);
    });

    test('initial state is unpopulated, not loading, and not saving', () {
      expect(controller.profile, isNull);
      expect(controller.preferences, isNull);
      expect(controller.isLoading, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.isLoaded, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test(
      'successful load fetches profile and preferences and sets isLoaded true',
      () async {
        const profile = UserProfile(
          id: 'u-1',
          fullName: 'Jane Doe',
          photoUrl: 'https://example.com/j.jpg',
        );
        const preferences = UserPreferences(
          notificationsEnabled: false,
          locationEnabled: true,
          language: 'ms',
        );

        repository.mockProfile = profile;
        repository.mockPreferences = preferences;

        final success = await controller.load(userId: 'u-1');

        expect(success, isTrue);
        expect(controller.profile, profile);
        expect(controller.preferences, preferences);
        expect(controller.isLoaded, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, isNull);
        expect(repository.getProfileCallCount, 1);
        expect(repository.getPreferencesCallCount, 1);
      },
    );

    test(
      'reset clears profile, preferences, errorMessage, and isLoaded',
      () async {
        repository.mockProfile = const UserProfile(id: 'u-1', fullName: 'Jane');
        repository.mockPreferences = const UserPreferences();
        await controller.load(userId: 'u-1');
        expect(controller.isLoaded, isTrue);

        controller.reset();

        expect(controller.profile, isNull);
        expect(controller.preferences, isNull);
        expect(controller.errorMessage, isNull);
        expect(controller.isLoaded, isFalse);
        expect(controller.isLoading, isFalse);
        expect(controller.isSaving, isFalse);
      },
    );

    test('isLoadedFor returns true only for matching loaded user ID', () async {
      expect(controller.isLoadedFor('u-1'), isFalse);

      repository.mockProfile = const UserProfile(id: 'u-1', fullName: 'Jane');
      repository.mockPreferences = const UserPreferences();
      await controller.load(userId: 'u-1');

      expect(controller.isLoadedFor('u-1'), isTrue);
      expect(controller.isLoadedFor('u-2'), isFalse);

      controller.reset();
      expect(controller.isLoadedFor('u-1'), isFalse);
    });

    test(
      'load failure sets error, isLoaded false, and resets loading',
      () async {
        repository.shouldThrowError = true;
        repository.errorMessage = 'Network connection failed';

        final success = await controller.load(userId: 'u-1');

        expect(success, isFalse);
        expect(controller.profile, isNull);
        expect(controller.preferences, isNull);
        expect(controller.isLoaded, isFalse);
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, 'Network connection failed');
      },
    );

    test('load prevents duplicate simultaneous calls', () async {
      repository.mockProfile = const UserProfile(id: 'u-1', fullName: 'Jane');
      repository.mockPreferences = const UserPreferences();

      final firstLoad = controller.load(userId: 'u-1');
      final secondLoad = controller.load(userId: 'u-1');

      final results = await Future.wait([firstLoad, secondLoad]);

      expect(results[0], isTrue);
      expect(results[1], isFalse);
      expect(repository.getProfileCallCount, 1);
    });

    test('failed second load clears previous user data completely', () async {
      repository.mockProfile = const UserProfile(
        id: 'user-a',
        fullName: 'User A',
      );
      repository.mockPreferences = const UserPreferences(language: 'ms');
      final userALoad = await controller.load(userId: 'user-a');
      expect(userALoad, isTrue);
      expect(controller.profile?.id, 'user-a');
      expect(controller.preferences?.language, 'ms');
      expect(controller.isLoaded, isTrue);

      repository.shouldThrowError = true;
      repository.errorMessage = 'Failed to load User B';

      final userBLoad = await controller.load(userId: 'user-b');

      expect(userBLoad, isFalse);
      expect(controller.profile, isNull);
      expect(controller.preferences, isNull);
      expect(controller.isLoaded, isFalse);
      expect(controller.errorMessage, 'Failed to load User B');
    });

    test(
      'preference mutations are rejected before preferences are loaded',
      () async {
        expect(controller.isLoaded, isFalse);

        final notifResult = await controller.setNotificationsEnabled(
          userId: 'u-1',
          enabled: false,
        );
        expect(notifResult, isFalse);
        expect(
          controller.errorMessage,
          'Preferences are not loaded. Please try again.',
        );
        expect(repository.updatePreferencesCallCount, 0);

        final locationResult = await controller.setLocationEnabled(
          userId: 'u-1',
          enabled: false,
        );
        expect(locationResult, isFalse);
        expect(
          controller.errorMessage,
          'Preferences are not loaded. Please try again.',
        );
        expect(repository.updatePreferencesCallCount, 0);

        final langResult = await controller.setLanguage(
          userId: 'u-1',
          language: 'ms',
        );
        expect(langResult, isFalse);
        expect(
          controller.errorMessage,
          'Preferences are not loaded. Please try again.',
        );
        expect(repository.updatePreferencesCallCount, 0);
      },
    );

    test('successful profile update replaces local profile state', () async {
      repository.mockProfile = const UserProfile(
        id: 'u-1',
        fullName: 'Initial Name',
      );
      await controller.load(userId: 'u-1');

      final success = await controller.updateProfile(
        userId: 'u-1',
        fullName: 'Updated Name',
        photoUrl: 'https://example.com/new.png',
      );

      expect(success, isTrue);
      expect(controller.profile?.fullName, 'Updated Name');
      expect(controller.profile?.photoUrl, 'https://example.com/new.png');
      expect(controller.isSaving, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test(
      'failed profile update preserves previous profile and exposes error',
      () async {
        const initialProfile = UserProfile(
          id: 'u-1',
          fullName: 'Initial Name',
          photoUrl: 'https://example.com/init.png',
        );
        repository.mockProfile = initialProfile;
        await controller.load(userId: 'u-1');

        repository.shouldThrowError = true;
        repository.errorMessage = 'Failed to save name';

        final success = await controller.updateProfile(
          userId: 'u-1',
          fullName: 'Should Fail',
        );

        expect(success, isFalse);
        expect(controller.profile, initialProfile);
        expect(controller.errorMessage, 'Failed to save name');
        expect(controller.isSaving, isFalse);
      },
    );

    test(
      'updateProfile validates fullName presence and length before repository call',
      () async {
        final emptyResult = await controller.updateProfile(
          userId: 'u-1',
          fullName: '   ',
        );
        expect(emptyResult, isFalse);
        expect(controller.errorMessage, 'Full name is required');
        expect(repository.updateProfileCallCount, 0);

        final shortResult = await controller.updateProfile(
          userId: 'u-1',
          fullName: 'A',
        );
        expect(shortResult, isFalse);
        expect(
          controller.errorMessage,
          'Full name must be at least 2 characters',
        );
        expect(repository.updateProfileCallCount, 0);
      },
    );

    test('notification preference update succeeds and updates state', () async {
      await controller.load(userId: 'u-1');
      expect(controller.preferences?.notificationsEnabled, isTrue);

      final success = await controller.setNotificationsEnabled(
        userId: 'u-1',
        enabled: false,
      );

      expect(success, isTrue);
      expect(controller.preferences?.notificationsEnabled, isFalse);
      expect(repository.updatePreferencesCallCount, 1);
    });

    test(
      'notification update failure preserves previous state and exposes error',
      () async {
        await controller.load(userId: 'u-1');
        expect(controller.preferences?.notificationsEnabled, isTrue);

        repository.shouldThrowError = true;
        repository.errorMessage = 'Database unavailable';

        final success = await controller.setNotificationsEnabled(
          userId: 'u-1',
          enabled: false,
        );

        expect(success, isFalse);
        expect(controller.preferences?.notificationsEnabled, isTrue);
        expect(controller.errorMessage, 'Database unavailable');
      },
    );

    test('location preference update succeeds and updates state', () async {
      await controller.load(userId: 'u-1');

      final success = await controller.setLocationEnabled(
        userId: 'u-1',
        enabled: false,
      );

      expect(success, isTrue);
      expect(controller.preferences?.locationEnabled, isFalse);
    });

    test('language update succeeds for valid languages en and ms', () async {
      await controller.load(userId: 'u-1');

      final successMs = await controller.setLanguage(
        userId: 'u-1',
        language: 'ms',
      );
      expect(successMs, isTrue);
      expect(controller.preferences?.language, 'ms');

      final successEn = await controller.setLanguage(
        userId: 'u-1',
        language: 'en',
      );
      expect(successEn, isTrue);
      expect(controller.preferences?.language, 'en');
    });

    test('invalid language is rejected before repository call', () async {
      await controller.load(userId: 'u-1');

      final success = await controller.setLanguage(
        userId: 'u-1',
        language: 'de',
      );

      expect(success, isFalse);
      expect(
        controller.errorMessage,
        'Language must be English (en) or Bahasa Melayu (ms)',
      );
      expect(repository.updatePreferencesCallCount, 0);
    });

    test(
      'prevents duplicate save operations while a save is pending',
      () async {
        await controller.load(userId: 'u-1');

        final completer = Completer<UserPreferences>();
        repository.updatePreferencesCompleter = completer;

        final firstSaveFuture = controller.setNotificationsEnabled(
          userId: 'u-1',
          enabled: false,
        );

        expect(controller.isSaving, isTrue);

        final secondSaveResult = await controller.setLocationEnabled(
          userId: 'u-1',
          enabled: false,
        );

        expect(secondSaveResult, isFalse);
        expect(repository.updatePreferencesCallCount, 1);

        const updatedPrefs = UserPreferences(notificationsEnabled: false);
        completer.complete(updatedPrefs);

        final firstSaveResult = await firstSaveFuture;
        expect(firstSaveResult, isTrue);
        expect(controller.isSaving, isFalse);
        expect(controller.preferences, updatedPrefs);
        expect(repository.updatePreferencesCallCount, 1);
      },
    );

    test(
      'pending load completed after reset does not restore old User A data and controller remains reset',
      () async {
        final profileCompleter = Completer<UserProfile>();
        final prefsCompleter = Completer<UserPreferences>();
        repository.getProfileCompleter = profileCompleter;
        repository.getPreferencesCompleter = prefsCompleter;

        final loadFuture = controller.load(userId: 'user-a');

        expect(controller.isLoading, isTrue);

        controller.reset();

        expect(controller.profile, isNull);
        expect(controller.preferences, isNull);
        expect(controller.isLoaded, isFalse);
        expect(controller.isLoading, isFalse);
        expect(controller.isSaving, isFalse);
        expect(controller.errorMessage, isNull);

        profileCompleter.complete(
          const UserProfile(id: 'user-a', fullName: 'User A'),
        );
        prefsCompleter.complete(const UserPreferences(language: 'ms'));

        final result = await loadFuture;

        expect(result, isFalse);
        expect(controller.profile, isNull);
        expect(controller.preferences, isNull);
        expect(controller.isLoaded, isFalse);
        expect(controller.isLoading, isFalse);
        expect(controller.isSaving, isFalse);
      },
    );

    test(
      'old User A load completion does not override subsequently loaded User B data',
      () async {
        final userAProfileCompleter = Completer<UserProfile>();
        final userAPrefsCompleter = Completer<UserPreferences>();
        repository.getProfileCompleter = userAProfileCompleter;
        repository.getPreferencesCompleter = userAPrefsCompleter;

        final userAFuture = controller.load(userId: 'user-a');
        expect(controller.isLoading, isTrue);

        controller.reset();

        repository.getProfileCompleter = null;
        repository.getPreferencesCompleter = null;
        repository.mockProfile = const UserProfile(
          id: 'user-b',
          fullName: 'User B',
        );
        repository.mockPreferences = const UserPreferences(language: 'en');

        final userBSuccess = await controller.load(userId: 'user-b');
        expect(userBSuccess, isTrue);
        expect(controller.profile?.id, 'user-b');
        expect(controller.profile?.fullName, 'User B');

        userAProfileCompleter.complete(
          const UserProfile(id: 'user-a', fullName: 'User A'),
        );
        userAPrefsCompleter.complete(const UserPreferences(language: 'ms'));

        final userAResult = await userAFuture;
        expect(userAResult, isFalse);

        expect(controller.profile?.id, 'user-b');
        expect(controller.profile?.fullName, 'User B');
        expect(controller.preferences?.language, 'en');
        expect(controller.isLoaded, isTrue);
      },
    );

    test(
      'pending save completed after reset does not republish old profile or error',
      () async {
        await controller.load(userId: 'u-1');
        expect(controller.isLoaded, isTrue);

        final updateCompleter = Completer<UserProfile>();
        repository.updateProfileCompleter = updateCompleter;

        final saveFuture = controller.updateProfile(
          userId: 'u-1',
          fullName: 'New Name',
        );
        expect(controller.isSaving, isTrue);

        controller.reset();

        expect(controller.profile, isNull);
        expect(controller.preferences, isNull);
        expect(controller.isSaving, isFalse);
        expect(controller.isLoaded, isFalse);

        updateCompleter.complete(
          const UserProfile(id: 'u-1', fullName: 'New Name'),
        );
        final saveResult = await saveFuture;

        expect(saveResult, isFalse);
        expect(controller.profile, isNull);
        expect(controller.isSaving, isFalse);
      },
    );
  });
}

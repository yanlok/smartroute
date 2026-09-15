import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/profile/screens/profile_screen.dart';
import 'package:smartroute/features/user_management/application/auth_controller.dart';
import 'package:smartroute/features/user_management/application/profile_controller.dart';
import 'package:smartroute/features/user_management/application/saved_journey_controller.dart';
import 'package:smartroute/features/user_management/domain/models/avatar_upload.dart';
import 'package:smartroute/features/user_management/domain/exceptions/profile_repository_exception.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/registration_result.dart';
import 'package:smartroute/features/user_management/domain/models/saved_journey.dart';
import 'package:smartroute/features/user_management/domain/models/user_preferences.dart';
import 'package:smartroute/features/user_management/domain/models/user_profile.dart';
import 'package:smartroute/features/user_management/domain/repositories/auth_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/avatar_storage_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/profile_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/saved_journey_repository.dart';
import 'package:smartroute/shared/models/journey_models.dart';

class FakeProfileRepository implements ProfileRepository {
  UserProfile? mockProfile;
  UserPreferences? mockPreferences;
  bool shouldThrowOnLoad = false;
  bool shouldThrowOnUpdate = false;
  String? loadErrorMessage;
  String? updateErrorMessage;

  Completer<UserProfile>? loadProfileCompleter;
  Completer<UserPreferences>? loadPreferencesCompleter;
  Completer<UserProfile>? updateProfileCompleter;

  int getProfileCallCount = 0;
  int getPreferencesCallCount = 0;
  int updateProfileCallCount = 0;
  int updatePreferencesCallCount = 0;

  String? lastUpdateProfileUserId;
  String? lastUpdateProfileFullName;
  String? lastUpdatePreferencesUserId;
  UserPreferences? lastUpdatePreferencesPayload;

  @override
  Future<UserProfile> getProfile({required String userId}) async {
    getProfileCallCount++;
    if (shouldThrowOnLoad) {
      throw ProfileRepositoryException(
        loadErrorMessage ?? 'Unable to load your profile. Please try again.',
      );
    }
    if (loadProfileCompleter != null) {
      return loadProfileCompleter!.future;
    }
    return mockProfile ??
        UserProfile(
          id: userId,
          fullName: 'Test User',
          photoUrl: 'https://example.com/photo.png',
        );
  }

  @override
  Future<UserPreferences> getPreferences({required String userId}) async {
    getPreferencesCallCount++;
    if (shouldThrowOnLoad) {
      throw ProfileRepositoryException(
        loadErrorMessage ??
            'Unable to load your preferences. Please try again.',
      );
    }
    if (loadPreferencesCompleter != null) {
      return loadPreferencesCompleter!.future;
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
    lastUpdateProfileUserId = userId;
    lastUpdateProfileFullName = fullName;

    if (shouldThrowOnUpdate) {
      throw ProfileRepositoryException(
        updateErrorMessage ??
            'Unable to update your profile. Please try again.',
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
    lastUpdatePreferencesUserId = userId;
    lastUpdatePreferencesPayload = preferences;

    if (shouldThrowOnUpdate) {
      throw ProfileRepositoryException(
        updateErrorMessage ??
            'Unable to update your preferences. Please try again.',
      );
    }

    mockPreferences = preferences;
    return preferences;
  }
}

class FakeAvatarStorageRepository implements AvatarStorageRepository {
  String uploadedUrl = 'https://example.com/new-avatar.png';
  Object? uploadError;
  Object? removeError;
  int uploadCalls = 0;
  int removeCalls = 0;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required AvatarUpload image,
  }) async {
    uploadCalls++;
    if (uploadError != null) throw uploadError!;
    return uploadedUrl;
  }

  @override
  Future<void> removeAvatar({required String userId}) async {
    removeCalls++;
    if (removeError != null) throw removeError!;
  }
}

class FakeAuthRepository implements AuthRepository {
  Object? changePasswordError;
  int changePasswordCalls = 0;

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    if (changePasswordError != null) throw changePasswordError!;
  }

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> resetPassword({required String newPassword}) async {}

  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class FakeSavedJourneyRepository implements SavedJourneyRepository {
  final List<FavoriteJourney> favorites = [];

  @override
  Future<void> deleteFavorite(String favoriteId) async {
    favorites.removeWhere((item) => item.id == favoriteId);
  }

  @override
  Future<void> deleteFavoriteStation(String favoriteId) async {}

  @override
  Future<List<FavoriteJourney>> getFavorites(String userId) async => favorites;

  @override
  Future<List<FavoriteStation>> getFavoriteStations(String userId) async => [];

  @override
  Future<List<RecentJourney>> getRecentSearches(String userId) async =>
      const [];

  @override
  Future<RecentJourney> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  }) => throw UnimplementedError();

  @override
  Future<FavoriteJourney> saveFavorite({
    required String userId,
    required String label,
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
  }) => throw UnimplementedError();

  @override
  Future<FavoriteStation> saveFavoriteStation({
    required String userId,
    required String stationId,
    required String routeId,
    required String label,
  }) => throw UnimplementedError();
}

void main() {
  const testUser = AppUser(
    id: 'user-123',
    fullName: 'Test User',
    email: 'real.user@example.com',
  );

  late FakeProfileRepository fakeRepo;
  late FakeAvatarStorageRepository fakeAvatarRepo;
  late FakeAuthRepository fakeAuthRepo;
  late ProfileController profileController;
  late AuthController authController;
  late SavedJourneyController savedJourneyController;
  late bool logoutCalled;
  late bool savedJourneysCalled;

  setUp(() {
    fakeRepo = FakeProfileRepository();
    fakeAvatarRepo = FakeAvatarStorageRepository();
    fakeAuthRepo = FakeAuthRepository();
    profileController = ProfileController(
      profileRepository: fakeRepo,
      avatarStorageRepository: fakeAvatarRepo,
    );
    authController = AuthController(authRepository: fakeAuthRepo);
    savedJourneyController = SavedJourneyController(
      repository: FakeSavedJourneyRepository(),
    );
    logoutCalled = false;
    savedJourneysCalled = false;
  });

  Widget buildTestWidget({
    AppUser authUser = testUser,
    ProfileController? controller,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ProfileScreen(
          authUser: authUser,
          authController: authController,
          profileController: controller ?? profileController,
          savedJourneys: savedJourneyController,
          onBack: () {},
          onLogout: () {
            logoutCalled = true;
          },
          onSavedJourneys: () {
            savedJourneysCalled = true;
          },
          pickAvatar: () async => AvatarUpload(
            bytes: Uint8List.fromList(const [
              0x89,
              0x50,
              0x4E,
              0x47,
              0x0D,
              0x0A,
              0x1A,
              0x0A,
            ]),
            fileName: 'avatar.png',
            mimeType: 'image/png',
          ),
        ),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('1. initial loading does not show hardcoded identity', (
      tester,
    ) async {
      fakeRepo.loadProfileCompleter = Completer<UserProfile>();
      fakeRepo.loadPreferencesCompleter = Completer<UserPreferences>();

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(
        find.byKey(const Key('profile_loading_indicator')),
        findsOneWidget,
      );

      expect(find.text('Yih Loong'), findsNothing);
      expect(find.text('yih.loong@gmail.com'), findsNothing);
    });

    testWidgets('2. successful load displays real identity and preferences', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Lee Jia Che',
        photoUrl: null,
      );
      fakeRepo.mockPreferences = const UserPreferences(
        notificationsEnabled: false,
        locationEnabled: true,
        language: 'ms',
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lee Jia Che'), findsOneWidget);
      expect(find.text('real.user@example.com'), findsOneWidget);

      expect(find.text('LJ'), findsOneWidget);

      expect(find.text('In-app notifications'), findsOneWidget);
      expect(find.text('Location Services'), findsOneWidget);

      expect(find.text('Yih Loong'), findsNothing);
      expect(find.text('yih.loong@gmail.com'), findsNothing);
    });

    testWidgets('2b. saved photo renders with a safe initials fallback', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Lee Jia Che',
        photoUrl: 'https://example.com/photo.png',
      );
      fakeRepo.mockPreferences = const UserPreferences();

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);
      expect(find.byKey(const Key('profile_avatar_initials')), findsOneWidget);
    });

    testWidgets(
      '3. load failure shows safe error, retry button, and no fake profile',
      (tester) async {
        fakeRepo.shouldThrowOnLoad = true;
        fakeRepo.loadErrorMessage = 'Network connection timed out.';

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Network connection timed out.'), findsOneWidget);
        expect(find.byKey(const Key('profile_retry_button')), findsOneWidget);
        expect(find.text('Yih Loong'), findsNothing);
        expect(find.text('Lee Jia Che'), findsNothing);

        fakeRepo.shouldThrowOnLoad = false;
        fakeRepo.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Recovered User',
        );
        fakeRepo.mockPreferences = const UserPreferences();

        await tester.tap(find.byKey(const Key('profile_retry_button')));
        await tester.pumpAndSettle();

        expect(find.text('Recovered User'), findsOneWidget);
        expect(find.byKey(const Key('profile_retry_button')), findsNothing);
      },
    );

    testWidgets('4. notifications toggle persists through repository', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Alice Smith',
      );
      fakeRepo.mockPreferences = const UserPreferences(
        notificationsEnabled: true,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(profileController.preferences?.notificationsEnabled, isTrue);

      await tester.tap(find.byKey(const Key('notifications_toggle')));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatePreferencesCallCount, 1);
      expect(fakeRepo.lastUpdatePreferencesUserId, 'user-123');
      expect(
        fakeRepo.lastUpdatePreferencesPayload?.notificationsEnabled,
        isFalse,
      );
      expect(profileController.preferences?.notificationsEnabled, isFalse);
    });

    testWidgets('5. failed notifications update preserves confirmed UI state', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Alice Smith',
      );
      fakeRepo.mockPreferences = const UserPreferences(
        notificationsEnabled: true,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      fakeRepo.shouldThrowOnUpdate = true;
      fakeRepo.updateErrorMessage = 'Database update failed';

      await tester.tap(find.byKey(const Key('notifications_toggle')));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatePreferencesCallCount, 1);

      expect(profileController.preferences?.notificationsEnabled, isTrue);

      expect(find.text('Database update failed'), findsOneWidget);
    });

    testWidgets('6. location toggle persists through repository', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Bob Johnson',
      );
      fakeRepo.mockPreferences = const UserPreferences(locationEnabled: true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('location_toggle')));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatePreferencesCallCount, 1);
      expect(fakeRepo.lastUpdatePreferencesPayload?.locationEnabled, isFalse);
      expect(profileController.preferences?.locationEnabled, isFalse);
    });

    testWidgets('7. language preference is visible and persists selection', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Charlie Tan',
      );
      fakeRepo.mockPreferences = const UserPreferences(language: 'en');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('language_row')), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.byKey(const Key('language_row')));
      await tester.pumpAndSettle();

      expect(find.text('Bahasa Melayu'), findsOneWidget);
      expect(
        find.text(
          'This saves your preference. Full app translation is not available yet.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('language_malay')));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatePreferencesCallCount, 1);
      expect(fakeRepo.lastUpdatePreferencesPayload?.language, 'ms');
      expect(find.text('Bahasa Melayu'), findsOneWidget);
    });

    testWidgets(
      '8 & 9. full-name edit sends correct data and updates confirmed result',
      (tester) async {
        fakeRepo.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Original Name',
        );
        fakeRepo.mockPreferences = const UserPreferences();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Original Name'), findsOneWidget);

        await tester.tap(find.byKey(const Key('profile_edit_name_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit_name_textfield')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('edit_name_textfield')),
          'Updated Full Name',
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pumpAndSettle();

        expect(fakeRepo.updateProfileCallCount, 1);
        expect(fakeRepo.lastUpdateProfileUserId, 'user-123');
        expect(fakeRepo.lastUpdateProfileFullName, 'Updated Full Name');

        expect(find.text('Updated Full Name'), findsOneWidget);
        expect(find.text('Original Name'), findsNothing);
      },
    );

    testWidgets(
      '8b. edit dialog duplicate submission prevention with pending Future',
      (tester) async {
        fakeRepo.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Original Name',
        );
        fakeRepo.mockPreferences = const UserPreferences();

        final completer = Completer<UserProfile>();
        fakeRepo.updateProfileCompleter = completer;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_edit_name_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('edit_name_textfield')),
          'Confirmed Name',
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pump();

        expect(fakeRepo.updateProfileCallCount, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pump();

        expect(fakeRepo.updateProfileCallCount, 1);

        completer.complete(
          const UserProfile(id: 'user-123', fullName: 'Confirmed Name'),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit_name_textfield')), findsNothing);
        expect(find.text('Confirmed Name'), findsOneWidget);
      },
    );

    testWidgets(
      '8c. edit dialog error keeps dialog open, shows safe error, and allows retry',
      (tester) async {
        fakeRepo.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Original Name',
        );
        fakeRepo.mockPreferences = const UserPreferences();
        fakeRepo.shouldThrowOnUpdate = true;
        fakeRepo.updateErrorMessage = 'Unable to save profile changes.';

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_edit_name_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('edit_name_textfield')),
          'New Name',
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit_name_textfield')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Unable to save profile changes.'),
          ),
          findsOneWidget,
        );

        fakeRepo.shouldThrowOnUpdate = false;
        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit_name_textfield')), findsNothing);
        expect(find.text('New Name'), findsOneWidget);
      },
    );

    testWidgets('10. logout button invokes provided onLogout callback', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'David Lee',
      );
      fakeRepo.mockPreferences = const UserPreferences();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(logoutCalled, isFalse);

      await tester.ensureVisible(
        find.byKey(const Key('profile_signout_button')),
      );
      await tester.tap(find.byKey(const Key('profile_signout_button')));
      await tester.pump();

      expect(logoutCalled, isTrue);
    });

    testWidgets(
      '11. unsupported fake personal sections are completely absent',
      (tester) async {
        fakeRepo.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Jane Doe',
        );
        fakeRepo.mockPreferences = const UserPreferences();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('SmartRoute Premium'), findsNothing);
        expect(find.text('TRAVEL STATS'), findsNothing);
        expect(find.text('247'), findsNothing);
        expect(find.text('1,240km'), findsNothing);
        expect(find.text('89kg'), findsNothing);
        expect(find.text('PAYMENT METHODS'), findsNothing);
        expect(find.text('MyRapid Card'), findsNothing);
        expect(find.text("Touch 'n Go eWallet"), findsNothing);
      },
    );

    testWidgets('12. profile role and saved journeys entry are connected', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Jane Doe',
      );
      fakeRepo.mockPreferences = const UserPreferences();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('profile_role_display')),
          matching: find.text('Passenger'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('saved_journeys_row')), findsOneWidget);

      await tester.tap(find.byKey(const Key('saved_journeys_row')));
      expect(savedJourneysCalled, isTrue);
    });

    testWidgets(
      '13. selecting a valid avatar uploads and updates the profile',
      (tester) async {
        fakeRepo.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Jane Doe',
        );
        fakeRepo.mockPreferences = const UserPreferences();

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_avatar_edit_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('choose_avatar_action')));
        await tester.pump();

        expect(fakeAvatarRepo.uploadCalls, 1);
        expect(profileController.profile?.photoUrl, fakeAvatarRepo.uploadedUrl);
        expect(find.text('Profile photo updated.'), findsOneWidget);
      },
    );

    testWidgets('14. profile photo can be removed and falls back to initials', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Jane Doe',
        photoUrl: 'https://example.com/avatar.png',
      );
      fakeRepo.mockPreferences = const UserPreferences();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_avatar_edit_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('remove_avatar_action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_remove_avatar')));
      await tester.pumpAndSettle();

      expect(fakeAvatarRepo.removeCalls, 1);
      expect(profileController.profile?.photoUrl, isNull);
      expect(find.byKey(const Key('profile_avatar_initials')), findsOneWidget);
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('15. change password dialog validates and submits passwords', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Jane Doe',
      );
      fakeRepo.mockPreferences = const UserPreferences();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('change_password_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_password_button')));
      await tester.pump();

      expect(find.text('All password fields are required.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('current_password_field')),
        'OldPassword1',
      );
      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'NewPassword1',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'NewPassword1',
      );
      await tester.tap(find.byKey(const Key('save_password_button')));
      await tester.pumpAndSettle();

      expect(fakeAuthRepo.changePasswordCalls, 1);
      expect(find.text('Password changed successfully.'), findsOneWidget);
    });
  });
}

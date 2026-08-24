import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/profile/screens/profile_screen.dart';
import 'package:smartroute/features/user_management/application/profile_controller.dart';
import 'package:smartroute/features/user_management/domain/exceptions/profile_repository_exception.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/user_preferences.dart';
import 'package:smartroute/features/user_management/domain/models/user_profile.dart';
import 'package:smartroute/features/user_management/domain/repositories/profile_repository.dart';

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

void main() {
  const testUser = AppUser(
    id: 'user-123',
    fullName: 'Test User',
    email: 'real.user@example.com',
  );

  late FakeProfileRepository fakeRepo;
  late ProfileController profileController;
  late bool logoutCalled;

  setUp(() {
    fakeRepo = FakeProfileRepository();
    profileController = ProfileController(profileRepository: fakeRepo);
    logoutCalled = false;
  });

  Widget buildTestWidget({
    AppUser authUser = testUser,
    ProfileController? controller,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ProfileScreen(
          authUser: authUser,
          profileController: controller ?? profileController,
          onBack: () {},
          onLogout: () {
            logoutCalled = true;
          },
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

      // Loading indicator should be shown
      expect(
        find.byKey(const Key('profile_loading_indicator')),
        findsOneWidget,
      );

      // Hardcoded fake identity must NOT be displayed
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

      // Real full name and auth email
      expect(find.text('Lee Jia Che'), findsOneWidget);
      expect(find.text('real.user@example.com'), findsOneWidget);

      // Initials derived from real name
      expect(find.text('LJ'), findsOneWidget);

      // Actual preferences
      expect(find.text('Bahasa Melayu'), findsOneWidget);

      // Hardcoded fake identity absent
      expect(find.text('Yih Loong'), findsNothing);
      expect(find.text('yih.loong@gmail.com'), findsNothing);
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

        // Now fix network and tap Retry
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

      // Tap toggle
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

      // Tap toggle
      await tester.tap(find.byKey(const Key('notifications_toggle')));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatePreferencesCallCount, 1);
      // Preserves original true
      expect(profileController.preferences?.notificationsEnabled, isTrue);
      // Displays safe error banner
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

      // Tap location toggle
      await tester.tap(find.byKey(const Key('location_toggle')));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatePreferencesCallCount, 1);
      expect(fakeRepo.lastUpdatePreferencesPayload?.locationEnabled, isFalse);
      expect(profileController.preferences?.locationEnabled, isFalse);
    });

    testWidgets('7. language changes en -> ms through controller', (
      tester,
    ) async {
      fakeRepo.mockProfile = const UserProfile(
        id: 'user-123',
        fullName: 'Charlie Tan',
      );
      fakeRepo.mockPreferences = const UserPreferences(language: 'en');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('English (Malaysia)'), findsOneWidget);

      // Open language sheet
      await tester.tap(find.byKey(const Key('language_row')));
      await tester.pumpAndSettle();

      // Select Bahasa Melayu
      expect(find.byKey(const Key('language_option_ms')), findsOneWidget);
      await tester.tap(find.byKey(const Key('language_option_ms')));
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

        // Tap edit button
        await tester.tap(find.byKey(const Key('profile_edit_name_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit_name_textfield')), findsOneWidget);

        // Enter new name
        await tester.enterText(
          find.byKey(const Key('edit_name_textfield')),
          'Updated Full Name',
        );
        await tester.pump();

        // Tap Save
        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pumpAndSettle();

        expect(fakeRepo.updateProfileCallCount, 1);
        expect(fakeRepo.lastUpdateProfileUserId, 'user-123');
        expect(fakeRepo.lastUpdateProfileFullName, 'Updated Full Name');

        // Displays updated confirmed name
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

        // Open edit dialog
        await tester.tap(find.byKey(const Key('profile_edit_name_button')));
        await tester.pumpAndSettle();

        // Enter name
        await tester.enterText(
          find.byKey(const Key('edit_name_textfield')),
          'Confirmed Name',
        );
        await tester.pump();

        // Tap Save once
        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pump();

        // While pending:
        expect(fakeRepo.updateProfileCallCount, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Attempt second Save tap while pending
        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pump();

        // Call count must remain strictly 1
        expect(fakeRepo.updateProfileCallCount, 1);

        // Complete the Future
        completer.complete(
          const UserProfile(id: 'user-123', fullName: 'Confirmed Name'),
        );
        await tester.pumpAndSettle();

        // Dialog closed and confirmed name displayed
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

        // Open edit dialog
        await tester.tap(find.byKey(const Key('profile_edit_name_button')));
        await tester.pumpAndSettle();

        // Enter name
        await tester.enterText(
          find.byKey(const Key('edit_name_textfield')),
          'New Name',
        );
        await tester.pump();

        // Tap Save
        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pumpAndSettle();

        // Dialog must remain open
        expect(find.byKey(const Key('edit_name_textfield')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Unable to save profile changes.'),
          ),
          findsOneWidget,
        );

        // Now fix error and retry
        fakeRepo.shouldThrowOnUpdate = false;
        await tester.tap(find.byKey(const Key('save_edit_name_button')));
        await tester.pumpAndSettle();

        // Dialog closed
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

        // Fabricated dashboard sections must NOT be in the UI
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
  });
}

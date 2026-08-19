import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/constants/navigation_types.dart';
import 'package:smartroute/features/home/screens/home_screen.dart';
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
  String? loadErrorMessage;

  Completer<UserProfile>? loadProfileCompleter;
  Completer<UserPreferences>? loadPreferencesCompleter;

  int getProfileCallCount = 0;
  int getPreferencesCallCount = 0;

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
    return UserProfile(id: userId, fullName: fullName, photoUrl: photoUrl);
  }

  @override
  Future<UserPreferences> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    return preferences;
  }
}

void main() {
  late FakeProfileRepository repository;
  late ProfileController controller;
  late List<AppScreen> navigatedScreens;

  const testUser = AppUser(
    id: 'user-123',
    email: 'test@example.com',
    fullName: 'Auth Metadata Name',
  );

  setUp(() {
    repository = FakeProfileRepository();
    controller = ProfileController(profileRepository: repository);
    navigatedScreens = [];
  });

  Widget createTestWidget({
    AppUser user = testUser,
    ProfileController? profileController,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          authUser: user,
          profileController: profileController ?? controller,
          onNavigate: (screen) => navigatedScreens.add(screen),
        ),
      ),
    );
  }

  group('HomeScreen - Real User Identity & Loading Lifecycle', () {
    testWidgets(
      'A. loads server profile and displays server profile name over auth metadata name',
      (WidgetTester tester) async {
        repository.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Server Profile Name',
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Welcome,'), findsOneWidget);
        expect(find.text('Server Profile Name 👋'), findsOneWidget);
        expect(find.textContaining('Yih Loong'), findsNothing);
        expect(find.textContaining('test@example.com'), findsNothing);
      },
    );

    testWidgets(
      'B. displays fallback auth metadata name while server profile load is pending',
      (WidgetTester tester) async {
        final profileCompleter = Completer<UserProfile>();
        final prefsCompleter = Completer<UserPreferences>();
        repository.loadProfileCompleter = profileCompleter;
        repository.loadPreferencesCompleter = prefsCompleter;

        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // Frame after post-frame callback

        // While pending, shows Auth Metadata Name and no fake user
        expect(find.text('Welcome,'), findsOneWidget);
        expect(find.text('Auth Metadata Name 👋'), findsOneWidget);
        expect(find.textContaining('Yih Loong'), findsNothing);

        // Resolve profile load
        profileCompleter.complete(
          const UserProfile(id: 'user-123', fullName: 'Server Profile Name'),
        );
        prefsCompleter.complete(const UserPreferences());
        await tester.pump();
        await tester.pump();

        expect(find.text('Server Profile Name 👋'), findsOneWidget);
      },
    );

    testWidgets(
      'C. remains usable and retains auth metadata name fallback when profile load fails',
      (WidgetTester tester) async {
        repository.shouldThrowOnLoad = true;
        repository.loadErrorMessage = 'Network disconnect';

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Welcome,'), findsOneWidget);
        expect(find.text('Auth Metadata Name 👋'), findsOneWidget);
        expect(find.textContaining('Network disconnect'), findsNothing);
        expect(find.textContaining('Yih Loong'), findsNothing);
      },
    );

    testWidgets(
      'uses generic SmartRoute User when both profile and auth name are empty',
      (WidgetTester tester) async {
        const emptyUser = AppUser(
          id: 'user-empty',
          fullName: '',
          email: 'empty@example.com',
        );
        repository.mockProfile = const UserProfile(
          id: 'user-empty',
          fullName: '   ',
        );

        await tester.pumpWidget(createTestWidget(user: emptyUser));
        await tester.pump();
        await tester.pump();

        expect(find.text('SmartRoute User 👋'), findsOneWidget);
      },
    );
  });

  group('HomeScreen - Navigation Actions', () {
    testWidgets(
      'D. tapping keyed quick actions and tools navigates to expected AppScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        // 1. Header notification icon
        await tester.tap(find.byKey(const Key('home_notification_action')));
        expect(navigatedScreens.last, AppScreen.alerts);

        // 2. Plan Trip quick action
        await tester.tap(find.byKey(const Key('home_plan_trip_action')));
        expect(navigatedScreens.last, AppScreen.planner);

        // 3. Transit Map quick action
        expect(find.text('Live Map'), findsNothing);
        expect(
          find.text('Transit Map'),
          findsNWidgets(2),
        ); // quick action + tool tile
        await tester.tap(find.byKey(const Key('home_live_map_action')));
        expect(navigatedScreens.last, AppScreen.map);

        // 4. Alerts quick action
        await tester.tap(find.byKey(const Key('home_alerts_action')));
        expect(navigatedScreens.last, AppScreen.alerts);

        // 5. Profile quick action
        await tester.tap(find.byKey(const Key('home_profile_action')));
        expect(navigatedScreens.last, AppScreen.profile);

        // 6. Primary Journey Card (Plan Your Journey)
        await tester.tap(find.text('PLAN YOUR JOURNEY'));
        expect(navigatedScreens.last, AppScreen.planner);

        // 7. Travel Tools: Service Alerts
        expect(
          find.text('View live service notices and disruptions'),
          findsNothing,
        );
        expect(
          find.text('View service notices and disruptions'),
          findsOneWidget,
        );
        await tester.tap(find.text('Service Alerts'));
        expect(navigatedScreens.last, AppScreen.alerts);

        // 8. Travel Tools: Transit Map
        await tester.tap(find.text('Transit Map').last);
        expect(navigatedScreens.last, AppScreen.map);

        // 9. Travel Tools: Profile & Preferences
        await tester.tap(find.text('Profile & Preferences'));
        expect(navigatedScreens.last, AppScreen.profile);
      },
    );
  });

  group('HomeScreen - Absence of Fabricated Sections', () {
    testWidgets(
      'E. all fabricated financial, alert, delay, card, and distance claims are absent',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.textContaining('Yih Loong'), findsNothing);
        expect(find.textContaining('2 Service Alerts Active'), findsNothing);
        expect(
          find.textContaining('MRT Kajang Line · 5–8 min delay'),
          findsNothing,
        );
        expect(find.textContaining('Asia Jaya LRT'), findsNothing);
        expect(find.textContaining('FARE SAVINGS THIS MONTH'), findsNothing);
        expect(find.textContaining('RM 18.40'), findsNothing);
        expect(find.textContaining('47 Trips'), findsNothing);
        expect(find.textContaining('RM 82.50'), findsNothing);
        expect(find.textContaining('RM 23.10'), findsNothing);
        expect(find.text('My Card'), findsNothing);
        expect(find.text('Live Map'), findsNothing);
        expect(find.textContaining('live service'), findsNothing);
      },
    );
  });

  group('HomeScreen - Responsive & Overflow Safety', () {
    testWidgets(
      'F. renders on 500x1000 and small 360x640 viewports without RenderFlex overflow',
      (WidgetTester tester) async {
        // Test standard viewport 500 x 1000
        tester.view.physicalSize = const Size(500, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);

        // Test small viewport 360 x 640
        tester.view.physicalSize = const Size(360, 640);
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });
}

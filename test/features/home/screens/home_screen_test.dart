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

  group('getGreeting Helper', () {
    test('returns correct greeting for different hours', () {
      expect(getGreeting(DateTime(2026, 8, 20, 5, 0)), 'Good morning');
      expect(getGreeting(DateTime(2026, 8, 20, 11, 59)), 'Good morning');
      expect(getGreeting(DateTime(2026, 8, 20, 12, 0)), 'Good afternoon');
      expect(getGreeting(DateTime(2026, 8, 20, 16, 59)), 'Good afternoon');
      expect(getGreeting(DateTime(2026, 8, 20, 17, 0)), 'Good evening');
      expect(getGreeting(DateTime(2026, 8, 20, 23, 59)), 'Good evening');
      expect(getGreeting(DateTime(2026, 8, 20, 4, 59)), 'Good evening');
    });
  });

  group('HomeScreen - Real User Identity & Loading Lifecycle', () {
    testWidgets(
      'A. loads server profile and displays server profile name in compact hero greeting',
      (WidgetTester tester) async {
        repository.mockProfile = const UserProfile(
          id: 'user-123',
          fullName: 'Server Profile Name',
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Server Profile Name 👋'), findsOneWidget);
        expect(find.text('Where would you like to go today?'), findsOneWidget);
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

        expect(find.text('Auth Metadata Name 👋'), findsOneWidget);
        expect(find.textContaining('Network disconnect'), findsNothing);
        expect(find.textContaining('Yih Loong'), findsNothing);
      },
    );

    testWidgets(
      'D. uses generic SmartRoute User when both profile and auth name are empty',
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

  group('HomeScreen - Navigation Architecture', () {
    testWidgets(
      'E & F. tapping journey card or plan button navigates to Planner, notification bell navigates to Alerts',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        // 1. Header notification icon -> Alerts
        await tester.tap(find.byKey(const Key('home_notification_action')));
        expect(navigatedScreens.last, AppScreen.alerts);

        // 2. Journey card Plan Journey button -> Planner
        await tester.tap(find.byKey(const Key('home_plan_journey_button')));
        expect(navigatedScreens.last, AppScreen.planner);

        // 3. Main Journey card container -> Planner
        await tester.tap(find.byKey(const Key('home_planner_card')));
        expect(navigatedScreens.last, AppScreen.planner);

        // Prove only planner and alerts were navigated to
        expect(
          navigatedScreens,
          containsAllInOrder([
            AppScreen.alerts,
            AppScreen.planner,
            AppScreen.planner,
          ]),
        );
      },
    );
  });

  group('HomeScreen - Information Architecture & Content Integrity', () {
    testWidgets(
      'contains primary journey planner content and SmartRoute value section',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        // Primary journey card content
        expect(find.text('Where do you want to go?'), findsOneWidget);
        expect(
          find.text('Plan your journey across Klang Valley.'),
          findsOneWidget,
        );
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Choose starting point'), findsOneWidget);
        expect(find.text('Destination'), findsOneWidget);
        expect(find.text('Search destination'), findsOneWidget);
        expect(find.text('Plan Journey'), findsOneWidget);

        // Non-interactive informational section
        expect(find.text('Travel smarter with SmartRoute'), findsOneWidget);
        expect(
          find.text(
            'Plan public transport journeys across Klang Valley from one simple starting point.',
          ),
          findsOneWidget,
        );
        expect(find.text('Route planning'), findsOneWidget);
        expect(find.text('Transit information'), findsOneWidget);
        expect(find.text('Service awareness'), findsOneWidget);
      },
    );

    testWidgets(
      'proves secondary navigation, duplicated settings, and fabricated data are completely absent',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        // Duplicated navigation & settings sections removed
        expect(find.text('YOUR TRAVEL SETUP'), findsNothing);
        expect(find.text('EXPLORE SMARTROUTE'), findsNothing);
        expect(find.text('Transit Map'), findsNothing);
        expect(find.text('Profile & Preferences'), findsNothing);
        expect(find.text('Notifications'), findsNothing);
        expect(find.text('Location'), findsNothing);
        expect(find.text('Language'), findsNothing);
        expect(find.text('QUICK ACTIONS'), findsNothing);
        expect(find.text('TRAVEL TOOLS'), findsNothing);

        // Fabricated / fake data absent
        expect(find.textContaining('Yih Loong'), findsNothing);
        expect(find.textContaining('Asia Jaya'), findsNothing);
        expect(find.textContaining('KL Sentral'), findsNothing);
        expect(find.textContaining('2 Service Alerts Active'), findsNothing);
        expect(
          find.textContaining('MRT Kajang Line · 5–8 min delay'),
          findsNothing,
        );
        expect(find.textContaining('FARE SAVINGS'), findsNothing);
        expect(find.textContaining('RM 18.40'), findsNothing);
        expect(find.textContaining('RM 82.50'), findsNothing);
        expect(find.textContaining('RM 23.10'), findsNothing);
        expect(find.text('My Card'), findsNothing);
        expect(find.text('Live Map'), findsNothing);
      },
    );
  });

  group('HomeScreen - Mobile-First Responsive & Overflow Safety', () {
    testWidgets(
      'renders without RenderFlex overflow across phone viewports (360x640, 390x844, 412x915, 500x1000)',
      (WidgetTester tester) async {
        final viewports = [
          const Size(360, 640),
          const Size(390, 844),
          const Size(412, 915),
          const Size(500, 1000),
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: 'RenderFlex overflow occurred on viewport $size',
          );
        }
      },
    );
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/constants/navigation_types.dart';
import 'package:smartroute/features/home/screens/home_screen.dart';
import 'package:smartroute/features/login/screens/login_screen.dart';
import 'package:smartroute/features/route_detail/screens/route_detail_screen.dart';
import 'package:smartroute/features/transit_information/screens/transit_information_screen.dart';
import 'package:smartroute/features/user_management/application/auth_controller.dart';
import 'package:smartroute/features/user_management/application/profile_controller.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/registration_result.dart';
import 'package:smartroute/features/user_management/domain/models/user_preferences.dart';
import 'package:smartroute/features/user_management/domain/models/user_profile.dart';
import 'package:smartroute/features/user_management/domain/repositories/auth_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/profile_repository.dart';
import 'package:smartroute/main.dart';

class FakeWidgetAuthRepository implements AuthRepository {
  Completer<AppUser?>? getCurrentUserCompleter;
  AppUser? mockUser;
  bool shouldThrowError = false;

  @override
  Future<AppUser?> getCurrentUser() async {
    if (shouldThrowError) throw Exception('Auth check failed');
    if (getCurrentUserCompleter != null) {
      return getCurrentUserCompleter!.future;
    }
    return mockUser;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return mockUser ?? AppUser(id: 'u-1', fullName: 'Test User', email: email);
  }

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return RegistrationResult(
      user: AppUser(id: 'u-1', fullName: fullName, email: email),
      hasActiveSession: true,
    );
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
  }
}

class FakeWidgetProfileRepository implements ProfileRepository {
  UserProfile? mockProfile;
  UserPreferences? mockPreferences;

  @override
  Future<UserProfile> getProfile({required String userId}) async {
    return mockProfile ??
        UserProfile(
          id: userId,
          fullName: 'Test User',
          photoUrl: 'https://example.com/photo.png',
        );
  }

  @override
  Future<UserPreferences> getPreferences({required String userId}) async {
    return mockPreferences ?? const UserPreferences();
  }

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    String? photoUrl,
  }) async {
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
    mockPreferences = preferences;
    return preferences;
  }
}

void main() {
  group('SmartRouteApp Root Auth Gate', () {
    late FakeWidgetProfileRepository fakeProfileRepo;
    late ProfileController profileController;

    setUp(() {
      fakeProfileRepo = FakeWidgetProfileRepository();
      profileController = ProfileController(profileRepository: fakeProfileRepo);
    });

    testWidgets(
      'session bootstrap gate shows progress indicator and does not flash LoginScreen while pending',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final completer = Completer<AppUser?>();
        final fakeAuthRepo = FakeWidgetAuthRepository();
        fakeAuthRepo.getCurrentUserCompleter = completer;

        final authController = AuthController(authRepository: fakeAuthRepo);

        await tester.pumpWidget(
          SmartRouteApp(
            authController: authController,
            profileController: profileController,
          ),
        );
        // Post frame callback fires initialize()
        await tester.pump();

        // While getCurrentUser is unresolved:
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(HomeScreen), findsNothing);

        // Resolve session with no logged-in user
        completer.complete(null);
        await tester.pump();
        await tester.pump();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      },
    );

    testWidgets('restored authenticated session displays HomeScreen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuthRepo = FakeWidgetAuthRepository();
      fakeAuthRepo.mockUser = const AppUser(
        id: 'u-session',
        fullName: 'Restored User',
        email: 'restored@example.com',
      );
      final authController = AuthController(authRepository: fakeAuthRepo);

      await tester.pumpWidget(
        SmartRouteApp(
          authController: authController,
          profileController: profileController,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets(
      'transition from authenticated to unauthenticated returns to LoginScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuthRepo = FakeWidgetAuthRepository();
        fakeAuthRepo.mockUser = const AppUser(
          id: 'u-session',
          fullName: 'Active User',
          email: 'active@example.com',
        );
        final authController = AuthController(authRepository: fakeAuthRepo);

        await tester.pumpWidget(
          SmartRouteApp(
            authController: authController,
            profileController: profileController,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(HomeScreen), findsOneWidget);

        await authController.signOut();
        await tester.pump();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      },
    );
  });

  testWidgets('Transit information opens T250 route details',
      (WidgetTester tester) async {
    AppScreen? requestedScreen;

    await tester.pumpWidget(
      MaterialApp(
        home: TransitInformationScreen(
          onNavigate: (screen) => requestedScreen = screen,
        ),
      ),
    );

    expect(find.text('Transit Information'), findsOneWidget);
    expect(find.text('T250'), findsOneWidget);

    await tester.tap(find.text('View Information'));

    expect(requestedScreen, AppScreen.routeDetail);
  });

  testWidgets('Route details adds T250 to favourites',
      (WidgetTester tester) async {
    bool? favouriteValue;

    await tester.pumpWidget(
      MaterialApp(
        home: RouteDetailScreen(
          isFavourite: false,
          onFavouriteChanged: (value) => favouriteValue = value,
          onBack: () {},
        ),
      ),
    );

    await tester.tap(find.text('Add to favourite'));

    expect(favouriteValue, isTrue);
  });
}

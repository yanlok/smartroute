import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/home/screens/home_screen.dart';
import 'package:smartroute/features/login/screens/login_screen.dart';
import 'package:smartroute/features/user_management/application/auth_controller.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/registration_result.dart';
import 'package:smartroute/features/user_management/domain/repositories/auth_repository.dart';
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

void main() {
  group('SmartRouteApp Root Auth Gate', () {
    testWidgets(
      'session bootstrap gate shows progress indicator and does not flash LoginScreen while pending',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final completer = Completer<AppUser?>();
        final fakeRepo = FakeWidgetAuthRepository();
        fakeRepo.getCurrentUserCompleter = completer;

        final authController = AuthController(authRepository: fakeRepo);

        await tester.pumpWidget(SmartRouteApp(authController: authController));
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

      final fakeRepo = FakeWidgetAuthRepository();
      fakeRepo.mockUser = const AppUser(
        id: 'u-session',
        fullName: 'Restored User',
        email: 'restored@example.com',
      );
      final authController = AuthController(authRepository: fakeRepo);

      await tester.pumpWidget(SmartRouteApp(authController: authController));
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

        final fakeRepo = FakeWidgetAuthRepository();
        fakeRepo.mockUser = const AppUser(
          id: 'u-session',
          fullName: 'Active User',
          email: 'active@example.com',
        );
        final authController = AuthController(authRepository: fakeRepo);

        await tester.pumpWidget(SmartRouteApp(authController: authController));
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
}

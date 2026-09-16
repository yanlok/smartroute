import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/theme/app_theme.dart';
import 'package:smartroute/features/login/screens/login_screen.dart';
import 'package:smartroute/features/user_management/application/auth_controller.dart';
import 'package:smartroute/features/user_management/domain/exceptions/auth_repository_exception.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/registration_result.dart';
import 'package:smartroute/features/user_management/domain/repositories/auth_repository.dart';

class FakeLoginAuthRepository implements AuthRepository {
  Completer<AppUser>? signInCompleter;
  AppUser? mockUser;
  bool shouldThrowError = false;
  String? errorMessage;
  bool registerHasSession = true;

  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastRegisterName;
  String? lastRegisterEmail;
  String? lastRegisterPassword;

  int signInCallCount = 0;
  int registerCallCount = 0;

  @override
  Future<AppUser?> getCurrentUser() async {
    return mockUser;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (shouldThrowError) {
      throw AuthRepositoryException(
        errorMessage ?? 'Invalid email or password',
      );
    }
    if (signInCompleter != null) {
      return signInCompleter!.future.then((user) {
        mockUser = user;
        return user;
      });
    }
    final user = mockUser ?? AppUser(id: 'u-1', fullName: 'User', email: email);
    mockUser = user;
    return user;
  }

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registerCallCount++;
    lastRegisterName = fullName;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    if (shouldThrowError) {
      throw AuthRepositoryException(errorMessage ?? 'Registration failed');
    }
    final user = AppUser(id: 'u-reg', fullName: fullName, email: email);
    if (registerHasSession) {
      mockUser = user;
    }
    return RegistrationResult(user: user, hasActiveSession: registerHasSession);
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {}

  int sendPasswordResetEmailCallCount = 0;
  String? lastResetEmail;
  int googleSignInCallCount = 0;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sendPasswordResetEmailCallCount++;
    lastResetEmail = email;
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {}

  @override
  Future<AppUser> signInWithGoogle() async {
    googleSignInCallCount++;
    final user =
        mockUser ??
        const AppUser(
          id: 'google-u1',
          fullName: 'Google User',
          email: 'google@example.com',
        );
    mockUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
  }
}

void main() {
  Widget createTestWidget(AuthController authController) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: LoginScreen(authController: authController)),
    );
  }

  group('LoginScreen Widget Tests', () {
    late FakeLoginAuthRepository repository;
    late AuthController controller;

    setUp(() {
      repository = FakeLoginAuthRepository();
      controller = AuthController(authRepository: repository);
    });

    testWidgets(
      'invalid email submission displays controller validation error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget(controller));
        await tester.pump();

        await tester.tap(find.text('Sign In to SmartRoute'));
        await tester.pump();

        expect(find.text('Email is required'), findsOneWidget);
        expect(repository.signInCallCount, 0);

        await tester.enterText(
          find.widgetWithText(TextField, 'name@example.com'),
          'invalid-email',
        );
        await tester.tap(find.text('Sign In to SmartRoute'));
        await tester.pump();

        expect(find.text('Please enter a valid email address'), findsOneWidget);
        expect(repository.signInCallCount, 0);
      },
    );

    testWidgets('valid Sign In sends email and password to repository', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'name@example.com'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '••••••••'),
        'password123',
      );

      await tester.tap(find.text('Sign In to SmartRoute'));
      await tester.pump();

      expect(repository.signInCallCount, 1);
      expect(repository.lastSignInEmail, 'user@example.com');
      expect(repository.lastSignInPassword, 'password123');
      expect(controller.isAuthenticated, isTrue);
    });

    testWidgets('repository sign-in failure displays safe error message', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      repository.shouldThrowError = true;
      repository.errorMessage = 'Invalid email or password';

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'name@example.com'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '••••••••'),
        'wrongpassword',
      );

      await tester.tap(find.text('Sign In to SmartRoute'));
      await tester.pump();

      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(controller.isAuthenticated, isFalse);
    });

    testWidgets('Register sends full name, email, and password to repository', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      await tester.tap(find.text('Register'));
      await tester.pump();

      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('Create My Account'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your full name'),
        'Jane Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'name@example.com'),
        'jane@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '••••••••'),
        'password123',
      );

      await tester.tap(find.text('Create My Account'));
      await tester.pump();

      expect(repository.registerCallCount, 1);
      expect(repository.lastRegisterName, 'Jane Doe');
      expect(repository.lastRegisterEmail, 'jane@example.com');
      expect(repository.lastRegisterPassword, 'password123');
    });

    testWidgets(
      'registration with active session marks controller authenticated',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        repository.registerHasSession = true;

        await tester.pumpWidget(createTestWidget(controller));
        await tester.pump();

        await tester.tap(find.text('Register'));
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your full name'),
          'Session User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'name@example.com'),
          'session@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, '••••••••'),
          'password123',
        );

        await tester.tap(find.text('Create My Account'));
        await tester.pump();

        expect(controller.isAuthenticated, isTrue);
        expect(controller.requiresEmailConfirmation, isFalse);
      },
    );

    testWidgets(
      'registration requiring email confirmation remains unauthenticated, shows confirmation message, and switches to Sign In tab',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        repository.registerHasSession = false;

        await tester.pumpWidget(createTestWidget(controller));
        await tester.pump();

        await tester.tap(find.text('Register'));
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your full name'),
          'Pending User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'name@example.com'),
          'pending@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, '••••••••'),
          'password123',
        );

        await tester.tap(find.text('Create My Account'));
        await tester.pump();

        expect(controller.isAuthenticated, isFalse);
        expect(controller.requiresEmailConfirmation, isTrue);
        expect(
          find.text(
            'Account created. Check your email to confirm your account, then sign in.',
          ),
          findsOneWidget,
        );

        expect(find.text('Sign In to SmartRoute'), findsOneWidget);

        expect(find.text('pending@example.com'), findsOneWidget);
      },
    );

    testWidgets(
      'primary button prevents duplicate submission while loading with pending Future',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final signInCompleter = Completer<AppUser>();
        repository.signInCompleter = signInCompleter;

        await tester.pumpWidget(createTestWidget(controller));
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextField, 'name@example.com'),
          'user@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, '••••••••'),
          'password123',
        );

        await tester.tap(find.text('Sign In to SmartRoute'));
        await tester.pump();

        expect(repository.signInCallCount, 1);
        expect(controller.isLoading, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final loadingButton = find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(InkWell),
        );
        await tester.tap(loadingButton);
        await tester.pump();

        expect(repository.signInCallCount, 1);

        const user = AppUser(
          id: 'u-1',
          fullName: 'User',
          email: 'user@example.com',
        );
        signInCompleter.complete(user);
        await tester.pump();
        await tester.pump();

        expect(controller.isLoading, isFalse);
        expect(controller.isAuthenticated, isTrue);
        expect(controller.currentUser, user);
      },
    );

    testWidgets('tapping Forgot password opens modal and sends reset link', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      final forgotButton = find.text('Forgot password?');
      expect(forgotButton, findsOneWidget);
      await tester.tap(forgotButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(
        find.text(
          'Enter your registered email and we will send you a password recovery link.',
        ),
        findsOneWidget,
      );

      final resetEmailInput = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(resetEmailInput, 'forgot@example.com');
      await tester.pump();

      final sendLinkButton = find.widgetWithText(
        FilledButton,
        'Send Recovery Link',
      );
      await tester.tap(sendLinkButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.sendPasswordResetEmailCallCount, 1);
      expect(repository.lastResetEmail, 'forgot@example.com');
    });

    testWidgets('does not show social or Google sign in on login screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('OR'), findsNothing);
    });
  });
}

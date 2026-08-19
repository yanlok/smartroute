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

        // Tap submit with empty fields
        await tester.tap(find.text('Sign In to SmartRoute'));
        await tester.pump();

        expect(find.text('Email is required'), findsOneWidget);
        expect(repository.signInCallCount, 0);

        // Enter invalid email format
        await tester.enterText(
          find.widgetWithText(TextField, 'yih.loong@gmail.com'),
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
        find.widgetWithText(TextField, 'yih.loong@gmail.com'),
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
        find.widgetWithText(TextField, 'yih.loong@gmail.com'),
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

      // Switch to Register tab
      await tester.tap(find.text('Register'));
      await tester.pump();

      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('Create My Account'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Yih Loong'),
        'Jane Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'yih.loong@gmail.com'),
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
          find.widgetWithText(TextField, 'Yih Loong'),
          'Session User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'yih.loong@gmail.com'),
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
          find.widgetWithText(TextField, 'Yih Loong'),
          'Pending User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'yih.loong@gmail.com'),
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
        // Switched back to Sign In tab
        expect(find.text('Sign In to SmartRoute'), findsOneWidget);
        // Password cleared, email preserved
        expect(find.text('pending@example.com'), findsOneWidget);
      },
    );

    testWidgets('primary button prevents duplicate submission while loading', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'yih.loong@gmail.com'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '••••••••'),
        'password123',
      );

      // Trigger sign-in
      await tester.tap(find.text('Sign In to SmartRoute'));
      await tester.pump();

      expect(repository.signInCallCount, 1);
    });

    testWidgets('Google button does NOT authenticate user', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      await tester.tap(find.text('Google'));
      await tester.pump();

      expect(controller.isAuthenticated, isFalse);
      expect(repository.signInCallCount, 0);
      expect(
        find.text('Google sign-in is not available in this version.'),
        findsOneWidget,
      );
    });

    testWidgets('Apple button does NOT authenticate user', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(controller));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pump();

      expect(controller.isAuthenticated, isFalse);
      expect(repository.signInCallCount, 0);
      expect(
        find.text('Apple sign-in is not available in this version.'),
        findsOneWidget,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/user_management/application/auth_controller.dart';
import 'package:smartroute/features/user_management/domain/exceptions/auth_repository_exception.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/registration_result.dart';
import 'package:smartroute/features/user_management/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  AppUser? mockUser;
  bool shouldThrowError = false;
  Exception? customException;
  String errorMessage = 'Auth error';
  bool registerHasActiveSession = true;

  bool signInCalled = false;
  bool registerCalled = false;
  bool signOutCalled = false;
  bool getCurrentUserCalled = false;
  bool changePasswordCalled = false;

  String? lastEmail;
  String? lastPassword;
  String? lastFullName;
  String? lastCurrentPassword;
  String? lastNewPassword;

  void _checkAndThrow() {
    if (customException != null) throw customException!;
    if (shouldThrowError) throw AuthRepositoryException(errorMessage);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    getCurrentUserCalled = true;
    _checkAndThrow();
    return mockUser;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    lastEmail = email;
    lastPassword = password;
    _checkAndThrow();
    return mockUser ??
        AppUser(id: 'user-1', fullName: 'Test User', email: email);
  }

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registerCalled = true;
    lastFullName = fullName;
    lastEmail = email;
    lastPassword = password;
    _checkAndThrow();
    final user =
        mockUser ?? AppUser(id: 'user-1', fullName: fullName, email: email);
    return RegistrationResult(
      user: user,
      hasActiveSession: registerHasActiveSession,
    );
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalled = true;
    lastEmail = email;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    _checkAndThrow();
  }

  bool sendPasswordResetEmailCalled = false;
  bool resetPasswordCalled = false;
  bool signInWithGoogleCalled = false;
  String? lastResetEmail;
  String? lastResetNewPassword;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sendPasswordResetEmailCalled = true;
    lastResetEmail = email;
    _checkAndThrow();
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    resetPasswordCalled = true;
    lastResetNewPassword = newPassword;
    _checkAndThrow();
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    _checkAndThrow();
    return mockUser ??
        const AppUser(
          id: 'google-1',
          fullName: 'Google User',
          email: 'google@test.com',
        );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _checkAndThrow();
  }
}

void main() {
  group('AuthController', () {
    late FakeAuthRepository repository;
    late AuthController controller;

    setUp(() {
      repository = FakeAuthRepository();
      controller = AuthController(authRepository: repository);
    });

    test(
      'initial state is unauthenticated, not initialized, and not loading',
      () {
        expect(controller.currentUser, isNull);
        expect(controller.isLoading, isFalse);
        expect(controller.isInitialized, isFalse);
        expect(controller.errorMessage, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.requiresEmailConfirmation, isFalse);
      },
    );

    test(
      'initialize current session sets user, isInitialized true, and resets loading',
      () async {
        const user = AppUser(
          id: 'u-init',
          fullName: 'Init User',
          email: 'init@example.com',
        );
        repository.mockUser = user;

        await controller.initialize();

        expect(repository.getCurrentUserCalled, isTrue);
        expect(controller.currentUser, user);
        expect(controller.isAuthenticated, isTrue);
        expect(controller.isInitialized, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, isNull);
        expect(controller.requiresEmailConfirmation, isFalse);
      },
    );

    test(
      'initialize without session sets authenticated false and isInitialized true',
      () async {
        repository.mockUser = null;

        await controller.initialize();

        expect(repository.getCurrentUserCalled, isTrue);
        expect(controller.currentUser, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.isInitialized, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.errorMessage, isNull);
        expect(controller.requiresEmailConfirmation, isFalse);
      },
    );

    test(
      'initialize failure clears session, exposes error, sets isInitialized true, and resets loading',
      () async {
        repository.shouldThrowError = true;
        repository.errorMessage = 'Session expired';

        await controller.initialize();

        expect(repository.getCurrentUserCalled, isTrue);
        expect(controller.currentUser, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.isInitialized, isTrue);
        expect(controller.errorMessage, 'Session expired');
        expect(controller.isLoading, isFalse);
        expect(controller.requiresEmailConfirmation, isFalse);
      },
    );

    test(
      'normal signIn/register loading does not reset isInitialized',
      () async {
        await controller.initialize();
        expect(controller.isInitialized, isTrue);

        repository.mockUser = const AppUser(
          id: 'u-1',
          fullName: 'User',
          email: 'user@test.com',
        );
        await controller.signIn(
          email: 'user@test.com',
          password: 'password123',
        );

        expect(controller.isInitialized, isTrue);
      },
    );

    test('valid sign-in calls repository with trimmed email', () async {
      const email = '  user@test.com  ';
      const password = 'mypassword';

      final result = await controller.signIn(email: email, password: password);

      expect(result, isTrue);
      expect(repository.signInCalled, isTrue);
      expect(repository.lastEmail, 'user@test.com');
      expect(repository.lastPassword, password);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
      expect(controller.requiresEmailConfirmation, isFalse);
    });

    test('invalid sign-in email is rejected before repository', () async {
      final invalidEmails = [
        '',
        '   ',
        'plainaddress',
        '@missingusername.com',
        'username@.com',
        'username@domain',
      ];

      for (final email in invalidEmails) {
        final result = await controller.signIn(
          email: email,
          password: 'password123',
        );
        expect(result, isFalse);
        expect(controller.errorMessage, isNotNull);
        expect(repository.signInCalled, isFalse);
      }
    });

    test('empty sign-in password is rejected', () async {
      final result = await controller.signIn(
        email: 'valid@example.com',
        password: '',
      );

      expect(result, isFalse);
      expect(controller.errorMessage, 'Password is required');
      expect(repository.signInCalled, isFalse);
    });

    test(
      'sign-in password shorter than 8 characters is allowed to reach repository',
      () async {
        const shortPassword = '123';
        const user = AppUser(
          id: 'u-short',
          fullName: 'Short Pwd User',
          email: 'user@example.com',
        );
        repository.mockUser = user;

        final result = await controller.signIn(
          email: 'user@example.com',
          password: shortPassword,
        );

        expect(result, isTrue);
        expect(repository.signInCalled, isTrue);
        expect(repository.lastPassword, shortPassword);
        expect(controller.currentUser, user);
        expect(controller.isAuthenticated, isTrue);
      },
    );

    test(
      'registration with active session sets user and is authenticated',
      () async {
        const user = AppUser(
          id: 'u-reg-active',
          fullName: 'Jane Doe',
          email: 'jane@example.com',
        );
        repository.mockUser = user;
        repository.registerHasActiveSession = true;

        final result = await controller.register(
          fullName: '  Jane Doe  ',
          email: '  jane@example.com  ',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(repository.registerCalled, isTrue);
        expect(repository.lastFullName, 'Jane Doe');
        expect(repository.lastEmail, 'jane@example.com');
        expect(repository.lastPassword, 'password123');
        expect(controller.currentUser, user);
        expect(controller.isAuthenticated, isTrue);
        expect(controller.requiresEmailConfirmation, isFalse);
        expect(controller.errorMessage, isNull);
        expect(controller.isLoading, isFalse);
      },
    );

    test(
      'registration requiring email confirmation returns true with requiresEmailConfirmation true and unauthenticated',
      () async {
        const user = AppUser(
          id: 'u-reg-confirm',
          fullName: 'Pending User',
          email: 'pending@example.com',
        );
        repository.mockUser = user;
        repository.registerHasActiveSession = false;

        final result = await controller.register(
          fullName: 'Pending User',
          email: 'pending@example.com',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(repository.registerCalled, isTrue);
        expect(controller.currentUser, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.requiresEmailConfirmation, isTrue);
        expect(controller.errorMessage, isNull);
        expect(controller.isLoading, isFalse);
      },
    );

    test('invalid registration name is rejected', () async {
      final invalidNames = ['', ' ', '   ', 'a'];

      for (final name in invalidNames) {
        final result = await controller.register(
          fullName: name,
          email: 'valid@example.com',
          password: 'password123',
        );
        expect(result, isFalse);
        expect(controller.errorMessage, isNotNull);
        expect(repository.registerCalled, isFalse);
      }
    });

    test('invalid registration email is rejected', () async {
      final invalidEmails = ['', '   ', 'not-an-email', 'name@domain'];

      for (final email in invalidEmails) {
        final result = await controller.register(
          fullName: 'John Doe',
          email: email,
          password: 'password123',
        );
        expect(result, isFalse);
        expect(controller.errorMessage, isNotNull);
        expect(repository.registerCalled, isFalse);
      }
    });

    test(
      'registration password shorter than 8 characters is rejected',
      () async {
        final shortPasswords = ['', '1234567', 'abc'];

        for (final password in shortPasswords) {
          final result = await controller.register(
            fullName: 'John Doe',
            email: 'valid@example.com',
            password: password,
          );
          expect(result, isFalse);
          expect(controller.errorMessage, isNotNull);
          expect(repository.registerCalled, isFalse);
        }
      },
    );

    test(
      'repository auth failure sets errorMessage and resets email confirmation',
      () async {
        repository.shouldThrowError = true;
        repository.errorMessage = 'Invalid credentials';

        final signInResult = await controller.signIn(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(signInResult, isFalse);
        expect(controller.currentUser, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.requiresEmailConfirmation, isFalse);
        expect(controller.errorMessage, 'Invalid credentials');
        expect(controller.isLoading, isFalse);

        final registerResult = await controller.register(
          fullName: 'John Doe',
          email: 'user@example.com',
          password: 'password123',
        );

        expect(registerResult, isFalse);
        expect(controller.currentUser, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.requiresEmailConfirmation, isFalse);
        expect(controller.errorMessage, 'Invalid credentials');
        expect(controller.isLoading, isFalse);
      },
    );

    test(
      'AuthRepositoryException message is exposed as controller errorMessage',
      () async {
        repository.customException = const AuthRepositoryException(
          'Incorrect email or password.',
        );

        final result = await controller.signIn(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(result, isFalse);
        expect(controller.errorMessage, 'Incorrect email or password.');
      },
    );

    test(
      'arbitrary unexpected Exception does not expose raw technical message',
      () async {
        repository.customException = Exception(
          'postgres internal jwt secret debug blah',
        );

        final result = await controller.signIn(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(result, isFalse);
        expect(
          controller.errorMessage?.contains('postgres internal jwt secret'),
          isFalse,
        );
        expect(
          controller.errorMessage,
          'Something went wrong. Please try again.',
        );
      },
    );

    test('signIn success clears prior email-confirmation state', () async {
      repository.registerHasActiveSession = false;
      await controller.register(
        fullName: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );
      expect(controller.requiresEmailConfirmation, isTrue);

      repository.mockUser = const AppUser(
        id: 'u-1',
        fullName: 'Test User',
        email: 'test@example.com',
      );
      await controller.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(controller.isAuthenticated, isTrue);
      expect(controller.requiresEmailConfirmation, isFalse);
    });

    test('signOut clears current user and email-confirmation state', () async {
      repository.mockUser = const AppUser(
        id: 'u-1',
        fullName: 'John Doe',
        email: 'john@example.com',
      );
      await controller.signIn(
        email: 'john@example.com',
        password: 'password123',
      );
      expect(controller.currentUser, isNotNull);
      expect(controller.isAuthenticated, isTrue);

      await controller.signOut();

      expect(repository.signOutCalled, isTrue);
      expect(controller.currentUser, isNull);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.requiresEmailConfirmation, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('loading returns to false after operations', () async {
      final result = await controller.signIn(
        email: 'user@test.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test(
      'duplicate auth submission protection prevents parallel execution',
      () async {
        final future1 = controller.signIn(
          email: 'user1@example.com',
          password: 'password123',
        );
        final future2 = controller.signIn(
          email: 'user2@example.com',
          password: 'password123',
        );

        final results = await Future.wait([future1, future2]);

        expect(results.contains(false), isTrue);
        expect(results.contains(true), isTrue);
      },
    );

    test('change password validates all fields and password rules', () async {
      expect(
        await controller.changePassword(
          email: 'user@example.com',
          currentPassword: '',
          newPassword: '',
          confirmPassword: '',
        ),
        isFalse,
      );
      expect(
        controller.passwordErrorMessage,
        'All password fields are required.',
      );

      expect(
        await controller.changePassword(
          email: 'user@example.com',
          currentPassword: 'CurrentPass1',
          newPassword: 'short',
          confirmPassword: 'short',
        ),
        isFalse,
      );
      expect(
        controller.passwordErrorMessage,
        'New password must be at least 8 characters.',
      );

      expect(
        await controller.changePassword(
          email: 'user@example.com',
          currentPassword: 'CurrentPass1',
          newPassword: 'NewPassword1',
          confirmPassword: 'DifferentPass1',
        ),
        isFalse,
      );
      expect(controller.passwordErrorMessage, 'New passwords do not match.');

      expect(
        await controller.changePassword(
          email: 'user@example.com',
          currentPassword: 'SamePassword1',
          newPassword: 'SamePassword1',
          confirmPassword: 'SamePassword1',
        ),
        isFalse,
      );
      expect(
        controller.passwordErrorMessage,
        'New password must be different from your current password.',
      );
      expect(repository.changePasswordCalled, isFalse);
    });

    test('change password exposes wrong current password safely', () async {
      repository.customException = const AuthRepositoryException(
        'Current password is incorrect.',
      );

      final result = await controller.changePassword(
        email: 'user@example.com',
        currentPassword: 'WrongPassword1',
        newPassword: 'NewPassword1',
        confirmPassword: 'NewPassword1',
      );

      expect(result, isFalse);
      expect(controller.passwordErrorMessage, 'Current password is incorrect.');
      expect(controller.isChangingPassword, isFalse);
    });

    test('change password sends verified values to the repository', () async {
      final result = await controller.changePassword(
        email: 'user@example.com',
        currentPassword: 'CurrentPass1',
        newPassword: 'NewPassword1',
        confirmPassword: 'NewPassword1',
      );

      expect(result, isTrue);
      expect(repository.changePasswordCalled, isTrue);
      expect(repository.lastEmail, 'user@example.com');
      expect(repository.lastCurrentPassword, 'CurrentPass1');
      expect(repository.lastNewPassword, 'NewPassword1');
      expect(controller.passwordErrorMessage, isNull);
      expect(controller.isChangingPassword, isFalse);
    });

    test('clearError clears errorMessage and notifies listeners', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Some error';

      await controller.initialize();
      expect(controller.errorMessage, isNotNull);

      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.clearError();
      expect(controller.errorMessage, isNull);
      expect(notified, isTrue);
    });

    test(
      'sendPasswordResetEmail validates email and calls repository',
      () async {
        final emptyResult = await controller.sendPasswordResetEmail('');
        expect(emptyResult, isFalse);
        expect(controller.errorMessage, 'Email is required');

        final invalidResult = await controller.sendPasswordResetEmail(
          'invalid',
        );
        expect(invalidResult, isFalse);
        expect(controller.errorMessage, 'Please enter a valid email address');

        final validResult = await controller.sendPasswordResetEmail(
          'user@test.com',
        );
        expect(validResult, isTrue);
        expect(repository.sendPasswordResetEmailCalled, isTrue);
        expect(repository.lastResetEmail, 'user@test.com');
        expect(controller.errorMessage, isNull);
      },
    );

    test('resetPassword validates fields and updates password', () async {
      final emptyResult = await controller.resetPassword(
        newPassword: '',
        confirmPassword: '',
      );
      expect(emptyResult, isFalse);
      expect(
        controller.resetPasswordErrorMessage,
        'All password fields are required.',
      );

      final shortResult = await controller.resetPassword(
        newPassword: 'short',
        confirmPassword: 'short',
      );
      expect(shortResult, isFalse);
      expect(
        controller.resetPasswordErrorMessage,
        'New password must be at least 8 characters.',
      );

      final mismatchResult = await controller.resetPassword(
        newPassword: 'password1',
        confirmPassword: 'password2',
      );
      expect(mismatchResult, isFalse);
      expect(
        controller.resetPasswordErrorMessage,
        'New passwords do not match.',
      );

      final successResult = await controller.resetPassword(
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );
      expect(successResult, isTrue);
      expect(repository.resetPasswordCalled, isTrue);
      expect(repository.lastResetNewPassword, 'newpassword123');
      expect(controller.resetPasswordErrorMessage, isNull);
      expect(controller.isPasswordRecovery, isFalse);
    });

    test('signInWithGoogle authenticates user successfully', () async {
      final success = await controller.signInWithGoogle();

      expect(success, isTrue);
      expect(repository.signInWithGoogleCalled, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser?.email, 'google@test.com');
    });

    test(
      'handleAuthChangeEvent sets password recovery mode on passwordRecovery event',
      () {
        expect(controller.isPasswordRecovery, isFalse);

        controller.handleAuthChangeEvent(AuthChangeEvent.passwordRecovery);

        expect(controller.isPasswordRecovery, isTrue);
      },
    );
  });
}

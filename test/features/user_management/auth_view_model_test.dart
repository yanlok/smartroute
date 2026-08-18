import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/user_management/models/app_user.dart';
import 'package:smartroute/features/user_management/models/user_preferences.dart';
import 'package:smartroute/features/user_management/repositories/auth_repository.dart';
import 'package:smartroute/features/user_management/view_models/auth_view_model.dart';

class FakeAuthRepository implements AuthRepository {
  AppUser? mockUser;
  bool shouldThrowError = false;
  String errorMessage = 'Auth error';

  bool signInCalled = false;
  bool registerCalled = false;
  bool signOutCalled = false;
  bool getCurrentUserCalled = false;

  String? lastEmail;
  String? lastPassword;
  String? lastFullName;

  @override
  Future<AppUser?> getCurrentUser() async {
    getCurrentUserCalled = true;
    if (shouldThrowError) throw Exception(errorMessage);
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
    if (shouldThrowError) throw Exception(errorMessage);
    return mockUser ??
        AppUser(id: 'user-1', fullName: 'Test User', email: email);
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registerCalled = true;
    lastFullName = fullName;
    lastEmail = email;
    lastPassword = password;
    if (shouldThrowError) throw Exception(errorMessage);
    return mockUser ?? AppUser(id: 'user-1', fullName: fullName, email: email);
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    if (shouldThrowError) throw Exception(errorMessage);
  }
}

void main() {
  group('AuthViewModel', () {
    late FakeAuthRepository repository;
    late AuthViewModel viewModel;

    setUp(() {
      repository = FakeAuthRepository();
      viewModel = AuthViewModel(authRepository: repository);
    });

    test('initial state is unauthenticated and not loading', () {
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isAuthenticated, isFalse);
    });

    test('invalid email is rejected for signIn and register', () async {
      final invalidEmails = [
        '',
        '   ',
        'plainaddress',
        '@missingusername.com',
        'username@.com',
        'username@domain',
      ];

      for (final email in invalidEmails) {
        final signInResult = await viewModel.signIn(
          email: email,
          password: 'password123',
        );
        expect(signInResult, isFalse);
        expect(viewModel.errorMessage, isNotNull);
        expect(repository.signInCalled, isFalse);

        final registerResult = await viewModel.register(
          fullName: 'John Doe',
          email: email,
          password: 'password123',
        );
        expect(registerResult, isFalse);
        expect(viewModel.errorMessage, isNotNull);
        expect(repository.registerCalled, isFalse);
      }
    });

    test('password shorter than 8 characters is rejected', () async {
      final shortPasswords = ['', '1234567', '  abc  '];

      for (final password in shortPasswords) {
        final signInResult = await viewModel.signIn(
          email: 'valid@example.com',
          password: password,
        );
        expect(signInResult, isFalse);
        expect(viewModel.errorMessage, isNotNull);
        expect(repository.signInCalled, isFalse);

        final registerResult = await viewModel.register(
          fullName: 'John Doe',
          email: 'valid@example.com',
          password: password,
        );
        expect(registerResult, isFalse);
        expect(viewModel.errorMessage, isNotNull);
        expect(repository.registerCalled, isFalse);
      }
    });

    test('empty registration name is rejected', () async {
      final invalidNames = ['', ' ', '   ', 'a'];

      for (final name in invalidNames) {
        final result = await viewModel.register(
          fullName: name,
          email: 'valid@example.com',
          password: 'password123',
        );
        expect(result, isFalse);
        expect(viewModel.errorMessage, isNotNull);
        expect(repository.registerCalled, isFalse);
      }
    });

    test('valid sign-in calls repository', () async {
      const email = '  user@test.com  ';
      const password = 'password123';

      final result = await viewModel.signIn(email: email, password: password);

      expect(result, isTrue);
      expect(repository.signInCalled, isTrue);
      expect(repository.lastEmail, 'user@test.com');
      expect(repository.lastPassword, password);
      expect(viewModel.errorMessage, isNull);
    });

    test('successful sign-in sets currentUser', () async {
      const user = AppUser(
        id: 'u-123',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );
      repository.mockUser = user;

      final result = await viewModel.signIn(
        email: 'jane@example.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(viewModel.currentUser, user);
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('valid registration calls repository and sets currentUser', () async {
      const user = AppUser(
        id: 'u-456',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
      );
      repository.mockUser = user;

      final result = await viewModel.register(
        fullName: '  Jane Doe  ',
        email: '  jane@example.com  ',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(repository.registerCalled, isTrue);
      expect(repository.lastFullName, 'Jane Doe');
      expect(repository.lastEmail, 'jane@example.com');
      expect(viewModel.currentUser, user);
      expect(viewModel.isAuthenticated, isTrue);
    });

    test('repository failure produces errorMessage', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Invalid credentials';

      final signInResult = await viewModel.signIn(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(signInResult, isFalse);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.errorMessage, contains('Invalid credentials'));

      final registerResult = await viewModel.register(
        fullName: 'John Doe',
        email: 'user@example.com',
        password: 'password123',
      );

      expect(registerResult, isFalse);
      expect(viewModel.errorMessage, contains('Invalid credentials'));
    });

    test('signOut clears currentUser', () async {
      repository.mockUser = const AppUser(
        id: 'u-1',
        fullName: 'John Doe',
        email: 'john@example.com',
      );
      await viewModel.signIn(
        email: 'john@example.com',
        password: 'password123',
      );
      expect(viewModel.currentUser, isNotNull);
      expect(viewModel.isAuthenticated, isTrue);

      await viewModel.signOut();

      expect(repository.signOutCalled, isTrue);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isAuthenticated, isFalse);
    });

    test('initialize fetches current user from repository', () async {
      const user = AppUser(
        id: 'u-init',
        fullName: 'Init User',
        email: 'init@example.com',
      );
      repository.mockUser = user;

      await viewModel.initialize();

      expect(repository.getCurrentUserCalled, isTrue);
      expect(viewModel.currentUser, user);
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('initialize failure sets errorMessage', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Session expired';

      await viewModel.initialize();

      expect(repository.getCurrentUserCalled, isTrue);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.errorMessage, contains('Session expired'));
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('AppUser model', () {
    test('instantiates with required and optional fields', () {
      const user = AppUser(
        id: '1',
        fullName: 'Alex Lee',
        email: 'alex@example.com',
        photoUrl: 'https://example.com/avatar.png',
      );

      expect(user.id, '1');
      expect(user.fullName, 'Alex Lee');
      expect(user.email, 'alex@example.com');
      expect(user.photoUrl, 'https://example.com/avatar.png');
    });

    test('copyWith creates modified clone', () {
      const user = AppUser(
        id: '1',
        fullName: 'Alex Lee',
        email: 'alex@example.com',
      );

      final updated = user.copyWith(
        fullName: 'Alexander Lee',
        photoUrl: 'https://example.com/new.png',
      );

      expect(updated.id, '1');
      expect(updated.fullName, 'Alexander Lee');
      expect(updated.email, 'alex@example.com');
      expect(updated.photoUrl, 'https://example.com/new.png');
    });
  });

  group('UserPreferences model', () {
    test('has expected default values', () {
      const prefs = UserPreferences();

      expect(prefs.notificationsEnabled, isTrue);
      expect(prefs.locationEnabled, isTrue);
      expect(prefs.language, 'English (Malaysia)');
    });

    test('copyWith creates modified clone', () {
      const prefs = UserPreferences();
      final updated = prefs.copyWith(
        notificationsEnabled: false,
        language: 'Bahasa Melayu',
      );

      expect(updated.notificationsEnabled, isFalse);
      expect(updated.locationEnabled, isTrue);
      expect(updated.language, 'Bahasa Melayu');
    });
  });
}

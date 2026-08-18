import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartroute/features/user_management/data/repositories/supabase_auth_repository.dart';
import 'package:smartroute/features/user_management/domain/exceptions/auth_repository_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late SupabaseAuthRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    repository = SupabaseAuthRepository(client: mockClient);
  });

  User createTestUser({
    String id = 'user-123',
    String? email = 'alex@example.com',
    String? fullName,
    String? photoUrl,
  }) {
    final metadata = <String, dynamic>{};
    if (fullName != null) metadata['full_name'] = fullName;
    if (photoUrl != null) metadata['photo_url'] = photoUrl;

    return User(
      id: id,
      appMetadata: const {},
      userMetadata: metadata,
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
      email: email,
    );
  }

  Session createTestSession({required User user}) {
    return Session(
      accessToken: 'test-access-token',
      tokenType: 'bearer',
      user: user,
    );
  }

  group('SupabaseAuthRepository - getCurrentUser', () {
    test('returns null when there is no active session', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      final result = await repository.getCurrentUser();

      expect(result, isNull);
    });

    test('returns mapped AppUser when active session exists', () async {
      final user = createTestUser(
        id: 'u-current',
        email: 'current@test.com',
        fullName: 'Current User',
        photoUrl: 'https://example.com/pic.png',
      );
      final session = createTestSession(user: user);
      when(() => mockAuth.currentSession).thenReturn(session);

      final result = await repository.getCurrentUser();

      expect(result, isNotNull);
      expect(result!.id, 'u-current');
      expect(result.email, 'current@test.com');
      expect(result.fullName, 'Current User');
      expect(result.photoUrl, 'https://example.com/pic.png');
    });
  });

  group('SupabaseAuthRepository - signIn', () {
    test(
      'calls signInWithPassword with correct parameters and returns AppUser',
      () async {
        final user = createTestUser(
          id: 'u-signin',
          email: 'signin@test.com',
          fullName: 'Sign In User',
        );
        final session = createTestSession(user: user);
        final response = AuthResponse(session: session, user: user);

        when(
          () => mockAuth.signInWithPassword(
            email: 'signin@test.com',
            password: 'secretPassword',
          ),
        ).thenAnswer((_) async => response);

        final result = await repository.signIn(
          email: 'signin@test.com',
          password: 'secretPassword',
        );

        verify(
          () => mockAuth.signInWithPassword(
            email: 'signin@test.com',
            password: 'secretPassword',
          ),
        ).called(1);

        expect(result.id, 'u-signin');
        expect(result.email, 'signin@test.com');
        expect(result.fullName, 'Sign In User');
      },
    );

    test(
      'throws AuthRepositoryException when response has no session',
      () async {
        final user = createTestUser(email: 'nosession@test.com');
        final response = AuthResponse(session: null, user: user);

        when(
          () => mockAuth.signInWithPassword(
            email: 'nosession@test.com',
            password: 'secretPassword',
          ),
        ).thenAnswer((_) async => response);

        expect(
          () => repository.signIn(
            email: 'nosession@test.com',
            password: 'secretPassword',
          ),
          throwsA(isA<AuthRepositoryException>()),
        );
      },
    );
  });

  group('SupabaseAuthRepository - register', () {
    test('signUp passes email, password, and full_name in metadata', () async {
      final user = createTestUser(
        id: 'u-reg',
        email: 'reg@test.com',
        fullName: 'Jane Doe',
      );
      final session = createTestSession(user: user);
      final response = AuthResponse(session: session, user: user);

      when(
        () => mockAuth.signUp(
          email: 'reg@test.com',
          password: 'password123',
          data: {'full_name': 'Jane Doe'},
        ),
      ).thenAnswer((_) async => response);

      final result = await repository.register(
        fullName: 'Jane Doe',
        email: 'reg@test.com',
        password: 'password123',
      );

      verify(
        () => mockAuth.signUp(
          email: 'reg@test.com',
          password: 'password123',
          data: {'full_name': 'Jane Doe'},
        ),
      ).called(1);

      expect(result.user.id, 'u-reg');
      expect(result.user.fullName, 'Jane Doe');
      expect(result.hasActiveSession, isTrue);
      expect(result.requiresEmailConfirmation, isFalse);
    });

    test(
      'signup without active session returns hasActiveSession false',
      () async {
        final user = createTestUser(
          id: 'u-pending',
          email: 'pending@test.com',
          fullName: 'Pending User',
        );
        final response = AuthResponse(session: null, user: user);

        when(
          () => mockAuth.signUp(
            email: 'pending@test.com',
            password: 'password123',
            data: {'full_name': 'Pending User'},
          ),
        ).thenAnswer((_) async => response);

        final result = await repository.register(
          fullName: 'Pending User',
          email: 'pending@test.com',
          password: 'password123',
        );

        expect(result.user.id, 'u-pending');
        expect(result.hasActiveSession, isFalse);
        expect(result.requiresEmailConfirmation, isTrue);
      },
    );

    test('signup with null user throws safe AuthRepositoryException', () async {
      final response = AuthResponse(session: null, user: null);

      when(
        () => mockAuth.signUp(
          email: 'nulluser@test.com',
          password: 'password123',
          data: {'full_name': 'Null User'},
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => repository.register(
          fullName: 'Null User',
          email: 'nulluser@test.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Authentication failed. Please try again.',
          ),
        ),
      );
    });
  });

  group('SupabaseAuthRepository - signOut', () {
    test('invokes Supabase signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('SupabaseAuthRepository - User Mapping', () {
    test('uses full_name from metadata when present and non-empty', () async {
      final user = createTestUser(
        email: 'user@test.com',
        fullName: '  Trimmed Name  ',
      );
      final session = createTestSession(user: user);
      when(() => mockAuth.currentSession).thenReturn(session);

      final result = await repository.getCurrentUser();

      expect(result!.fullName, 'Trimmed Name');
    });

    test(
      'falls back to email local-part when full_name is missing or whitespace',
      () async {
        final userWhitespace = createTestUser(
          email: 'ella.smith@test.com',
          fullName: '   ',
        );
        when(
          () => mockAuth.currentSession,
        ).thenReturn(createTestSession(user: userWhitespace));

        final result1 = await repository.getCurrentUser();
        expect(result1!.fullName, 'ella.smith');

        final userMissing = createTestUser(
          email: 'charlie@test.com',
          fullName: null,
        );
        when(
          () => mockAuth.currentSession,
        ).thenReturn(createTestSession(user: userMissing));

        final result2 = await repository.getCurrentUser();
        expect(result2!.fullName, 'charlie');
      },
    );

    test('maps photo_url when present and non-empty', () async {
      final userWithPhoto = createTestUser(
        photoUrl: 'https://example.com/avatar.jpg',
      );
      when(
        () => mockAuth.currentSession,
      ).thenReturn(createTestSession(user: userWithPhoto));

      final result = await repository.getCurrentUser();
      expect(result!.photoUrl, 'https://example.com/avatar.jpg');
    });

    test('maps photo_url to null when missing or whitespace', () async {
      final userEmptyPhoto = createTestUser(photoUrl: '   ');
      when(
        () => mockAuth.currentSession,
      ).thenReturn(createTestSession(user: userEmptyPhoto));

      final result = await repository.getCurrentUser();
      expect(result!.photoUrl, isNull);
    });

    test(
      'throws AuthRepositoryException when user email is null or empty',
      () async {
        final userNoEmail = createTestUser(email: null);
        when(
          () => mockAuth.currentSession,
        ).thenReturn(createTestSession(user: userNoEmail));

        expect(
          () => repository.getCurrentUser(),
          throwsA(
            isA<AuthRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to read the account email. Please sign in again.',
            ),
          ),
        );
      },
    );
  });

  group('SupabaseAuthRepository - Error Translation', () {
    test('maps invalid_credentials to safe message', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: 'wrong@test.com',
          password: 'wrong',
        ),
      ).thenThrow(
        const AuthException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );

      expect(
        () => repository.signIn(email: 'wrong@test.com', password: 'wrong'),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Incorrect email or password.',
          ),
        ),
      );
    });

    test('maps email_not_confirmed to safe message', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: 'unconfirmed@test.com',
          password: 'password',
        ),
      ).thenThrow(
        const AuthException('Email not confirmed', code: 'email_not_confirmed'),
      );

      expect(
        () => repository.signIn(
          email: 'unconfirmed@test.com',
          password: 'password',
        ),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Please confirm your email before signing in.',
          ),
        ),
      );
    });

    test('maps signup_disabled to safe message', () async {
      when(
        () => mockAuth.signUp(
          email: 'test@test.com',
          password: 'password123',
          data: {'full_name': 'Test'},
        ),
      ).thenThrow(
        const AuthException('Signups not allowed', code: 'signup_disabled'),
      );

      expect(
        () => repository.register(
          fullName: 'Test',
          email: 'test@test.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Account registration is currently unavailable.',
          ),
        ),
      );
    });

    test('maps weak_password to safe message', () async {
      when(
        () => mockAuth.signUp(
          email: 'test@test.com',
          password: '123',
          data: {'full_name': 'Test'},
        ),
      ).thenThrow(
        const AuthException('Password is too weak', code: 'weak_password'),
      );

      expect(
        () => repository.register(
          fullName: 'Test',
          email: 'test@test.com',
          password: '123',
        ),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Password does not meet the required security rules.',
          ),
        ),
      );
    });

    test('maps rate limit error codes to safe messages', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: 'rate@test.com',
          password: 'password',
        ),
      ).thenThrow(
        const AuthException(
          'Too many requests',
          code: 'over_request_rate_limit',
        ),
      );

      expect(
        () => repository.signIn(email: 'rate@test.com', password: 'password'),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Too many attempts. Please try again later.',
          ),
        ),
      );
    });

    test(
      'maps unknown AuthException to generic safe authentication message',
      () async {
        when(() => mockAuth.currentSession).thenThrow(
          const AuthException('Internal gotrue error: DB_CONN_FAIL: 0x9812'),
        );

        expect(
          () => repository.getCurrentUser(),
          throwsA(
            isA<AuthRepositoryException>().having(
              (e) => e.message,
              'message',
              'Authentication failed. Please try again.',
            ),
          ),
        );
      },
    );

    test('maps unexpected Exception to generic safe message', () async {
      when(
        () => mockAuth.signOut(),
      ).thenThrow(Exception('Network socket broken: connection refused'));

      expect(
        () => repository.signOut(),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            'Something went wrong. Please try again.',
          ),
        ),
      );
    });
  });
}

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/auth_repository_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/registration_result.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  final String _googleWebClientId;
  final GoogleSignIn? _googleSignIn;
  final Future<String?> Function()? _googleIdTokenProvider;

  SupabaseAuthRepository({
    required SupabaseClient client,
    String googleWebClientId = '',
    GoogleSignIn? googleSignIn,
    Future<String?> Function()? googleIdTokenProvider,
  }) : _client = client,
       _googleWebClientId = googleWebClientId,
       _googleSignIn = googleSignIn,
       _googleIdTokenProvider = googleIdTokenProvider;

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        return null;
      }
      return _mapUser(session.user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final user = response.user ?? session?.user;

      if (session == null || user == null) {
        throw const AuthRepositoryException(
          'Authentication failed. Please try again.',
        );
      }

      return _mapUser(user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final session = response.session;
      final user = response.user ?? session?.user;

      if (user == null) {
        throw const AuthRepositoryException(
          'Authentication failed. Please try again.',
        );
      }

      final mappedUser = _mapUser(user);
      return RegistrationResult(
        user: mappedUser,
        hasActiveSession: session != null,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final authenticatedUserId = _client.auth.currentUser?.id;
      if (authenticatedUserId == null) {
        throw const AuthRepositoryException(
          'Your session has expired. Please sign in again.',
        );
      }
      final verification = await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      if (verification.session?.user.id != authenticatedUserId ||
          verification.user?.id != authenticatedUserId) {
        throw const AuthRepositoryException(
          'Current password could not be verified.',
        );
      }
      final update = await _client.auth.updateUser(
        UserAttributes(password: newPassword, currentPassword: currentPassword),
      );
      if (update.user?.id != authenticatedUserId) {
        throw const AuthRepositoryException(
          'Password could not be changed. Please try again.',
        );
      }
    } on AuthException catch (error) {
      final code = error.code?.toLowerCase();
      final message = error.message.toLowerCase();
      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        throw const AuthRepositoryException('Current password is incorrect.');
      }
      if (code == 'weak_password' || message.contains('weak password')) {
        throw const AuthRepositoryException(
          'New password does not meet the required security rules.',
        );
      }
      throw const AuthRepositoryException(
        'Password could not be changed. Please try again.',
      );
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Password could not be changed. Please try again.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.smartroute.app://login-callback',
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Unable to send reset email. Please try again.',
      );
    }
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    try {
      final update = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (update.user == null) {
        throw const AuthRepositoryException(
          'Password could not be changed. Please try again.',
        );
      }
    } on AuthException catch (error) {
      final code = error.code?.toLowerCase();
      final message = error.message.toLowerCase();
      if (code == 'weak_password' || message.contains('weak password')) {
        throw const AuthRepositoryException(
          'New password does not meet the required security rules.',
        );
      }
      throw const AuthRepositoryException(
        'Password could not be changed. Please try again.',
      );
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Password could not be changed. Please try again.',
      );
    }
  }

  Future<void>? _googleInitFuture;

  Future<void> _ensureGoogleInitialized(GoogleSignIn signIn) {
    _googleInitFuture ??= () async {
      try {
        await signIn.initialize(
          serverClientId: _googleWebClientId.isNotEmpty
              ? _googleWebClientId
              : null,
        );
      } catch (e) {
        _googleInitFuture = null;
        throw const AuthRepositoryException(
          'Google sign-in initialization failed. Please try again.',
        );
      }
    }();
    return _googleInitFuture!;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      String? idToken;
      if (_googleIdTokenProvider != null) {
        idToken = await _googleIdTokenProvider();
      } else {
        final signIn = _googleSignIn ?? GoogleSignIn.instance;
        await _ensureGoogleInitialized(signIn);
        final account = await signIn.authenticate();
        idToken = account.authentication.idToken;
      }

      if (idToken == null || idToken.isEmpty) {
        throw const AuthRepositoryException(
          'Google authentication was cancelled or returned no token.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final session = response.session;
      final user = response.user ?? session?.user;

      if (user == null) {
        throw const AuthRepositoryException(
          'Authentication failed. Please try again.',
        );
      }

      return _mapUser(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthRepositoryException('Sign in was cancelled.');
      }
      throw AuthRepositoryException(
        'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Something went wrong during Google sign-in. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final signIn = _googleSignIn ?? GoogleSignIn.instance;
      try {
        await signIn.signOut();
      } catch (_) {}
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw const AuthRepositoryException(
        'Something went wrong. Please try again.',
      );
    }
  }

  AppUser _mapUser(User user) {
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw const AuthRepositoryException(
        'Unable to read the account email. Please sign in again.',
      );
    }

    final rawFullName = user.userMetadata?['full_name'];
    final String fullName;
    if (rawFullName is String && rawFullName.trim().isNotEmpty) {
      fullName = rawFullName.trim();
    } else {
      final localPart = email.split('@').first.trim();
      fullName = localPart.isNotEmpty ? localPart : 'SmartRoute User';
    }

    final rawPhotoUrl = user.userMetadata?['photo_url'];
    final String? photoUrl =
        (rawPhotoUrl is String && rawPhotoUrl.trim().isNotEmpty)
        ? rawPhotoUrl.trim()
        : null;

    return AppUser(
      id: user.id,
      fullName: fullName,
      email: email,
      photoUrl: photoUrl,
    );
  }

  AuthRepositoryException _mapAuthException(AuthException e) {
    final code = e.code?.toLowerCase();
    final message = e.message.toLowerCase();

    if (code == 'invalid_credentials') {
      return const AuthRepositoryException('Incorrect email or password.');
    }

    if (code == 'email_not_confirmed') {
      return const AuthRepositoryException(
        'Please confirm your email before signing in.',
      );
    }

    if (code == 'signup_disabled') {
      return const AuthRepositoryException(
        'Account registration is currently unavailable.',
      );
    }

    if (code == 'weak_password') {
      return const AuthRepositoryException(
        'Password does not meet the required security rules.',
      );
    }

    if (code == 'over_email_send_rate_limit') {
      return const AuthRepositoryException(
        'Too many email requests. Please try again later.',
      );
    }

    if (code == 'over_request_rate_limit') {
      return const AuthRepositoryException(
        'Too many attempts. Please try again later.',
      );
    }

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return const AuthRepositoryException('Incorrect email or password.');
    }

    if (message.contains('email not confirmed')) {
      return const AuthRepositoryException(
        'Please confirm your email before signing in.',
      );
    }

    if (message.contains('signup_disabled') ||
        message.contains('signups not allowed')) {
      return const AuthRepositoryException(
        'Account registration is currently unavailable.',
      );
    }

    if (message.contains('weak_password')) {
      return const AuthRepositoryException(
        'Password does not meet the required security rules.',
      );
    }

    if (message.contains('email rate limit') ||
        message.contains('over_email_send_rate_limit')) {
      return const AuthRepositoryException(
        'Too many email requests. Please try again later.',
      );
    }

    if (message.contains('rate limit') ||
        message.contains('too many requests') ||
        message.contains('over_request_rate_limit')) {
      return const AuthRepositoryException(
        'Too many attempts. Please try again later.',
      );
    }

    return const AuthRepositoryException(
      'Authentication failed. Please try again.',
    );
  }
}

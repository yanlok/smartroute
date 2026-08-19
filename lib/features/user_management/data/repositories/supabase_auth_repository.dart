import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/auth_repository_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/registration_result.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({required SupabaseClient client}) : _client = client;

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
  Future<void> signOut() async {
    try {
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

    // 1. Exact stable error codes first
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

    // 2. Narrow message fallbacks (email-specific before generic rate limits)
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

    // 3. Safe fallback
    return const AuthRepositoryException(
      'Authentication failed. Please try again.',
    );
  }
}

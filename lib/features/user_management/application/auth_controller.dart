import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../domain/exceptions/auth_repository_exception.dart';
import '../domain/models/app_user.dart';
import '../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final AuthRepository _authRepository;

  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _requiresEmailConfirmation = false;
  bool _isChangingPassword = false;
  String? _passwordErrorMessage;
  bool _isPasswordRecovery = false;
  bool _isResettingPassword = false;
  String? _resetPasswordErrorMessage;

  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get requiresEmailConfirmation => _requiresEmailConfirmation;
  bool get isChangingPassword => _isChangingPassword;
  String? get passwordErrorMessage => _passwordErrorMessage;
  bool get isPasswordRecovery => _isPasswordRecovery;
  bool get isResettingPassword => _isResettingPassword;
  String? get resetPasswordErrorMessage => _resetPasswordErrorMessage;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearPasswordError() {
    if (_passwordErrorMessage != null) {
      _passwordErrorMessage = null;
      notifyListeners();
    }
  }

  void clearResetPasswordError() {
    if (_resetPasswordErrorMessage != null) {
      _resetPasswordErrorMessage = null;
      notifyListeners();
    }
  }

  void setPasswordRecovery(bool value) {
    if (_isPasswordRecovery != value) {
      _isPasswordRecovery = value;
      notifyListeners();
    }
  }

  void handleAuthChangeEvent(AuthChangeEvent event) {
    switch (event) {
      case AuthChangeEvent.passwordRecovery:
        _isPasswordRecovery = true;
        notifyListeners();
        break;
      case AuthChangeEvent.signedOut:
        _isPasswordRecovery = false;
        _currentUser = null;
        _requiresEmailConfirmation = false;
        notifyListeners();
        break;
      default:
        break;
    }
  }

  Future<bool> checkInitialRecoveryLink({AppLinks? appLinks}) async {
    try {
      final links = appLinks ?? AppLinks();
      final uri = await links.getInitialLink();
      if (uri != null && isRecoveryUri(uri)) {
        _isPasswordRecovery = true;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static bool isRecoveryUri(Uri uri) {
    if (uri.queryParameters['type'] == 'recovery') return true;
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final fragmentParams = Uri.splitQueryString(fragment);
      if (fragmentParams['type'] == 'recovery') return true;
    }
    return uri.toString().contains('type=recovery');
  }

  Future<void> initialize({AppLinks? appLinks}) async {
    if (_isLoading) return;

    _errorMessage = null;
    _requiresEmailConfirmation = false;
    _isLoading = true;
    notifyListeners();

    try {
      await checkInitialRecoveryLink(appLinks: appLinks);
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      _currentUser = null;
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_isLoading) return false;

    _errorMessage = null;
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      _errorMessage = 'Email is required';
      notifyListeners();
      return false;
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Password is required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signIn(
        email: trimmedEmail,
        password: password,
      );
      _requiresEmailConfirmation = false;
      _isPasswordRecovery = false;
      return true;
    } catch (e) {
      _currentUser = null;
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    _errorMessage = null;
    _requiresEmailConfirmation = false;
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty) {
      _errorMessage = 'Full name is required';
      notifyListeners();
      return false;
    }

    if (trimmedName.length < 2) {
      _errorMessage = 'Full name must be at least 2 characters';
      notifyListeners();
      return false;
    }

    if (trimmedEmail.isEmpty) {
      _errorMessage = 'Email is required';
      notifyListeners();
      return false;
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Password is required';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _errorMessage = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authRepository.register(
        fullName: trimmedName,
        email: trimmedEmail,
        password: password,
      );

      if (result.hasActiveSession) {
        _currentUser = result.user;
        _requiresEmailConfirmation = false;
      } else {
        _currentUser = null;
        _requiresEmailConfirmation = true;
      }
      _isPasswordRecovery = false;
      return true;
    } catch (e) {
      _currentUser = null;
      _requiresEmailConfirmation = false;
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (_isLoading) return false;

    _errorMessage = null;
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      _errorMessage = 'Email is required';
      notifyListeners();
      return false;
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.sendPasswordResetEmail(trimmedEmail);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_isResettingPassword) return false;

    _resetPasswordErrorMessage = null;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _resetPasswordErrorMessage = 'All password fields are required.';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 8) {
      _resetPasswordErrorMessage =
          'New password must be at least 8 characters.';
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      _resetPasswordErrorMessage = 'New passwords do not match.';
      notifyListeners();
      return false;
    }

    _isResettingPassword = true;
    notifyListeners();

    try {
      await _authRepository.resetPassword(newPassword: newPassword);
      await _authRepository.signOut();
      _currentUser = null;
      _isPasswordRecovery = false;
      return true;
    } catch (error) {
      _resetPasswordErrorMessage = _cleanErrorMessage(error);
      return false;
    } finally {
      _isResettingPassword = false;
      notifyListeners();
    }
  }

  Future<void> cancelPasswordRecovery() async {
    _isPasswordRecovery = false;
    _resetPasswordErrorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _requiresEmailConfirmation = false;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInWithGoogle();
      _requiresEmailConfirmation = false;
      _isPasswordRecovery = false;
      return true;
    } catch (e) {
      _currentUser = null;
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isLoading) return;

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _requiresEmailConfirmation = false;
      _isPasswordRecovery = false;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_isChangingPassword) return false;
    _passwordErrorMessage = null;
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _passwordErrorMessage = 'All password fields are required.';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 8) {
      _passwordErrorMessage = 'New password must be at least 8 characters.';
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      _passwordErrorMessage = 'New passwords do not match.';
      notifyListeners();
      return false;
    }
    if (newPassword == currentPassword) {
      _passwordErrorMessage =
          'New password must be different from your current password.';
      notifyListeners();
      return false;
    }

    _isChangingPassword = true;
    notifyListeners();
    try {
      await _authRepository.changePassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (error) {
      _passwordErrorMessage = _cleanErrorMessage(error);
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object error) {
    if (error is AuthRepositoryException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}

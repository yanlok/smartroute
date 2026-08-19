import 'package:flutter/foundation.dart';

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

  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get requiresEmailConfirmation => _requiresEmailConfirmation;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_isLoading) return;

    _errorMessage = null;
    _requiresEmailConfirmation = false;
    _isLoading = true;
    notifyListeners();

    try {
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

  Future<void> signOut() async {
    if (_isLoading) return;

    _errorMessage = null;
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

  String _cleanErrorMessage(Object error) {
    if (error is AuthRepositoryException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}

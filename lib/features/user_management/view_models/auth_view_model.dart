import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final AuthRepository _authRepository;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
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

    if (password.length < 8) {
      _errorMessage = 'Password must be at least 8 characters';
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
      return true;
    } catch (e) {
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
    _errorMessage = null;
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
      _currentUser = await _authRepository.register(
        fullName: trimmedName,
        email: trimmedEmail,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }
}

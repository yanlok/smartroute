import 'package:flutter/foundation.dart';

import '../domain/models/user_role.dart';
import '../domain/repositories/user_role_repository.dart';

class UserRoleController extends ChangeNotifier {
  final UserRoleRepository _repository;
  UserRole? _role;
  bool _isLoading = false;
  String? _errorMessage;

  UserRoleController({required UserRoleRepository repository})
    : _repository = repository;

  UserRole get role => _role ?? UserRole.passenger;
  bool get isAdmin => _role == UserRole.admin;
  bool get isResolved => _role != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<UserRole?> resolveRole(String userId) async {
    if (_isLoading) {
      return _role;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _role = await _repository.getRole(userId);
    } catch (_) {
      _role = null;
      _errorMessage = 'Unable to verify account access. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _role;
  }

  void reset() {
    _role = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

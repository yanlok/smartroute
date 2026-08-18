import '../models/app_user.dart';
import '../models/registration_result.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

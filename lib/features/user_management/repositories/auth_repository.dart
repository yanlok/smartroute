import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

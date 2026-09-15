import '../models/user_role.dart';

abstract class UserRoleRepository {
  Future<UserRole> getRole(String userId);
}

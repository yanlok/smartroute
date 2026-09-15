import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/user_role.dart';
import '../../domain/repositories/user_role_repository.dart';

class SupabaseUserRoleRepository implements UserRoleRepository {
  final SupabaseClient _client;

  const SupabaseUserRoleRepository({required SupabaseClient client})
    : _client = client;

  @override
  Future<UserRole> getRole(String userId) async {
    final row = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
    return UserRole.fromString(row?['role'] as String?);
  }
}

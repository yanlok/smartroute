import '../models/user_preferences.dart';
import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile({required String userId});

  Future<UserPreferences> getPreferences({required String userId});

  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    String? photoUrl,
  });

  Future<UserPreferences> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  });
}

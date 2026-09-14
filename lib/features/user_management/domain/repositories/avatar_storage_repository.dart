import '../models/avatar_upload.dart';

abstract class AvatarStorageRepository {
  Future<String> uploadAvatar({
    required String userId,
    required AvatarUpload image,
  });

  Future<void> removeAvatar({required String userId});
}

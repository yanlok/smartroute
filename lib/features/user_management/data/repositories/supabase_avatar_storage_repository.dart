import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/profile_repository_exception.dart';
import '../../domain/models/avatar_upload.dart';
import '../../domain/repositories/avatar_storage_repository.dart';

class SupabaseAvatarStorageRepository implements AvatarStorageRepository {
  static const bucketName = 'avatars';

  final SupabaseClient _client;

  const SupabaseAvatarStorageRepository({required SupabaseClient client})
    : _client = client;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required AvatarUpload image,
  }) async {
    try {
      final bucket = _client.storage.from(bucketName);
      await _removeExisting(bucket: bucket, userId: userId);
      final extension = image.fileName.split('.').last.toLowerCase();
      final objectPath = '$userId/avatar.$extension';
      await bucket.uploadBinary(
        objectPath,
        image.bytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          contentType: image.mimeType,
          upsert: true,
        ),
      );
      return bucket.getPublicUrl(
        objectPath,
        cacheNonce: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } on StorageException catch (error) {
      throw _storageFailure(error, action: 'uploaded');
    } catch (_) {
      throw const ProfileRepositoryException(
        'Profile photo could not be uploaded. Try again.',
      );
    }
  }

  @override
  Future<void> removeAvatar({required String userId}) async {
    try {
      final bucket = _client.storage.from(bucketName);
      await _removeExisting(bucket: bucket, userId: userId);
    } on StorageException catch (error) {
      throw _storageFailure(error, action: 'removed');
    } catch (_) {
      throw const ProfileRepositoryException(
        'Profile photo could not be removed. Try again.',
      );
    }
  }

  Future<void> _removeExisting({
    required StorageFileApi bucket,
    required String userId,
  }) async {
    final objects = await bucket.list(path: userId);
    final paths = [for (final object in objects) '$userId/${object.name}'];
    if (paths.isNotEmpty) await bucket.remove(paths);
  }

  ProfileRepositoryException _storageFailure(
    StorageException error, {
    required String action,
  }) {
    final message = error.message.toLowerCase();
    if (error.statusCode == '404' || message.contains('bucket not found')) {
      return const ProfileRepositoryException(
        'Profile photos are not available yet. Try again later.',
      );
    }
    return ProfileRepositoryException(
      'Profile photo could not be $action. Try again.',
    );
  }
}

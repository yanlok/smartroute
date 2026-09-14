import 'dart:typed_data';

class AvatarUpload {
  final Uint8List bytes;
  final String fileName;
  final String? mimeType;

  const AvatarUpload({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });
}

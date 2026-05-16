import 'dart:typed_data';

abstract class StorageRepository {
  Future<String> uploadFile(String path, String localFilePath);
  Future<String> uploadBytes(String path, Uint8List bytes);
  Future<void> deleteFile(String path);
}

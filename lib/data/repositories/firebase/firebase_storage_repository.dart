import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:unshelf_seller/data/repositories/storage_repository.dart';

// There is no dedicated `storage_service.dart` in lib/services. The seller
// currently calls `FirebaseStorage.instance.ref().child(...).putData(...)`
// inline from a handful of viewmodels (store_profile, product, bundle).
// This repository centralizes those calls; Task 3.5 (service refactor) will
// route viewmodel callers through this repository.
class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> uploadFile(String path, String localFilePath) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(File(localFilePath));
    return ref.getDownloadURL();
  }

  @override
  Future<String> uploadBytes(String path, Uint8List bytes) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile(String path) => _storage.ref().child(path).delete();
}

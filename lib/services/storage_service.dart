import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling cloud and local storage operations
class StorageService {
  StorageService({
    FirebaseStorage? storage,
    FlutterSecureStorage? secureStorage,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();
  final FirebaseStorage _storage;
  final FlutterSecureStorage _secureStorage;

  // Cloud Storage Operations
  Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<bool> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Local Storage Operations
  Future<String> saveLocally(File file, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename';
    await file.copy(path);
    return path;
  }

  Future<bool> deleteLocal(String path) async {
    try {
      final file = File(path);
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Secure Storage Operations
  Future<void> saveSecure(String key, String value) =>
      _secureStorage.write(key: key, value: value);

  Future<String?> getSecure(String key) => _secureStorage.read(key: key);

  Future<void> deleteSecure(String key) => _secureStorage.delete(key: key);

  Future<void> clearSecureStorage() => _secureStorage.deleteAll();
}

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(
    String localPath,
    String fileName, {
    void Function(double)? onProgress,
  }) async {
    final File file = File(localPath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $localPath');
    }

    // Generate a unique file name if not provided
    final String uniqueFileName =
        fileName.isNotEmpty
            ? fileName
            : '${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}';

    // Create the storage reference
    final storageRef = _storage.ref().child('images/$uniqueFileName');

    try {
      // Start upload task
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaded': DateTime.now().toIso8601String()},
        ),
      );

      // Listen to upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      await uploadTask;

      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteImage(String cloudPath) async {
    try {
      final storageRef = _storage.refFromURL(cloudPath);
      await storageRef.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}

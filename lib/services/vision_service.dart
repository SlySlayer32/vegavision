import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

/// Service for interfacing with Google Cloud Vision API
class VisionService {
  VisionService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;
  final FirebaseFunctions _functions;

  /// Analyze an image using Cloud Vision API
  Future<Map<String, dynamic>> analyzeImage(File image) async {
    try {
      final callable = _functions.httpsCallable('analyzeImage');
      final result = await callable.call<Map<String, dynamic>>({
        'imagePath': image.path,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      throw VisionServiceException('Failed to analyze image: $e');
    }
  }

  /// Detect objects in an image
  Future<List<Map<String, dynamic>>> detectObjects(File image) async {
    try {
      final callable = _functions.httpsCallable('detectObjects');
      final result = await callable.call<Map<String, dynamic>>({
        'imagePath': image.path,
      });
      final list = result.data as List;
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      throw VisionServiceException('Failed to detect objects: $e');
    }
  }

  /// Get image labels
  Future<List<String>> getLabels(File image) async {
    try {
      final callable = _functions.httpsCallable('getLabels');
      final result = await callable.call<Map<String, dynamic>>({
        'imagePath': image.path,
      });
      final list = result.data as List;
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      throw VisionServiceException('Failed to get labels: $e');
    }
  }
}

/// Exception thrown when Vision API operations fail
class VisionServiceException implements Exception {
  VisionServiceException(this.message);
  final String message;

  @override
  String toString() => 'VisionServiceException: $message';
}

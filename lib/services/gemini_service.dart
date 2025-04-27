import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';

/// Service for interfacing with Google Gemini API for image editing
class GeminiService {
  GeminiService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;
  final FirebaseFunctions _functions;

  /// Process an edit request using Gemini API
  Future<EditResult> processEditRequest(EditRequest request, File image) async {
    try {
      final callable = _functions.httpsCallable('processImageEdit');
      final result = await callable.call<Map<String, dynamic>>({
        'requestId': request.id,
        'imageId': request.imageId,
        'instruction': request.instruction,
        'markers': request.markers?.map((m) => m.toJson()).toList(),
        'imagePath': image.path,
      });

      return EditResult.fromJson(Map<String, dynamic>.from(result.data as Map));
    } catch (e) {
      return EditResult.failed(
        requestId: request.id,
        imageId: request.imageId,
        errorMessage: 'Failed to process edit request: $e',
      );
    }
  }

  /// Get edit suggestions for an image
  Future<List<String>> getSuggestions(File image) async {
    try {
      final callable = _functions.httpsCallable('getEditSuggestions');
      final result = await callable.call<Map<String, dynamic>>({
        'imagePath': image.path,
      });
      final list = result.data as List;
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      throw GeminiServiceException('Failed to get suggestions: $e');
    }
  }

  /// Estimate processing time for an edit request
  Future<int> estimateProcessingTime(EditRequest request) async {
    try {
      final callable = _functions.httpsCallable('estimateProcessingTime');
      final result = await callable.call<Map<String, dynamic>>(
        request.toJson(),
      );
      final data = result.data as Map;
      return data['estimatedSeconds'] as int;
    } catch (e) {
      throw GeminiServiceException('Failed to estimate processing time: $e');
    }
  }
}

/// Exception thrown when Gemini API operations fail
class GeminiServiceException implements Exception {
  GeminiServiceException(this.message);
  final String message;

  @override
  String toString() => 'GeminiServiceException: $message';
}

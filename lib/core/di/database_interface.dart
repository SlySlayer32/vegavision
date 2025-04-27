import 'package:flutter/foundation.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';
import 'package:vegavision/models/image_model.dart';

/// Abstract interface for database operations
abstract class Database {
  /// Initialize the database
  Future<void> initialize();

  /// Close the database connection
  Future<void> close();

  /// Clear all data from the database
  Future<void> clear();

  /// Check if the database is ready
  @protected
  bool get isReady;

  // Image operations
  Future<void> saveImage(ImageModel image);
  Future<List<ImageModel>> getImages();
  Future<ImageModel?> getImage(String id);
  Future<void> updateImage(ImageModel image);
  Future<bool> deleteImage(String id);

  // Edit request operations
  Future<void> saveEditRequest(EditRequest request);
  Future<List<EditRequest>> getEditRequests({String? imageId});
  Future<EditRequest?> getEditRequest(String id);
  Future<void> updateEditRequest(EditRequest request);
  Future<bool> deleteEditRequest(String id);

  // Edit result operations
  Future<void> saveEditResult(EditResult result);
  Future<List<EditResult>> getEditResults({String? requestId, String? imageId});
  Future<EditResult?> getEditResult(String id);
  Future<bool> deleteEditResult(String id);

  // Batch operations
  Future<void> saveMultipleImages(List<ImageModel> images);
  Future<void> saveMultipleEditRequests(List<EditRequest> requests);
  Future<void> saveMultipleEditResults(List<EditResult> results);

  // Data maintenance
  Future<void> deleteOldData(DateTime olderThan);
  Future<void> cleanupUnusedData();
}

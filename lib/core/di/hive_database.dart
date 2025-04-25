import 'package:hive_flutter/hive_flutter.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';
import 'package:vegavision/models/image_model.dart';

class HiveDatabase implements Database {
  static const String imagesBox = 'images';
  static const String editRequestsBox = 'edit_requests';
  static const String editResultsBox = 'edit_results';

  late Box<Map> _imagesBox;
  late Box<Map> _editRequestsBox;
  late Box<Map> _editResultsBox;

  /// Initializes the Hive boxes for storing data.
  /// Must be called before any other database operations.
  Future<void> initialize() async {
    _imagesBox = await Hive.openBox<Map>(imagesBox);
    _editRequestsBox = await Hive.openBox<Map>(editRequestsBox);
    _editResultsBox = await Hive.openBox<Map>(editResultsBox);
  }

  @override
  /// Saves an [ImageModel] to the Hive box.
  Future<void> saveImage(ImageModel image) async {
    await _imagesBox.put(image.id, image.toJson());
  }

  @override
  /// Retrieves all [ImageModel]s from the Hive box.
  Future<List<ImageModel>> getImages() async {
    return _imagesBox.values
        .map((json) => ImageModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  /// Retrieves a specific [ImageModel] by its [id] from the Hive box.
  /// Returns `null` if not found.
  Future<ImageModel?> getImage(String id) async {
    final json = _imagesBox.get(id);
    if (json == null) return null;
    return ImageModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  /// Updates an existing [ImageModel] in the Hive box.
  Future<void> updateImage(ImageModel image) async {
    await _imagesBox.put(image.id, image.toJson());
  }

  @override
  /// Deletes an [ImageModel] by its [id] from the Hive box.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> deleteImage(String id) async {
    if (!_imagesBox.containsKey(id)) return false;
    await _imagesBox.delete(id);
    return true;
  }

  @override
  /// Saves an [EditRequest] to the Hive box.
  Future<void> saveEditRequest(EditRequest request) async {
    await _editRequestsBox.put(request.id, request.toJson());
  }

  @override
  /// Retrieves [EditRequest]s from the Hive box, optionally filtered by [imageId].
  Future<List<EditRequest>> getEditRequests({String? imageId}) async {
    final requests =
        _editRequestsBox.values
            .map((json) => EditRequest.fromJson(Map<String, dynamic>.from(json)))
            .toList();

    if (imageId != null) {
      return requests.where((request) => request.imageId == imageId).toList();
    }
    return requests;
  }

  @override
  /// Retrieves a specific [EditRequest] by its [id] from the Hive box.
  /// Returns `null` if not found.
  Future<EditRequest?> getEditRequest(String id) async {
    final json = _editRequestsBox.get(id);
    if (json == null) return null;
    return EditRequest.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  /// Updates an existing [EditRequest] in the Hive box.
  Future<void> updateEditRequest(EditRequest request) async {
    await _editRequestsBox.put(request.id, request.toJson());
  }

  @override
  /// Deletes an [EditRequest] by its [id] from the Hive box.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> deleteEditRequest(String id) async {
    if (!_editRequestsBox.containsKey(id)) return false;
    await _editRequestsBox.delete(id);
    return true;
  }

  @override
  /// Saves an [EditResult] to the Hive box.
  Future<void> saveEditResult(EditResult result) async {
    await _editResultsBox.put(result.id, result.toJson());
  }

  @override
  /// Retrieves [EditResult]s from the Hive box, optionally filtered by [requestId] or [imageId].
  Future<List<EditResult>> getEditResults({String? requestId, String? imageId}) async {
    final results =
        _editResultsBox.values
            .map((json) => EditResult.fromJson(Map<String, dynamic>.from(json)))
            .toList();

    return results.where((result) {
      // TODO: These checks assume result.requestId and result.imageId are non-null. Add null checks if necessary.
      if (requestId != null && result.requestId != requestId) return false;
      if (imageId != null && result.imageId != imageId) return false;
      return true;
    }).toList();
  }

  @override
  /// Retrieves a specific [EditResult] by its [id] from the Hive box.
  /// Returns `null` if not found.
  Future<EditResult?> getEditResult(String id) async {
    final json = _editResultsBox.get(id);
    if (json == null) return null;
    return EditResult.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  /// Deletes an [EditResult] by its [id] from the Hive box.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> deleteEditResult(String id) async {
    if (!_editResultsBox.containsKey(id)) return false;
    await _editResultsBox.delete(id);
    return true;
  }

  @override
  /// Saves multiple [ImageModel]s to the Hive box in a single operation.
  Future<void> saveMultipleImages(List<ImageModel> images) async {
    final Map<dynamic, Map<String, dynamic>> entries = {
      for (var image in images) image.id: image.toJson(),
    };
    await _imagesBox.putAll(entries);
  }

  @override
  /// Saves multiple [EditRequest]s to the Hive box in a single operation.
  Future<void> saveMultipleEditRequests(List<EditRequest> requests) async {
    final Map<dynamic, Map<String, dynamic>> entries = {
      for (var request in requests) request.id: request.toJson(),
    };
    await _editRequestsBox.putAll(entries);
  }

  @override
  /// Saves multiple [EditResult]s to the Hive box in a single operation.
  Future<void> saveMultipleEditResults(List<EditResult> results) async {
    final Map<dynamic, Map<String, dynamic>> entries = {
      for (var result in results) result.id: result.toJson(),
    };
    await _editResultsBox.putAll(entries);
  }

  @override
  /// Deletes data older than the specified [olderThan] date from all relevant boxes.
  Future<void> deleteOldData(DateTime olderThan) async {
    try {
      // Delete old images
      final oldImageKeys = _imagesBox.keys.where((key) {
        final json = _imagesBox.get(key);
        final createdAtString = json?['createdAt'] as String?;
        if (createdAtString == null) return false;
        try {
          return DateTime.parse(createdAtString).isBefore(olderThan);
        } catch (e) {
          // Handle potential parsing errors
          print('Error parsing date for image $key: $e');
          return false;
        }
      }).toList(); // Collect keys to avoid concurrent modification issues
      await _imagesBox.deleteAll(oldImageKeys);

      // Delete old edit requests
      final oldRequestKeys = _editRequestsBox.keys.where((key) {
        final json = _editRequestsBox.get(key);
        final createdAtString = json?['createdAt'] as String?;
        if (createdAtString == null) return false;
        try {
          return DateTime.parse(createdAtString).isBefore(olderThan);
        } catch (e) {
          print('Error parsing date for request $key: $e');
          return false;
        }
      }).toList();
      await _editRequestsBox.deleteAll(oldRequestKeys);

      // Delete old results
      final oldResultKeys = _editResultsBox.keys.where((key) {
        final json = _editResultsBox.get(key);
        final createdAtString = json?['createdAt'] as String?;
        if (createdAtString == null) return false;
        try {
          return DateTime.parse(createdAtString).isBefore(olderThan);
        } catch (e) {
          print('Error parsing date for result $key: $e');
          return false;
        }
      }).toList();
      await _editResultsBox.deleteAll(oldResultKeys);
    } catch (e) {
      print('Error during deleteOldData: $e');
      // Consider re-throwing or handling more gracefully
    }
  }

  @override
  /// Performs cleanup operations, removing orphaned edit requests and results.
  Future<void> cleanupUnusedData() async {
    try {
      // Get all image IDs
      final imageIds = _imagesBox.keys.toSet();

      // Cleanup edit requests without corresponding images
      final orphanedRequestKeys = _editRequestsBox.keys.where((key) {
        final json = _editRequestsBox.get(key);
        return !imageIds.contains(json?['imageId']);
      }).toList();
      await _editRequestsBox.deleteAll(orphanedRequestKeys);

      // Cleanup results without corresponding requests
      final requestIds = _editRequestsBox.keys.toSet();
      final orphanedResultKeys = _editResultsBox.keys.where((key) {
        final json = _editResultsBox.get(key);
        return !requestIds.contains(json?['requestId']);
      }).toList();
      await _editResultsBox.deleteAll(orphanedResultKeys);
    } catch (e) {
      print('Error during cleanupUnusedData: $e');
      // Consider re-throwing or handling more gracefully
    }
  }

  /// Closes all opened Hive boxes. Should be called when the database is no longer needed.
  Future<void> dispose() async {
    await _imagesBox.close();
    await _editRequestsBox.close();
    await _editResultsBox.close();
  }
}

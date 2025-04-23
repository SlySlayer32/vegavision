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

  Future<void> initialize() async {
    _imagesBox = await Hive.openBox<Map>(imagesBox);
    _editRequestsBox = await Hive.openBox<Map>(editRequestsBox);
    _editResultsBox = await Hive.openBox<Map>(editResultsBox);
  }

  @override
  Future<void> saveImage(ImageModel image) async {
    await _imagesBox.put(image.id, image.toJson());
  }

  @override
  Future<List<ImageModel>> getImages() async {
    return _imagesBox.values
        .map((json) => ImageModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<ImageModel?> getImage(String id) async {
    final json = _imagesBox.get(id);
    if (json == null) return null;
    return ImageModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<void> updateImage(ImageModel image) async {
    await _imagesBox.put(image.id, image.toJson());
  }

  @override
  Future<bool> deleteImage(String id) async {
    if (!_imagesBox.containsKey(id)) return false;
    await _imagesBox.delete(id);
    return true;
  }

  @override
  Future<void> saveEditRequest(EditRequest request) async {
    await _editRequestsBox.put(request.id, request.toJson());
  }

  @override
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
  Future<EditRequest?> getEditRequest(String id) async {
    final json = _editRequestsBox.get(id);
    if (json == null) return null;
    return EditRequest.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<void> updateEditRequest(EditRequest request) async {
    await _editRequestsBox.put(request.id, request.toJson());
  }

  @override
  Future<bool> deleteEditRequest(String id) async {
    if (!_editRequestsBox.containsKey(id)) return false;
    await _editRequestsBox.delete(id);
    return true;
  }

  @override
  Future<void> saveEditResult(EditResult result) async {
    await _editResultsBox.put(result.id, result.toJson());
  }

  @override
  Future<List<EditResult>> getEditResults({String? requestId, String? imageId}) async {
    final results =
        _editResultsBox.values
            .map((json) => EditResult.fromJson(Map<String, dynamic>.from(json)))
            .toList();

    return results.where((result) {
      if (requestId != null && result.requestId != requestId) return false;
      if (imageId != null && result.imageId != imageId) return false;
      return true;
    }).toList();
  }

  @override
  Future<EditResult?> getEditResult(String id) async {
    final json = _editResultsBox.get(id);
    if (json == null) return null;
    return EditResult.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<bool> deleteEditResult(String id) async {
    if (!_editResultsBox.containsKey(id)) return false;
    await _editResultsBox.delete(id);
    return true;
  }

  @override
  Future<void> saveMultipleImages(List<ImageModel> images) async {
    final Map<dynamic, Map<String, dynamic>> entries = {
      for (var image in images) image.id: image.toJson(),
    };
    await _imagesBox.putAll(entries);
  }

  @override
  Future<void> saveMultipleEditRequests(List<EditRequest> requests) async {
    final Map<dynamic, Map<String, dynamic>> entries = {
      for (var request in requests) request.id: request.toJson(),
    };
    await _editRequestsBox.putAll(entries);
  }

  @override
  Future<void> saveMultipleEditResults(List<EditResult> results) async {
    final Map<dynamic, Map<String, dynamic>> entries = {
      for (var result in results) result.id: result.toJson(),
    };
    await _editResultsBox.putAll(entries);
  }

  @override
  Future<void> deleteOldData(DateTime olderThan) async {
    // Delete old images
    final oldImages = _imagesBox.values.where(
      (json) => DateTime.parse(json['createdAt'] as String).isBefore(olderThan),
    );
    for (final image in oldImages) {
      await _imagesBox.delete(image['id']);
    }

    // Delete old edit requests
    final oldRequests = _editRequestsBox.values.where(
      (json) => DateTime.parse(json['createdAt'] as String).isBefore(olderThan),
    );
    for (final request in oldRequests) {
      await _editRequestsBox.delete(request['id']);
    }

    // Delete old results
    final oldResults = _editResultsBox.values.where(
      (json) => DateTime.parse(json['createdAt'] as String).isBefore(olderThan),
    );
    for (final result in oldResults) {
      await _editResultsBox.delete(result['id']);
    }
  }

  @override
  Future<void> cleanupUnusedData() async {
    // Get all image IDs
    final imageIds = _imagesBox.keys.toSet();

    // Cleanup edit requests without corresponding images
    final orphanedRequests = _editRequestsBox.values.where(
      (json) => !imageIds.contains(json['imageId']),
    );
    for (final request in orphanedRequests) {
      await _editRequestsBox.delete(request['id']);
    }

    // Cleanup results without corresponding requests
    final requestIds = _editRequestsBox.keys.toSet();
    final orphanedResults = _editResultsBox.values.where(
      (json) => !requestIds.contains(json['requestId']),
    );
    for (final result in orphanedResults) {
      await _editResultsBox.delete(result['id']);
    }
  }

  Future<void> dispose() async {
    await _imagesBox.close();
    await _editRequestsBox.close();
    await _editResultsBox.close();
  }
}

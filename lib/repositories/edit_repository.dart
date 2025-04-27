import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';

/// Repository for managing edit requests and results
class EditRepository {
  EditRepository(this._db);
  final Database _db;

  // Edit Request Operations
  Future<void> saveEditRequest(EditRequest request) =>
      _db.saveEditRequest(request);
  Future<List<EditRequest>> getEditRequests({String? imageId}) =>
      _db.getEditRequests(imageId: imageId);
  Future<EditRequest?> getEditRequest(String id) => _db.getEditRequest(id);
  Future<void> updateEditRequest(EditRequest request) =>
      _db.updateEditRequest(request);
  Future<bool> deleteEditRequest(String id) => _db.deleteEditRequest(id);

  // Edit Result Operations
  Future<void> saveEditResult(EditResult result) => _db.saveEditResult(result);
  Future<List<EditResult>> getEditResults({
    String? requestId,
    String? imageId,
  }) => _db.getEditResults(requestId: requestId, imageId: imageId);
  Future<EditResult?> getEditResult(String id) => _db.getEditResult(id);
  Future<bool> deleteEditResult(String id) => _db.deleteEditResult(id);

  // Batch Operations
  Future<void> saveMultipleEditRequests(List<EditRequest> requests) =>
      _db.saveMultipleEditRequests(requests);
  Future<void> saveMultipleEditResults(List<EditResult> results) =>
      _db.saveMultipleEditResults(results);
}

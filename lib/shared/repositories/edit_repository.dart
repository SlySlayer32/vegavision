import 'package:uuid/uuid.dart';
import 'package:vegavision/core/di/database_interface.dart';

import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';

// Filter options for querying edit requests
class EditRequestFilter {
  const EditRequestFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.searchText,
    this.userId,
    this.imageId,
  });
  final EditRequestStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchText;
  final String? userId;
  final String? imageId;
}

// Filter options for querying edit results
class EditResultFilter {
  const EditResultFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.requestId,
    this.imageId,
    this.userId,
  });
  final EditResultStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? requestId;
  final String? imageId;
  final String? userId;
}

// Sort fields for edit requests
enum EditRequestSortField { createdAt, status }

// Sort fields for edit results
enum EditResultSortField { createdAt, processingTimeMs, status }

// Sort direction
enum SortDirection { ascending, descending }

// Result of a paginated query
class PaginatedResult<T> {
  PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
}

// Interface for the repository
abstract class EditRepository {
  // Edit request operations
  Future<EditRequest> createEditRequest(
    String imageId,
    List<Marker> markers,
    String instruction, {
    String? userId,
    Map<String, dynamic>? additionalOptions,
  });

  Future<PaginatedResult<EditRequest>> getEditRequests({
    int page = 1,
    int pageSize = 20,
    EditRequestFilter? filter,
    EditRequestSortField sortField = EditRequestSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
  });

  Future<EditRequest?> getEditRequest(String id);

  Future<void> updateEditRequestStatus(String id, EditRequestStatus status);

  Future<bool> deleteEditRequest(String id);

  // Edit result operations
  Future<EditResult> saveEditResult(
    String requestId,
    String originalImageId,
    String? resultImagePath,
    EditResultStatus status, {
    String? errorMessage,
    int? processingTimeMs,
    Map<String, double>? confidenceScores,
    ProcessingMetrics? metrics,
  });

  Future<PaginatedResult<EditResult>> getEditResults({
    int page = 1,
    int pageSize = 20,
    EditResultFilter? filter,
    EditResultSortField sortField = EditResultSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
  });

  Future<EditResult?> getEditResult(String id);

  Future<List<EditResult>> getEditResultsForRequest(String requestId);

  Future<bool> deleteEditResult(String id);

  // Batch operations
  Future<List<EditRequest>> createMultipleEditRequests(
    List<Map<String, dynamic>> requestData,
  );

  Future<void> updateMultipleEditRequestStatus(
    List<String> ids,
    EditRequestStatus status,
  );

  Future<int> deleteMultipleEditRequests(List<String> ids);

  // Data maintenance
  Future<void> cleanupOldEditRequests(DateTime olderThan);

  Future<void> cleanupFailedEditResults(DateTime olderThan);
}

// Implementation
class EditRepositoryImpl implements EditRepository {
  EditRepositoryImpl(this._database);
  final Database _database;
  final Uuid _uuid = const Uuid();

  @override
  Future<EditRequest> createEditRequest(
    String imageId,
    List<Marker> markers,
    String instruction, {
    String? userId,
    Map<String, dynamic>? additionalOptions,
  }) async {
    final String id = _uuid.v4();

    final EditRequest request = EditRequest(
      id: id,
      imageId: imageId,
      userId: userId,
      markers: markers,
      instruction: instruction,
      createdAt: DateTime.now(),
      additionalOptions: additionalOptions,
    );

    await _database.saveEditRequest(request);
    return request;
  }

  @override
  Future<PaginatedResult<EditRequest>> getEditRequests({
    int page = 1,
    int pageSize = 20,
    EditRequestFilter? filter,
    EditRequestSortField sortField = EditRequestSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
  }) async {
    // In a real implementation, this would be a more sophisticated database query

    // Get all edit requests (simplified implementation)
    List<EditRequest> allRequests = await _database.getEditRequests(
      imageId: filter?.imageId,
      userId: filter?.userId,
    );

    // Apply filters if provided
    if (filter != null) {
      if (filter.status != null) {
        allRequests =
            allRequests
                .where((request) => request.status == filter.status)
                .toList();
      }

      if (filter.startDate != null) {
        allRequests =
            allRequests
                .where(
                  (request) => request.createdAt.isAfter(filter.startDate!),
                )
                .toList();
      }

      if (filter.endDate != null) {
        allRequests =
            allRequests
                .where((request) => request.createdAt.isBefore(filter.endDate!))
                .toList();
      }

      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        final searchLower = filter.searchText!.toLowerCase();
        allRequests =
            allRequests.where((request) {
              return request.instruction.toLowerCase().contains(searchLower);
            }).toList();
      }
    }

    // Apply sorting
    allRequests.sort((a, b) {
      int compareResult;

      switch (sortField) {
        case EditRequestSortField.createdAt:
          compareResult = a.createdAt.compareTo(b.createdAt);
          break;
        case EditRequestSortField.status:
          compareResult = a.status.index.compareTo(b.status.index);
          break;
      }

      // Apply sort direction
      return sortDirection == SortDirection.ascending
          ? compareResult
          : -compareResult;
    });

    // Calculate pagination
    final int total = allRequests.length;
    final int startIndex = (page - 1) * pageSize;
    final int endIndex =
        startIndex + pageSize > total ? total : startIndex + pageSize;

    // Check if there are more pages
    final bool hasMore = endIndex < total;

    // Get the items for the current page
    final List<EditRequest> pageItems =
        startIndex < total ? allRequests.sublist(startIndex, endIndex) : [];

    return PaginatedResult(
      items: pageItems,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }

  @override
  Future<EditRequest?> getEditRequest(String id) async {
    return await _database.getEditRequest(id);
  }

  @override
  Future<void> updateEditRequestStatus(
    String id,
    EditRequestStatus status,
  ) async {
    final request = await _database.getEditRequest(id);
    if (request == null) return;

    final updatedRequest = request.copyWith(status: status);

    await _database.updateEditRequest(updatedRequest);
  }

  @override
  Future<bool> deleteEditRequest(String id) async {
    // Delete any associated results first
    final results = await getEditResultsForRequest(id);

    for (final result in results) {
      await deleteEditResult(result.id);
    }

    // Delete the request
    return await _database.deleteEditRequest(id);
  }

  @override
  Future<EditResult> saveEditResult(
    String requestId,
    String originalImageId,
    String? resultImagePath,
    EditResultStatus status, {
    String? errorMessage,
    int? processingTimeMs,
    Map<String, double>? confidenceScores,
    ProcessingMetrics? metrics,
  }) async {
    final String id = _uuid.v4();

    final EditResult result = EditResult(
      id: id,
      requestId: requestId,
      originalImageId: originalImageId,
      resultImagePath: resultImagePath,
      createdAt: DateTime.now(),
      status: status,
      errorMessage: errorMessage,
      processingTimeMs: processingTimeMs,
      confidenceScores: confidenceScores,
      metrics: metrics,
    );

    await _database.saveEditResult(result);
    return result;
  }

  @override
  Future<PaginatedResult<EditResult>> getEditResults({
    int page = 1,
    int pageSize = 20,
    EditResultFilter? filter,
    EditResultSortField sortField = EditResultSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
  }) async {
    // In a real implementation, this would be a more sophisticated database query

    // Get all edit results (simplified implementation)
    List<EditResult> allResults = await _database.getEditResults(
      requestId: filter?.requestId,
      imageId: filter?.imageId,
    );

    // Apply filters if provided
    if (filter != null) {
      if (filter.status != null) {
        allResults =
            allResults
                .where((result) => result.status == filter.status)
                .toList();
      }

      if (filter.startDate != null) {
        allResults =
            allResults
                .where((result) => result.createdAt.isAfter(filter.startDate!))
                .toList();
      }

      if (filter.endDate != null) {
        allResults =
            allResults
                .where((result) => result.createdAt.isBefore(filter.endDate!))
                .toList();
      }
    }

    // Apply sorting
    allResults.sort((a, b) {
      int compareResult;

      switch (sortField) {
        case EditResultSortField.createdAt:
          compareResult = a.createdAt.compareTo(b.createdAt);
          break;
        case EditResultSortField.processingTimeMs:
          compareResult = (a.processingTimeMs ?? 0).compareTo(
            b.processingTimeMs ?? 0,
          );
          break;
        case EditResultSortField.status:
          compareResult = a.status.index.compareTo(b.status.index);
          break;
      }

      // Apply sort direction
      return sortDirection == SortDirection.ascending
          ? compareResult
          : -compareResult;
    });

    // Calculate pagination
    final int total = allResults.length;
    final int startIndex = (page - 1) * pageSize;
    final int endIndex =
        startIndex + pageSize > total ? total : startIndex + pageSize;

    // Check if there are more pages
    final bool hasMore = endIndex < total;

    // Get the items for the current page
    final List<EditResult> pageItems =
        startIndex < total ? allResults.sublist(startIndex, endIndex) : [];

    return PaginatedResult(
      items: pageItems,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }

  @override
  Future<EditResult?> getEditResult(String id) async {
    return await _database.getEditResult(id);
  }

  @override
  Future<List<EditResult>> getEditResultsForRequest(String requestId) async {
    final allResults = await _database.getEditResults(requestId: requestId);
    return allResults;
  }

  @override
  Future<bool> deleteEditResult(String id) async {
    // In a real implementation, you would also delete the result image file
    return await _database.deleteEditResult(id);
  }

  @override
  Future<List<EditRequest>> createMultipleEditRequests(
    List<Map<String, dynamic>> requestData,
  ) async {
    final List<EditRequest> createdRequests = [];

    for (final data in requestData) {
      try {
        final imageId = data['imageId'] as String;
        final markers = (data['markers'] as List<dynamic>).cast<Marker>();
        final instruction = data['instruction'] as String;
        final userId = data['userId'] as String?;
        final additionalOptions =
            data['additionalOptions'] as Map<String, dynamic>?;

        final request = await createEditRequest(
          imageId,
          markers,
          instruction,
          userId: userId,
          additionalOptions: additionalOptions,
        );

        createdRequests.add(request);
      } catch (e) {
        print('Error creating edit request: $e');
      }
    }

    return createdRequests;
  }

  @override
  Future<void> updateMultipleEditRequestStatus(
    List<String> ids,
    EditRequestStatus status,
  ) async {
    for (final id in ids) {
      try {
        await updateEditRequestStatus(id, status);
      } catch (e) {
        print('Error updating edit request status for $id: $e');
      }
    }
  }

  @override
  Future<int> deleteMultipleEditRequests(List<String> ids) async {
    int deletedCount = 0;

    for (final id in ids) {
      try {
        final result = await deleteEditRequest(id);
        if (result) {
          deletedCount++;
        }
      } catch (e) {
        print('Error deleting edit request $id: $e');
      }
    }

    return deletedCount;
  }

  @override
  Future<void> cleanupOldEditRequests(DateTime olderThan) async {
    // In a real implementation, this would use a database query to find and delete old requests
    final allRequests = await _database.getEditRequests();

    final oldRequestIds =
        allRequests
            .where((request) => request.createdAt.isBefore(olderThan))
            .map((request) => request.id)
            .toList();

    await deleteMultipleEditRequests(oldRequestIds);
  }

  @override
  Future<void> cleanupFailedEditResults(DateTime olderThan) async {
    // In a real implementation, this would use a database query to find and delete old failed results
    final allResults = await _database.getEditResults();

    final failedResultIds =
        allResults
            .where(
              (result) =>
                  result.status == EditResultStatus.failed &&
                  result.createdAt.isBefore(olderThan),
            )
            .map((result) => result.id)
            .toList();

    for (final id in failedResultIds) {
      await deleteEditResult(id);
    }
  }
}

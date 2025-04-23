import 'dart:io';

import 'package:uuid/uuid.dart';

import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/services/storage_service.dart';
// TODO: Add missing import for Database interface
// import '../core/di/database_interface.dart';

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

// TODO: ImageStatus enum is referenced but not defined, need to create this enum
// enum ImageStatus {
//   local,
//   uploading,
//   uploaded,
//   processing,
//   processed,
//   error
// }

// TODO: ImageDimensions class is used but not defined, need to implement this class
// class ImageDimensions {
//   final int width;
//   final int height;
//
//   const ImageDimensions({required this.width, required this.height});
// }

// Filter options for querying images
class ImageFilter {

  const ImageFilter({this.status, this.startDate, this.endDate, this.searchText, this.userId});
  final ImageStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchText;
  final String? userId;
}

// Sort options for querying images
enum ImageSortField { createdAt, fileSize }

// Sort direction
enum SortDirection { ascending, descending }

// Interface for the repository
abstract class ImageRepository {
  // Single image operations
  Future<ImageModel> saveImage(
    String localPath, {
    Map<String, dynamic>? metadata,
    String? mimeType,
  });

  Future<PaginatedResult<ImageModel>> getImages({
    int page = 1,
    int pageSize = 20,
    ImageFilter? filter,
    ImageSortField sortField = ImageSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
  });

  Future<ImageModel?> getImage(String id);

  Future<void> updateImageStatus(String id, ImageStatus status, {String? cloudPath});

  Future<bool> deleteImage(String id);

  // Bulk operations
  Future<List<ImageModel>> saveMultipleImages(List<String> localPaths);

  Future<void> updateMultipleImageStatus(List<String> ids, ImageStatus status, {String? cloudPath});

  Future<int> deleteMultipleImages(List<String> ids);

  // File operations
  Future<File?> getImageFile(String id);

  Future<ImageDimensions?> getImageDimensions(String id);
}

// Implementation
class ImageRepositoryImpl implements ImageRepository {

  ImageRepositoryImpl(this._storageService, this._database);
  final StorageService _storageService;
  final Database _database;
  final Uuid _uuid = const Uuid();

  @override
  Future<ImageModel> saveImage(
    String localPath, {
    Map<String, dynamic>? metadata,
    String? mimeType,
  }) async {
    final String id = _uuid.v4();

    // Get file size
    final File file = File(localPath);
    final int fileSize = await file.length();

    // Get image dimensions (this would use a package like image_size_getter in a real implementation)
    final ImageDimensions dimensions = ImageDimensions(width: 1920, height: 1080);

    // Determine MIME type if not provided
    final String determinedMimeType = mimeType ?? _getMimeTypeFromPath(localPath);

    final ImageModel image = ImageModel(
      id: id,
      localPath: localPath,
      createdAt: DateTime.now(),
      fileSize: fileSize,
      mimeType: determinedMimeType,
      dimensions: dimensions,
      metadata: metadata,
    );

    await _database.saveImage(image);
    return image;
  }

  @override
  Future<PaginatedResult<ImageModel>> getImages({
    int page = 1,
    int pageSize = 20,
    ImageFilter? filter,
    ImageSortField sortField = ImageSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
  }) async {
    // This would typically be implemented with a more sophisticated database query
    // with filtering, sorting, and pagination

    List<ImageModel> allImages = await _database.getImages();

    // Apply filters if provided
    if (filter != null) {
      if (filter.status != null) {
        allImages = allImages.where((image) => image.status == filter.status).toList();
      }

      if (filter.startDate != null) {
        allImages = allImages.where((image) => image.createdAt.isAfter(filter.startDate!)).toList();
      }

      if (filter.endDate != null) {
        allImages = allImages.where((image) => image.createdAt.isBefore(filter.endDate!)).toList();
      }

      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        final searchLower = filter.searchText!.toLowerCase();
        allImages =
            allImages.where((image) {
              // Search in metadata if available
              if (image.metadata != null) {
                for (var value in image.metadata!.values) {
                  if (value is String && value.toLowerCase().contains(searchLower)) {
                    return true;
                  }
                }
              }

              // Search in path
              return image.localPath.toLowerCase().contains(searchLower);
            }).toList();
      }

      if (filter.userId != null) {
        // In a real implementation, this would filter by userId
      }
    }

    // Apply sorting
    allImages.sort((a, b) {
      int compareResult;

      switch (sortField) {
        case ImageSortField.createdAt:
          compareResult = a.createdAt.compareTo(b.createdAt);
          break;
        case ImageSortField.fileSize:
          compareResult = (a.fileSize ?? 0).compareTo(b.fileSize ?? 0);
          break;
      }

      // Apply sort direction
      return sortDirection == SortDirection.ascending ? compareResult : -compareResult;
    });

    // Calculate pagination
    final int total = allImages.length;
    final int startIndex = (page - 1) * pageSize;
    final int endIndex = startIndex + pageSize > total ? total : startIndex + pageSize;

    // Check if there are more pages
    final bool hasMore = endIndex < total;

    // Get the items for the current page
    final List<ImageModel> pageItems =
        startIndex < total ? allImages.sublist(startIndex, endIndex) : [];

    return PaginatedResult(
      items: pageItems,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }

  @override
  Future<ImageModel?> getImage(String id) async {
    return await _database.getImage(id);
  }

  @override
  Future<void> updateImageStatus(String id, ImageStatus status, {String? cloudPath}) async {
    final image = await _database.getImage(id);
    if (image == null) return;

    final updatedImage = image.copyWith(cloudPath: cloudPath ?? image.cloudPath, status: status);

    await _database.updateImage(updatedImage);
  }

  @override
  Future<bool> deleteImage(String id) async {
    final image = await _database.getImage(id);
    if (image == null) return false;

    // Delete from local storage
    try {
      final File localFile = File(image.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    } catch (e) {
      print('Error deleting local file: $e');
    }

    // Delete from cloud storage if uploaded
    if (image.cloudPath != null) {
      try {
        await _storageService.deleteImage(image.cloudPath!);
      } catch (e) {
        print('Error deleting cloud file: $e');
      }
    }

    // Delete from database
    return await _database.deleteImage(id);
  }

  @override
  Future<List<ImageModel>> saveMultipleImages(List<String> localPaths) async {
    final List<ImageModel> savedImages = [];

    for (final localPath in localPaths) {
      try {
        final image = await saveImage(localPath);
        savedImages.add(image);
      } catch (e) {
        print('Error saving image $localPath: $e');
      }
    }

    return savedImages;
  }

  @override
  Future<void> updateMultipleImageStatus(
    List<String> ids,
    ImageStatus status, {
    String? cloudPath,
  }) async {
    for (final id in ids) {
      try {
        await updateImageStatus(id, status, cloudPath: cloudPath);
      } catch (e) {
        print('Error updating image status for $id: $e');
      }
    }
  }

  @override
  Future<int> deleteMultipleImages(List<String> ids) async {
    int deletedCount = 0;

    for (final id in ids) {
      try {
        final result = await deleteImage(id);
        if (result) {
          deletedCount++;
        }
      } catch (e) {
        print('Error deleting image $id: $e');
      }
    }

    return deletedCount;
  }

  @override
  Future<File?> getImageFile(String id) async {
    final image = await _database.getImage(id);
    if (image == null) return null;

    // Check if the local file exists
    final File file = File(image.localPath);
    if (await file.exists()) {
      return file;
    }

    // If local file doesn't exist but we have cloudPath, download it
    if (image.cloudPath != null) {
      try {
        final tempDir = Directory.systemTemp;
        final localPath = '${tempDir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final downloadedFile = await _storageService.downloadImage(image.cloudPath!, localPath);

        // Update the local path in the database
        final updatedImage = image.copyWith(localPath: downloadedFile.path);
        await _database.updateImage(updatedImage);

        return downloadedFile;
      } catch (e) {
        print('Error downloading image from cloud: $e');
        return null;
      }
    }

    return null;
  }

  @override
  Future<ImageDimensions?> getImageDimensions(String id) async {
    final image = await _database.getImage(id);
    if (image == null) return null;

    // If dimensions are already in the model, return them
    if (image.dimensions != null) {
      return image.dimensions;
    }

    // Otherwise, we'd need to calculate them
    // In a real implementation, this would use a package like image_size_getter
    // For now, we'll return a placeholder
    return const ImageDimensions(width: 1920, height: 1080);
  }

  // Helper function to determine MIME type from file path
  String _getMimeTypeFromPath(String path) {
    final String extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}

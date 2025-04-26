import 'dart:io';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:vegavision/core/services/base_api_service.dart';
import 'package:vegavision/core/services/cache_service.dart';
import 'package:vegavision/core/services/connectivity_service.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/models/image_status.dart';
import 'package:vegavision/services/storage_service.dart';

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

// Filter options for querying images
class ImageFilter {
  const ImageFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.searchText,
    this.userId,
  });
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

  Future<void> updateImageStatus(
    String id,
    ImageStatus status, {
    String? cloudPath,
  });

  Future<bool> deleteImage(String id);

  // Bulk operations
  Future<List<ImageModel>> saveMultipleImages(List<String> localPaths);

  Future<void> updateMultipleImageStatus(
    List<String> ids,
    ImageStatus status, {
    String? cloudPath,
  });

  Future<int> deleteMultipleImages(List<String> ids);

  // File operations
  Future<File?> getImageFile(String id);

  Future<ImageDimensions?> getImageDimensions(String id);

  // Sync operations
  Future<void> syncPendingUploads();
}

// Implementation
class ImageRepositoryImpl implements ImageRepository {
  ImageRepositoryImpl({
    required StorageService storageService,
    required Box<ImageModel> database,
    required CacheService cacheService,
    required ConnectivityService connectivityService,
  }) : _storageService = storageService,
       _database = database,
       _cacheService = cacheService,
       _connectivityService = connectivityService {
    // Start listening to connectivity changes
    _connectivityService.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  final StorageService _storageService;
  final Box<ImageModel> _database;
  final CacheService _cacheService;
  final ConnectivityService _connectivityService;
  final _pendingUploads = <String>{};

  void _handleConnectivityChange(bool isConnected) {
    if (isConnected && _pendingUploads.isNotEmpty) {
      syncPendingUploads();
    }
  }

  @override
  Future<ImageModel> saveImage(
    String path, {
    Map<String, dynamic>? metadata,
    String? mimeType,
  }) async {
    final String id = const Uuid().v4();

    // Get file size
    final File file = File(path);
    final int fileSize = await file.length();

    // Determine MIME type if not provided
    final String actualMimeType = mimeType ?? _getMimeTypeFromPath(path);

    final ImageModel image = ImageModel(
      id: id,
      localPath: path,
      createdAt: DateTime.now(),
      fileSize: fileSize,
      mimeType: actualMimeType,
      status: ImageStatus.pending,
      metadata: metadata,
    );

    await _database.put(id, image);

    // Try to upload immediately if online
    if (await _connectivityService.isConnected()) {
      try {
        await _uploadImage(image);
      } catch (e) {
        _pendingUploads.add(id);
      }
    } else {
      _pendingUploads.add(id);
    }

    return image;
  }

  Future<void> _uploadImage(ImageModel image) async {
    try {
      final cloudPath = await _storageService.uploadImage(
        File(image.localPath),
      );
      await updateImageStatus(
        image.id,
        ImageStatus.uploaded,
        cloudPath: cloudPath,
      );
      _pendingUploads.remove(image.id);
    } catch (e) {
      throw ApiException('Failed to upload image: $e');
    }
  }

  @override
  Future<void> updateImageStatus(
    String id,
    ImageStatus status, {
    String? cloudPath,
  }) async {
    final ImageModel? image = _database.get(id);
    if (image == null) return;

    final updatedImage = image.copyWith(
      cloudPath: cloudPath ?? image.cloudPath,
      status: status,
      updatedAt: DateTime.now(),
    );

    await _database.put(id, updatedImage);

    // Update cache
    _cacheService.put('image_$id', updatedImage.toJson());
  }

  @override
  Future<PaginatedResult<ImageModel>> getImages({
    int page = 1,
    int pageSize = 20,
    ImageFilter? filter,
    ImageSortField sortField = ImageSortField.createdAt,
    SortDirection sortDirection = SortDirection.descending,
  }) async {
    // Try to get from cache first
    final cacheKey =
        'images_${page}_$pageSize_${filter?.hashCode}_$sortField_$sortDirection';
    final cachedResult = _cacheService.get<Map<String, dynamic>>(cacheKey);

    if (cachedResult != null) {
      return PaginatedResult.fromJson(cachedResult);
    }

    List<ImageModel> allImages = _database.values.toList();

    // Apply filters
    if (filter != null) {
      allImages = _applyFilters(allImages, filter);
    }

    // Apply sorting
    _sortImages(allImages, sortField, sortDirection);

    // Calculate pagination
    final PaginatedResult<ImageModel> result = _paginateResults(
      allImages,
      page,
      pageSize,
    );

    // Cache the result
    _cacheService.put(cacheKey, result.toJson());

    return result;
  }

  List<ImageModel> _applyFilters(List<ImageModel> images, ImageFilter filter) {
    return images.where((image) {
      if (filter.status != null && image.status != filter.status) {
        return false;
      }

      if (filter.startDate != null &&
          image.createdAt.isBefore(filter.startDate!)) {
        return false;
      }

      if (filter.endDate != null && image.createdAt.isAfter(filter.endDate!)) {
        return false;
      }

      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        final searchLower = filter.searchText!.toLowerCase();

        // Search in metadata
        if (image.metadata != null) {
          for (var value in image.metadata!.values) {
            if (value is String && value.toLowerCase().contains(searchLower)) {
              return true;
            }
          }
        }

        // Search in path
        return image.localPath.toLowerCase().contains(searchLower);
      }

      if (filter.userId != null && image.metadata?['userId'] != filter.userId) {
        return false;
      }

      return true;
    }).toList();
  }

  void _sortImages(
    List<ImageModel> images,
    ImageSortField field,
    SortDirection direction,
  ) {
    images.sort((a, b) {
      int compareResult;

      switch (field) {
        case ImageSortField.createdAt:
          compareResult = a.createdAt.compareTo(b.createdAt);
          break;
        case ImageSortField.fileSize:
          compareResult = (a.fileSize ?? 0).compareTo(b.fileSize ?? 0);
          break;
      }

      return direction == SortDirection.ascending
          ? compareResult
          : -compareResult;
    });
  }

  PaginatedResult<ImageModel> _paginateResults(
    List<ImageModel> images,
    int page,
    int pageSize,
  ) {
    final int total = images.length;
    final int startIndex = (page - 1) * pageSize;
    final int endIndex =
        startIndex + pageSize > total ? total : startIndex + pageSize;

    return PaginatedResult(
      items: startIndex < total ? images.sublist(startIndex, endIndex) : [],
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: endIndex < total,
    );
  }

  @override
  Future<ImageModel?> getImage(String id) async {
    // Try cache first
    final cachedImage = _cacheService.get<Map<String, dynamic>>('image_$id');
    if (cachedImage != null) {
      return ImageModel.fromJson(cachedImage);
    }

    final image = _database.get(id);
    if (image != null) {
      // Update cache
      _cacheService.put('image_$id', image.toJson());
    }

    return image;
  }

  @override
  Future<bool> deleteImage(String id) async {
    final ImageModel? image = _database.get(id);
    if (image == null) return false;

    try {
      // Delete local file
      final File localFile = File(image.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Delete from cloud if uploaded
      if (image.cloudPath != null) {
        await _storageService.deleteImage(image.cloudPath!);
      }

      // Delete from database and cache
      await _database.delete(id);
      await _cacheService.delete('image_$id');
      _pendingUploads.remove(id);

      return true;
    } catch (e) {
      throw ApiException('Failed to delete image: $e');
    }
  }

  @override
  Future<List<ImageModel>> saveMultipleImages(List<String> localPaths) async {
    final List<ImageModel> savedImages = [];

    for (final path in localPaths) {
      try {
        final image = await saveImage(path);
        savedImages.add(image);
      } catch (e) {
        throw ApiException('Failed to save image $path: $e');
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
        throw ApiException('Failed to update status for image $id: $e');
      }
    }
  }

  @override
  Future<int> deleteMultipleImages(List<String> ids) async {
    int deletedCount = 0;

    for (final id in ids) {
      try {
        final success = await deleteImage(id);
        if (success) deletedCount++;
      } catch (e) {
        throw ApiException('Failed to delete image $id: $e');
      }
    }

    return deletedCount;
  }

  @override
  Future<File?> getImageFile(String id) async {
    final ImageModel? image = await getImage(id);
    if (image == null) return null;

    // Check local file
    final File file = File(image.localPath);
    if (await file.exists()) {
      return file;
    }

    // If not local but in cloud, download
    if (image.cloudPath != null && await _connectivityService.isConnected()) {
      try {
        final tempDir = Directory.systemTemp;
        final localPath =
            '${tempDir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final downloadedFile = await _storageService.downloadImage(
          image.cloudPath!,
          localPath,
        );

        // Update local path
        final updatedImage = image.copyWith(localPath: downloadedFile.path);
        await _database.put(id, updatedImage);
        _cacheService.put('image_$id', updatedImage.toJson());

        return downloadedFile;
      } catch (e) {
        throw ApiException('Failed to download image: $e');
      }
    }

    return null;
  }

  @override
  Future<ImageDimensions?> getImageDimensions(String id) async {
    final ImageModel? image = await getImage(id);
    if (image == null) return null;

    if (image.dimensions != null) {
      return image.dimensions;
    }

    try {
      final file = await getImageFile(id);
      if (file == null) return null;

      // In a real implementation, use image package to get dimensions
      return const ImageDimensions(width: 1920, height: 1080);
    } catch (e) {
      throw ApiException('Failed to get image dimensions: $e');
    }
  }

  @override
  Future<void> syncPendingUploads() async {
    if (!await _connectivityService.isConnected() || _pendingUploads.isEmpty) {
      return;
    }

    final pendingIds = List<String>.from(_pendingUploads);
    for (final id in pendingIds) {
      try {
        final image = await getImage(id);
        if (image != null) {
          await _uploadImage(image);
        }
      } catch (e) {
        print('Failed to sync image $id: $e');
      }
    }
  }

  String _getMimeTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();

    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }
}

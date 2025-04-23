import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/repositories/image_repository.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockStorageService mockStorageService;
  late MockDatabase mockDatabase;
  late ImageRepository imageRepository;

  setUp(() {
    mockStorageService = MockStorageService();
    mockDatabase = MockDatabase();
    imageRepository = ImageRepositoryImpl(mockStorageService, mockDatabase);
  });

  group('ImageRepository Tests - Single Operations', () {
    test('saveImage creates and saves image correctly', () async {
      const localPath = '/path/to/image.jpg';

      when(mockDatabase.saveImage(argThat(isNotNull))).thenAnswer((_) async {
        return null;
      });
      when(mockStorageService.getFileSize(localPath)).thenAnswer((_) async => 1024);

      final result = await imageRepository.saveImage(
        localPath,
        metadata: {'source': 'camera'},
        mimeType: 'image/jpeg',
      );

      expect(result.localPath, localPath);
      expect(result.status, ImageStatus.local);
      expect(result.fileSize, 1024);
      expect(result.mimeType, 'image/jpeg');
      verify(mockDatabase.saveImage(argThat(isNotNull))).called(1);
    });

    test('getImages applies filters and pagination correctly', () async {
      final now = DateTime.now();
      final images = [
        ImageModel(
          id: 'image-1',
          localPath: '/path/1.jpg',
          createdAt: now.subtract(const Duration(days: 1)),
          status: ImageStatus.local,
          fileSize: 2048,
        ),
        ImageModel(
          id: 'image-2',
          localPath: '/path/2.jpg',
          createdAt: now,
          status: ImageStatus.uploaded,
          fileSize: 1024,
        ),
      ];

      when(mockDatabase.getImages()).thenAnswer((_) async => images);

      final filter = ImageFilter(
        status: ImageStatus.uploaded,
        startDate: now.subtract(const Duration(hours: 12)),
      );

      final result = await imageRepository.getImages(
        filter: filter,
        sortField: ImageSortField.fileSize,
        sortDirection: SortDirection.ascending,
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, 'image-2');
      expect(result.total, 1);
    });

    test('updateImageStatus updates image correctly', () async {
      final image = ImageModel(
        id: 'image-1',
        localPath: '/path/1.jpg',
        createdAt: DateTime.now(),
        status: ImageStatus.local,
      );

      when(mockDatabase.getImage('image-1')).thenAnswer((_) async => image);
      when(mockDatabase.updateImage(argThat(isNotNull))).thenAnswer((_) async {
        return null;
      });

      await imageRepository.updateImageStatus(
        'image-1',
        ImageStatus.uploaded,
        cloudPath: 'cloud/path.jpg',
      );

      verify(mockDatabase.updateImage(argThat(isNotNull))).called(1);
    });

    test('deleteImage removes both local and cloud files', () async {
      final image = ImageModel(
        id: 'image-1',
        localPath: '/path/1.jpg',
        cloudPath: 'cloud/path.jpg',
        createdAt: DateTime.now(),
        status: ImageStatus.uploaded,
      );

      when(mockDatabase.getImage('image-1')).thenAnswer((_) async => image);
      when(mockStorageService.deleteImage('cloud/path.jpg')).thenAnswer((_) async {
        return null;
      });
      when(mockDatabase.deleteImage('image-1')).thenAnswer((_) async => true);

      final success = await imageRepository.deleteImage('image-1');

      expect(success, true);
      verify(mockStorageService.deleteImage('cloud/path.jpg')).called(1);
      verify(mockDatabase.deleteImage('image-1')).called(1);
    });

    test('getImageFile returns file for valid image', () async {
      final image = ImageModel(id: 'image-1', localPath: '/path/1.jpg', createdAt: DateTime.now());

      when(mockDatabase.getImage('image-1')).thenAnswer((_) async => image);

      final file = await imageRepository.getImageFile('image-1');

      expect(file, isNotNull);
      expect(file?.path, '/path/1.jpg');
    });
  });

  group('ImageRepository Tests - Batch Operations', () {
    test('saveMultipleImages handles errors gracefully', () async {
      final paths = ['/path/1.jpg', '/path/2.jpg'];

      when(mockDatabase.saveImage(argThat(isNotNull))).thenAnswer((_) async {
        return null;
      });
      when(mockStorageService.getFileSize(any)).thenAnswer((_) async => 1024);

      final results = await imageRepository.saveMultipleImages(paths);

      expect(results.length, 2);
      verify(mockDatabase.saveImage(argThat(isNotNull))).called(2);
    });

    test('updateMultipleImageStatus updates all images', () async {
      final ids = ['image-1', 'image-2'];
      final images =
          ids
              .map(
                (id) => ImageModel(
                  id: id,
                  localPath: '/path/$id.jpg',
                  createdAt: DateTime.now(),
                  status: ImageStatus.local,
                ),
              )
              .toList();

      for (var i = 0; i < ids.length; i++) {
        when(mockDatabase.getImage(ids[i])).thenAnswer((_) async => images[i]);
        when(mockDatabase.updateImage(argThat(isNotNull))).thenAnswer((_) async {
          return null;
        });
      }

      await imageRepository.updateMultipleImageStatus(
        ids,
        ImageStatus.uploaded,
        cloudPath: 'cloud/path',
      );

      verify(mockDatabase.updateImage(argThat(isNotNull))).called(2);
    });

    test('deleteMultipleImages returns correct count', () async {
      final ids = ['image-1', 'image-2'];
      final images =
          ids
              .map(
                (id) => ImageModel(id: id, localPath: '/path/$id.jpg', createdAt: DateTime.now()),
              )
              .toList();

      for (var i = 0; i < ids.length; i++) {
        when(mockDatabase.getImage(ids[i])).thenAnswer((_) async => images[i]);
        when(mockDatabase.deleteImage(ids[i])).thenAnswer((_) async => true);
      }

      final deletedCount = await imageRepository.deleteMultipleImages(ids);

      expect(deletedCount, 2);
      verify(mockDatabase.deleteImage(argThat(isA<String>()))).called(2);
    });
  });
}

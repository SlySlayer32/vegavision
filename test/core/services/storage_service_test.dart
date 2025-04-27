import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/core/services/storage_service.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;
    late MockVisionService mockVisionService;

    setUp(() {
      mockVisionService = MockVisionService();
      storageService = StorageService(mockVisionService);
    });

    test('saveImage should store image and return path', () async {
      // Arrange
      const imageBytes = [1, 2, 3, 4];
      const expectedPath = 'images/test.jpg';
      when(
        mockVisionService.processImage(any),
      ).thenAnswer((_) async => imageBytes);

      // Act
      final result = await storageService.saveImage(imageBytes);

      // Assert
      expect(result, equals(expectedPath));
      verify(mockVisionService.processImage(imageBytes)).called(1);
    });

    test('saveImage should handle errors', () async {
      // Arrange
      const imageBytes = [1, 2, 3, 4];
      when(
        mockVisionService.processImage(any),
      ).thenThrow(Exception('Processing failed'));

      // Act & Assert
      expect(
        () => storageService.saveImage(imageBytes),
        throwsA(isA<Exception>()),
      );
    });

    test('getImage should return image path', () async {
      // Arrange
      const imageId = 'test_id';
      const expectedPath = 'images/test_id.jpg';

      // Act
      final result = await storageService.getImage(imageId);

      // Assert
      expect(result, equals(expectedPath));
    });
  });
}

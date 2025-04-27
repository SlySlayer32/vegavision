import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/features/image_editor/view_models/image_editor_viewmodel.dart';

import '../../../helpers/mocks.mocks.dart';

void main() {
  group('ImageEditorViewModel', () {
    late ImageEditorViewModel viewModel;
    late MockStorageService mockStorageService;
    late MockEditRepository mockEditRepository;

    setUp(() {
      mockStorageService = MockStorageService();
      mockEditRepository = MockEditRepository();
      viewModel = ImageEditorViewModel(mockStorageService, mockEditRepository);
    });

    test('initial state should be idle', () {
      expect(viewModel.state, equals(ViewState.idle));
    });

    test('loadImage should update state correctly', () async {
      // Arrange
      when(
        mockStorageService.getImage(any),
      ).thenAnswer((_) async => 'test_image_path');

      // Act
      await viewModel.loadImage('test_id');

      // Assert
      verify(mockStorageService.getImage('test_id')).called(1);
      expect(viewModel.state, equals(ViewState.success));
      expect(viewModel.imagePath, equals('test_image_path'));
    });

    test('loadImage should handle errors', () async {
      // Arrange
      when(
        mockStorageService.getImage(any),
      ).thenThrow(Exception('Failed to load image'));

      // Act
      await viewModel.loadImage('test_id');

      // Assert
      verify(mockStorageService.getImage('test_id')).called(1);
      expect(viewModel.state, equals(ViewState.error));
      expect(viewModel.errorMessage, isNotEmpty);
    });
  });
}

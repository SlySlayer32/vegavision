import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/viewmodels/image_editor_viewmodel.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockImageRepository mockImageRepository;
  late MockEditRepository mockEditRepository;
  late MockStorageService mockStorageService;
  late ImageEditorViewModel viewModel;

  setUp(() {
    mockImageRepository = MockImageRepository();
    mockEditRepository = MockEditRepository();
    mockStorageService = MockStorageService();
    viewModel = ImageEditorViewModel(
      mockImageRepository,
      mockEditRepository,
      mockStorageService,
    );
  });

  group('ImageEditorViewModel Tests', () {
    test('initial state is correct', () {
      expect(viewModel.isBusy, false);
      expect(viewModel.error, null);
      expect(viewModel.selectedImage, null);
      expect(viewModel.markers, isEmpty);
      expect(viewModel.instruction, isEmpty);
      expect(viewModel.currentMarkerType, MarkerType.remove);
      expect(viewModel.currentMarkerSize, 1.0);
      expect(viewModel.canUndo, false);
      expect(viewModel.canRedo, false);
    });

    test('loadImage loads and sets up image correctly', () async {
      final image = ImageModel(
        id: 'test-1',
        localPath: '/path/to/image.jpg',
        createdAt: DateTime.now(),
      );

      when(
        mockImageRepository.getImage('test-1'),
      ).thenAnswer((_) async => image);
      when(
        mockImageRepository.getImageFile('test-1'),
      ).thenAnswer((_) async => File('/path/to/image.jpg'));

      await viewModel.loadImage('test-1');

      expect(viewModel.selectedImage, image);
      expect(viewModel.error, null);
      expect(viewModel.isBusy, false);
    });

    test('loadImage handles errors correctly', () async {
      when(
        mockImageRepository.getImage('invalid-id'),
      ).thenThrow(Exception('Image not found'));

      await viewModel.loadImage('invalid-id');

      expect(viewModel.error, contains('Failed to load image'));
      expect(viewModel.selectedImage, null);
      expect(viewModel.isBusy, false);
    });

    group('Marker Management', () {
      test('addMarker adds marker correctly', () {
        viewModel.addMarker(0.5, 0.5);

        expect(viewModel.markers.length, 1);
        expect(viewModel.markers.first.x, 0.5);
        expect(viewModel.markers.first.y, 0.5);
        expect(viewModel.markers.first.type, MarkerType.remove);
        expect(viewModel.canUndo, true);
        expect(viewModel.canRedo, false);
      });

      test('removeMarker removes marker correctly', () {
        viewModel.addMarker(0.5, 0.5);
        final markerId = viewModel.markers.first.id;
        viewModel.removeMarker(0);

        expect(viewModel.markers, isEmpty);
        expect(viewModel.canUndo, true);
        expect(viewModel.canRedo, false);

        viewModel.undo();
        expect(viewModel.markers.length, 1);
        expect(viewModel.markers.first.id, markerId);
      });

      test('undo/redo stack works correctly', () {
        viewModel.addMarker(0.5, 0.5); // First marker
        viewModel.addMarker(0.7, 0.7); // Second marker

        expect(viewModel.markers.length, 2);

        viewModel.undo(); // Remove second marker
        expect(viewModel.markers.length, 1);
        expect(viewModel.markers.first.x, 0.5);

        viewModel.redo(); // Add second marker back
        expect(viewModel.markers.length, 2);
        expect(viewModel.markers.last.x, 0.7);
      });

      test('clearMarkers removes all markers', () {
        viewModel.addMarker(0.5, 0.5);
        viewModel.addMarker(0.7, 0.7);
        viewModel.clearMarkers();

        expect(viewModel.markers, isEmpty);
        expect(viewModel.canUndo, true);
        expect(viewModel.canRedo, false);
      });
    });

    group('Edit Request Submission', () {
      test('submitEditRequest validates input correctly', () async {
        final result = await viewModel.submitEditRequest();
        expect(result, null);
        expect(viewModel.error, contains('No image selected'));

        // Load image but no markers
        final image = ImageModel(
          id: 'test-1',
          localPath: '/path/to/image.jpg',
          createdAt: DateTime.now(),
        );
        when(
          mockImageRepository.getImage('test-1'),
        ).thenAnswer((_) async => image);
        await viewModel.loadImage('test-1');

        final result2 = await viewModel.submitEditRequest();
        expect(result2, null);
        expect(viewModel.error, contains('No markers placed'));
      });

      test('submitEditRequest handles successful submission', () async {
        // Setup image
        final image = ImageModel(
          id: 'test-1',
          localPath: '/path/to/image.jpg',
          createdAt: DateTime.now(),
        );
        when(
          mockImageRepository.getImage('test-1'),
        ).thenAnswer((_) async => image);
        await viewModel.loadImage('test-1');

        // Add marker and instruction
        viewModel.addMarker(0.5, 0.5);
        viewModel.setInstruction('Remove the background');

        // Mock cloud upload
        when(
          mockStorageService.uploadImage(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => 'cloud/path.jpg');

        // Mock edit request creation
        final request = EditRequest(
          id: 'request-1',
          imageId: 'test-1',
          markers: viewModel.markers,
          instruction: viewModel.instruction,
          createdAt: DateTime.now(),
        );
        when(
          mockEditRepository.createEditRequest(any, any, any),
        ).thenAnswer((_) async => request);

        final result = await viewModel.submitEditRequest();

        expect(result, isNotNull);
        expect(result?.id, 'request-1');
        expect(viewModel.error, null);
        verify(
          mockStorageService.uploadImage(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).called(1);
        verify(mockEditRepository.createEditRequest(any, any, any)).called(1);
      });

      test('setInstruction validates input', () {
        viewModel.setInstruction('');
        expect(viewModel.instructionError, contains('cannot be empty'));

        viewModel.setInstruction('ab');
        expect(viewModel.instructionError, contains('too short'));

        viewModel.setInstruction('Remove the background');
        expect(viewModel.instructionError, null);
        expect(viewModel.hasValidInstruction, true);
      });
    });
  });
}

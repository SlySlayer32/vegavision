import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/viewmodels/result_viewmodel.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockEditRepository mockEditRepository;
  late MockImageRepository mockImageRepository;
  late MockVisionService mockVisionService;
  late MockGeminiService mockGeminiService;
  late ResultViewModel viewModel;

  setUp(() {
    mockEditRepository = MockEditRepository();
    mockImageRepository = MockImageRepository();
    mockVisionService = MockVisionService();
    mockGeminiService = MockGeminiService();
    viewModel = ResultViewModel(
      mockEditRepository,
      mockImageRepository,
      mockVisionService,
      mockGeminiService,
    );
  });

  group('ResultViewModel Tests', () {
    test('initial state is correct', () {
      expect(viewModel.isBusy, false);
      expect(viewModel.error, null);
      expect(viewModel.editRequest, null);
      expect(viewModel.editResult, null);
      expect(viewModel.originalImage, null);
      expect(viewModel.originalImageFile, null);
      expect(viewModel.resultImageFile, null);
      expect(viewModel.progress.status, ProcessingStatus.notStarted);
    });

    test('loadEditRequest loads request and associated data', () async {
      final request = EditRequest(
        id: 'request-1',
        imageId: 'image-1',
        markers: [],
        instruction: 'test',
        createdAt: DateTime.now(),
      );

      final image = ImageModel(
        id: 'image-1',
        localPath: '/path/to/image.jpg',
        createdAt: DateTime.now(),
      );

      final result = EditResult(
        id: 'result-1',
        requestId: 'request-1',
        originalImageId: 'image-1',
        resultImagePath: '/path/to/result.jpg',
        createdAt: DateTime.now(),
        status: EditResultStatus.completed,
      );

      when(
        mockEditRepository.getEditRequest('request-1'),
      ).thenAnswer((_) async => request);
      when(
        mockImageRepository.getImage('image-1'),
      ).thenAnswer((_) async => image);
      when(
        mockEditRepository.getEditResultsForRequest('request-1'),
      ).thenAnswer((_) async => [result]);

      await viewModel.loadEditRequest('request-1');

      expect(viewModel.editRequest, request);
      expect(viewModel.originalImage, image);
      expect(viewModel.editResult, result);
      expect(viewModel.error, null);
    });

    test('loadEditRequest handles errors', () async {
      when(
        mockEditRepository.getEditRequest('invalid-id'),
      ).thenThrow(Exception('Failed to load'));

      await viewModel.loadEditRequest('invalid-id');

      expect(viewModel.error, contains('Failed to load'));
      expect(viewModel.editRequest, null);
    });

    test('processEditRequest with direct API processes successfully', () async {
      // Setup initial state
      final request = EditRequest(
        id: 'request-1',
        imageId: 'image-1',
        markers: [],
        instruction: 'test',
        createdAt: DateTime.now(),
      );

      final image = ImageModel(
        id: 'image-1',
        localPath: '/path/to/image.jpg',
        cloudPath: 'cloud/path.jpg',
        createdAt: DateTime.now(),
      );

      viewModel = ResultViewModel(
        mockEditRepository,
        mockImageRepository,
        mockVisionService,
        mockGeminiService,
      );

      // Set up the request and image
      when(
        mockEditRepository.getEditRequest('request-1'),
      ).thenAnswer((_) async => request);
      when(
        mockImageRepository.getImage('image-1'),
      ).thenAnswer((_) async => image);

      // Mock the processing steps
      when(
        mockVisionService.analyzeImage(any, options: anyNamed('options')),
      ).thenAnswer((_) async => {'analysis': 'data'});
      when(
        mockGeminiService.editImage(any, any, any),
      ).thenAnswer((_) async => '/path/to/result.jpg');

      // Load the request first
      await viewModel.loadEditRequest('request-1');

      // Process with direct API
      viewModel.setProcessingMethod(ProcessingMethod.directApi);
      await viewModel.processEditRequest();

      expect(viewModel.editResult?.status, EditResultStatus.completed);
      expect(viewModel.progress.status, ProcessingStatus.completed);
      expect(viewModel.error, null);
    });

    test('processEditRequest handles cancellation', () async {
      // Setup initial state with a request and image
      final request = EditRequest(
        id: 'request-1',
        imageId: 'image-1',
        markers: [],
        instruction: 'test',
        createdAt: DateTime.now(),
      );

      final image = ImageModel(
        id: 'image-1',
        localPath: '/path/to/image.jpg',
        cloudPath: 'cloud/path.jpg',
        createdAt: DateTime.now(),
      );

      when(
        mockEditRepository.getEditRequest('request-1'),
      ).thenAnswer((_) async => request);
      when(
        mockImageRepository.getImage('image-1'),
      ).thenAnswer((_) async => image);

      // Load the request
      await viewModel.loadEditRequest('request-1');

      // Start processing and cancel immediately
      viewModel.setProcessingMethod(ProcessingMethod.directApi);
      final processPromise = viewModel.processEditRequest();
      viewModel.cancelProcessing();
      await processPromise;

      expect(viewModel.editResult?.status, EditResultStatus.failed);
      expect(viewModel.error, contains('cancelled'));
    });

    test('mock result processing works correctly', () async {
      // Setup initial state
      final request = EditRequest(
        id: 'request-1',
        imageId: 'image-1',
        markers: [],
        instruction: 'test',
        createdAt: DateTime.now(),
      );

      final image = ImageModel(
        id: 'image-1',
        localPath: '/path/to/image.jpg',
        createdAt: DateTime.now(),
      );

      when(
        mockEditRepository.getEditRequest('request-1'),
      ).thenAnswer((_) async => request);
      when(
        mockImageRepository.getImage('image-1'),
      ).thenAnswer((_) async => image);

      await viewModel.loadEditRequest('request-1');

      viewModel.setProcessingMethod(ProcessingMethod.mockResult);
      await viewModel.processEditRequest();

      expect(viewModel.editResult?.status, EditResultStatus.completed);
      expect(viewModel.progress.status, ProcessingStatus.completed);
      expect(viewModel.progress.progress, 1.0);
    });
  });
}

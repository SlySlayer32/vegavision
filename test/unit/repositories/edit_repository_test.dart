import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';
import 'package:vegavision/repositories/edit_repository.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockDatabase mockDatabase;
  late EditRepository editRepository;

  setUp(() {
    mockDatabase = MockDatabase();
    editRepository = EditRepositoryImpl(mockDatabase);
  });

  group('EditRepository Tests - Edit Requests', () {
    test('createEditRequest creates and saves request correctly', () async {
      final markers = [Marker(id: 'marker-1', x: 0.5, y: 0.5, type: MarkerType.remove)];

      when(mockDatabase.saveEditRequest(argThat(isNotNull))).thenAnswer((_) async {
        return null;
      });

      final result = await editRepository.createEditRequest(
        'image-1',
        markers,
        'Remove background',
        userId: 'user-1',
      );

      expect(result.imageId, 'image-1');
      expect(result.markers, markers);
      expect(result.instruction, 'Remove background');
      expect(result.userId, 'user-1');
      expect(result.status, EditRequestStatus.pending);
      verify(mockDatabase.saveEditRequest(argThat(isNotNull))).called(1);
    });

    test('getEditRequests applies filters correctly', () async {
      final now = DateTime.now();
      final requests = [
        EditRequest(
          id: 'request-1',
          imageId: 'image-1',
          markers: [],
          instruction: 'test',
          createdAt: now.subtract(const Duration(days: 1)),
          status: EditRequestStatus.pending,
        ),
        EditRequest(
          id: 'request-2',
          imageId: 'image-2',
          markers: [],
          instruction: 'test',
          createdAt: now,
          status: EditRequestStatus.completed,
        ),
      ];

      when(mockDatabase.getEditRequests()).thenAnswer((_) async => requests);

      final filter = EditRequestFilter(
        status: EditRequestStatus.completed,
        startDate: now.subtract(const Duration(hours: 12)),
      );

      final result = await editRepository.getEditRequests(
        filter: filter,
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, 'request-2');
      expect(result.total, 1);
    });

    test('updateEditRequestStatus updates status correctly', () async {
      final request = EditRequest(
        id: 'request-1',
        imageId: 'image-1',
        markers: [],
        instruction: 'test',
        createdAt: DateTime.now(),
      );

      when(mockDatabase.getEditRequest('request-1')).thenAnswer((_) async => request);
      when(mockDatabase.updateEditRequest(argThat(isNotNull))).thenAnswer((_) async {
        return null;
      });

      await editRepository.updateEditRequestStatus('request-1', EditRequestStatus.inProgress);

      verify(mockDatabase.updateEditRequest(argThat(isNotNull))).called(1);
    });

    test('deleteEditRequest removes request and associated results', () async {
      final request = EditRequest(
        id: 'request-1',
        imageId: 'image-1',
        markers: [],
        instruction: 'test',
        createdAt: DateTime.now(),
      );

      final results = [
        EditResult(
          id: 'result-1',
          requestId: 'request-1',
          originalImageId: 'image-1',
          createdAt: DateTime.now(),
        ),
      ];

      when(mockDatabase.getEditRequest('request-1')).thenAnswer((_) async => request);
      when(mockDatabase.getEditResults(requestId: 'request-1')).thenAnswer((_) async => results);
      when(mockDatabase.deleteEditResult('result-1')).thenAnswer((_) async => true);
      when(mockDatabase.deleteEditRequest('request-1')).thenAnswer((_) async => true);

      final success = await editRepository.deleteEditRequest('request-1');

      expect(success, true);
      verify(mockDatabase.deleteEditResult('result-1')).called(1);
      verify(mockDatabase.deleteEditRequest('request-1')).called(1);
    });
  });

  group('EditRepository Tests - Edit Results', () {
    test('saveEditResult creates and saves result correctly', () async {
      when(mockDatabase.saveEditResult(argThat(isNotNull))).thenAnswer((_) async {
        return null;
      });

      final result = await editRepository.saveEditResult(
        'request-1',
        'image-1',
        '/path/to/result.jpg',
        EditResultStatus.completed,
        processingTimeMs: 1000,
        confidenceScores: {'quality': 0.95},
      );

      expect(result.requestId, 'request-1');
      expect(result.originalImageId, 'image-1');
      expect(result.resultImagePath, '/path/to/result.jpg');
      expect(result.status, EditResultStatus.completed);
      expect(result.processingTimeMs, 1000);
      expect(result.confidenceScores?['quality'], 0.95);
      verify(mockDatabase.saveEditResult(argThat(isNotNull))).called(1);
    });

    test('getEditResults applies filters and sorting correctly', () async {
      final now = DateTime.now();
      final results = [
        EditResult(
          id: 'result-1',
          requestId: 'request-1',
          originalImageId: 'image-1',
          createdAt: now.subtract(const Duration(days: 1)),
          status: EditResultStatus.completed,
          processingTimeMs: 2000,
        ),
        EditResult(
          id: 'result-2',
          requestId: 'request-2',
          originalImageId: 'image-2',
          createdAt: now,
          status: EditResultStatus.completed,
          processingTimeMs: 1000,
        ),
      ];

      when(mockDatabase.getEditResults()).thenAnswer((_) async => results);

      final filter = EditResultFilter(
        status: EditResultStatus.completed,
        startDate: now.subtract(const Duration(hours: 12)),
      );

      final result = await editRepository.getEditResults(
        filter: filter,
        sortField: EditResultSortField.processingTimeMs,
        sortDirection: SortDirection.ascending,
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, 'result-2');
      expect(result.total, 1);
    });

    test('cleanupFailedEditResults removes old failed results', () async {
      final now = DateTime.now();
      final results = [
        EditResult(
          id: 'result-1',
          requestId: 'request-1',
          originalImageId: 'image-1',
          createdAt: now.subtract(const Duration(days: 2)),
          status: EditResultStatus.failed,
        ),
        EditResult(
          id: 'result-2',
          requestId: 'request-2',
          originalImageId: 'image-2',
          createdAt: now,
          status: EditResultStatus.failed,
        ),
      ];

      when(mockDatabase.getEditResults()).thenAnswer((_) async => results);
      when(mockDatabase.deleteEditResult('result-1')).thenAnswer((_) async => true);

      await editRepository.cleanupFailedEditResults(now.subtract(const Duration(days: 1)));

      verify(mockDatabase.deleteEditResult('result-1')).called(1);
      verifyNever(mockDatabase.deleteEditResult('result-2'));
    });
  });

  group('EditRepository Tests - Batch Operations', () {
    test('createMultipleEditRequests handles errors gracefully', () async {
      final requestData = [
        {'imageId': 'image-1', 'markers': <Marker>[], 'instruction': 'test1', 'userId': 'user-1'},
        {'imageId': 'image-2', 'markers': <Marker>[], 'instruction': 'test2', 'userId': 'user-1'},
      ];

      when(mockDatabase.saveEditRequest(argThat(isNotNull))).thenAnswer((_) async {
        return null;
      });

      final results = await editRepository.createMultipleEditRequests(requestData);

      expect(results.length, 2);
      verify(mockDatabase.saveEditRequest(argThat(isNotNull))).called(2);
    });

    test('updateMultipleEditRequestStatus updates all requests', () async {
      final ids = ['request-1', 'request-2'];
      final requests =
          ids
              .map(
                (id) => EditRequest(
                  id: id,
                  imageId: 'image-1',
                  markers: [],
                  instruction: 'test',
                  createdAt: DateTime.now(),
                ),
              )
              .toList();

      for (var i = 0; i < ids.length; i++) {
        when(mockDatabase.getEditRequest(ids[i])).thenAnswer((_) async => requests[i]);
        when(mockDatabase.updateEditRequest(argThat(isNotNull))).thenAnswer((_) async {
          return null;
        });
      }

      await editRepository.updateMultipleEditRequestStatus(ids, EditRequestStatus.completed);

      verify(mockDatabase.updateEditRequest(argThat(isNotNull))).called(2);
    });
  });
}

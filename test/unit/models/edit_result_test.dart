import 'package:flutter_test/flutter_test.dart';
import 'package:vegavision/models/edit_result.dart';

void main() {
  group('EditResult Tests', () {
    test('should create EditResult with required parameters', () {
      final now = DateTime.now();
      final result = EditResult(
        id: 'result-1',
        requestId: 'request-1',
        originalImageId: 'image-1',
        createdAt: now,
      );

      expect(result.id, 'result-1');
      expect(result.requestId, 'request-1');
      expect(result.originalImageId, 'image-1');
      expect(result.status, EditResultStatus.pending);
      expect(result.resultImagePath, isNull);
    });

    test('should handle download URL expiration correctly', () {
      final now = DateTime.now();
      final expired = now.subtract(const Duration(hours: 1));
      final notExpired = now.add(const Duration(hours: 1));

      final expiredResult = EditResult(
        id: 'result-1',
        requestId: 'request-1',
        originalImageId: 'image-1',
        createdAt: now,
        downloadUrl: 'https://example.com/image.jpg',
        expiresAt: expired,
      );

      final validResult = EditResult(
        id: 'result-2',
        requestId: 'request-1',
        originalImageId: 'image-1',
        createdAt: now,
        downloadUrl: 'https://example.com/image.jpg',
        expiresAt: notExpired,
      );

      expect(expiredResult.isDownloadUrlExpired, isTrue);
      expect(validResult.isDownloadUrlExpired, isFalse);
    });

    test('ProcessingMetrics should store performance data', () {
      final metrics = ProcessingMetrics(
        visionApiTimeMs: 1000,
        geminiApiTimeMs: 2000,
        preprocessingTimeMs: 500,
        postprocessingTimeMs: 300,
        totalTokensUsed: 1000,
        costEstimate: 0.002,
      );

      expect(metrics.visionApiTimeMs, 1000);
      expect(metrics.geminiApiTimeMs, 2000);
      expect(metrics.preprocessingTimeMs, 500);
      expect(metrics.postprocessingTimeMs, 300);
      expect(metrics.totalTokensUsed, 1000);
      expect(metrics.costEstimate, 0.002);
    });
  });
}

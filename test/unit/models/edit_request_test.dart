import 'package:flutter_test/flutter_test.dart';
import 'package:vegavision/models/edit_request.dart';

void main() {
  group('EditRequest Tests', () {
    test('should create EditRequest with required parameters', () {
      final now = DateTime.now();
      final request = EditRequest(
        id: 'test-id',
        imageId: 'image-1',
        markers: [],
        instruction: 'Remove background',
        createdAt: now,
      );

      expect(request.id, 'test-id');
      expect(request.imageId, 'image-1');
      expect(request.markers, isEmpty);
      expect(request.instruction, 'Remove background');
      expect(request.status, EditRequestStatus.pending);
    });

    test('should create Marker with correct position', () {
      final marker = Marker(
        id: 'marker-1',
        x: 0.5,
        y: 0.5,
        type: MarkerType.remove,
      );

      expect(marker.id, 'marker-1');
      expect(marker.x, 0.5);
      expect(marker.y, 0.5);
      expect(marker.type, MarkerType.remove);
      expect(marker.size, 1.0);
    });

    test('MarkerPosition should convert to Marker correctly', () {
      final position = MarkerPosition(x: 0.3, y: 0.7);
      final marker = position.toMarker(id: 'test-marker');

      expect(marker.id, 'test-marker');
      expect(marker.x, 0.3);
      expect(marker.y, 0.7);
      expect(marker.type, MarkerType.remove);
    });
  });
}

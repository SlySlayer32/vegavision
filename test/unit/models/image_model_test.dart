import 'package:flutter_test/flutter_test.dart';
import 'package:vegavision/models/image_model.dart';

void main() {
  group('ImageModel Tests', () {
    test('should create ImageModel with required parameters', () {
      final model = ImageModel(
        id: 'test-id',
        localPath: '/path/to/image.jpg',
        createdAt: DateTime.now(),
      );

      expect(model.id, 'test-id');
      expect(model.localPath, '/path/to/image.jpg');
      expect(model.status, ImageStatus.local);
    });

    test('copyWith should create new instance with updated values', () {
      final now = DateTime.now();
      final model = ImageModel(id: 'test-id', localPath: '/path/to/image.jpg', createdAt: now);

      final updated = model.copyWith(cloudPath: 'cloud/path.jpg', status: ImageStatus.uploaded);

      expect(updated.id, model.id);
      expect(updated.cloudPath, 'cloud/path.jpg');
      expect(updated.status, ImageStatus.uploaded);
      expect(updated.createdAt, now);
    });
  });
}

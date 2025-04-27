import 'package:flutter_test/flutter_test.dart';
import 'package:vegavision/models/edit_request.dart';

void main() {
  group('EditRequest', () {
    test('fromJson creates correct instance', () {
      // Arrange
      final json = {
        'id': 'test_id',
        'imagePath': 'test/path/image.jpg',
        'markers': [
          {'type': 'remove', 'x': 100, 'y': 100},
        ],
        'timestamp': DateTime(2024).toIso8601String(),
      };

      // Act
      final request = EditRequest.fromJson(json);

      // Assert
      expect(request.id, equals('test_id'));
      expect(request.imagePath, equals('test/path/image.jpg'));
      expect(request.markers.length, equals(1));
      expect(request.timestamp, equals(DateTime(2024)));
    });

    test('toJson creates correct map', () {
      // Arrange
      final request = EditRequest(
        id: 'test_id',
        imagePath: 'test/path/image.jpg',
        markers: [ImageMarker(type: MarkerType.remove, x: 100, y: 100)],
        timestamp: DateTime(2024),
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['id'], equals('test_id'));
      expect(json['imagePath'], equals('test/path/image.jpg'));
      expect(json['markers'], isNotEmpty);
      expect(json['timestamp'], equals(DateTime(2024).toIso8601String()));
    });

    test('copyWith creates new instance with updated values', () {
      // Arrange
      final original = EditRequest(
        id: 'test_id',
        imagePath: 'test/path/image.jpg',
        markers: const [],
        timestamp: DateTime(2024),
      );

      // Act
      final copy = original.copyWith(imagePath: 'new/path/image.jpg');

      // Assert
      expect(copy.id, equals(original.id));
      expect(copy.imagePath, equals('new/path/image.jpg'));
      expect(copy.markers, equals(original.markers));
      expect(copy.timestamp, equals(original.timestamp));
    });
  });
}

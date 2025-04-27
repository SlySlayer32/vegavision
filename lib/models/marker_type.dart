import 'package:flutter/material.dart';

part 'marker_type.g.dart';

/// Types of markers that can be placed on an image for editing
enum MarkerType {
  /// A point marker representing a single point on the image
  point,

  /// A line marker representing a straight line on the image
  line,

  /// A rectangle marker for selecting rectangular areas
  rectangle,

  /// A circle marker for selecting circular areas
  circle,

  /// A freeform polygon marker for selecting arbitrary shapes
  polygon,
}

/// Extension methods for [MarkerType]
extension MarkerTypeExtension on MarkerType {
  /// Get the display name of the marker type
  String get displayName {
    switch (this) {
      case MarkerType.point:
        return 'Point';
      case MarkerType.line:
        return 'Line';
      case MarkerType.rectangle:
        return 'Rectangle';
      case MarkerType.circle:
        return 'Circle';
      case MarkerType.polygon:
        return 'Polygon';
    }
  }

  /// Get the icon for the marker type
  IconData get icon {
    switch (this) {
      case MarkerType.point:
        return Icons.place;
      case MarkerType.line:
        return Icons.show_chart;
      case MarkerType.rectangle:
        return Icons.crop_square;
      case MarkerType.circle:
        return Icons.circle_outlined;
      case MarkerType.polygon:
        return Icons.star_border;
    }
  }

  /// Get the minimum number of points required for this marker type
  int get minPoints {
    switch (this) {
      case MarkerType.point:
        return 1;
      case MarkerType.line:
        return 2;
      case MarkerType.rectangle:
        return 2;
      case MarkerType.circle:
        return 2;
      case MarkerType.polygon:
        return 3;
    }
  }

  /// Get the color associated with this marker type
  Color get color {
    switch (this) {
      case MarkerType.point:
        return Colors.red;
      case MarkerType.line:
        return Colors.blue;
      case MarkerType.rectangle:
        return Colors.green;
      case MarkerType.circle:
        return Colors.orange;
      case MarkerType.polygon:
        return Colors.purple;
    }
  }

  /// Check if the marker is complete based on the number of points
  bool isComplete(List<dynamic> points) {
    return points.length >= minPoints;
  }
}

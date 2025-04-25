import 'package:hive/hive.dart';
import 'package:vegavision/models/marker_type.dart';

part 'marker.g.dart';

@HiveType(typeId: 6)
class Marker {
  const Marker({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    this.size = 1.0,
    this.label,
  });

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(
      id: json['id'] as String,
      x: json['x'] as double,
      y: json['y'] as double,
      type: MarkerType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MarkerType.remove,
      ),
      size: (json['size'] as num?)?.toDouble() ?? 1.0,
      label: json['label'] as String?,
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final double x;

  @HiveField(2)
  final double y;

  @HiveField(3)
  final MarkerType type;

  @HiveField(4)
  final double size;

  @HiveField(5)
  final String? label;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'type': type.toString().split('.').last,
      'size': size,
      'label': label,
    };
  }

  Marker copyWith({
    String? id,
    double? x,
    double? y,
    MarkerType? type,
    double? size,
    String? label,
  }) {
    return Marker(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      size: size ?? this.size,
      label: label ?? this.label,
    );
  }
}

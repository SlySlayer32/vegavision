import 'package:hive/hive.dart';
import 'package:vector_math/vector_math.dart';

part 'marker_type.g.dart';

@HiveType(typeId: 3)
enum MarkerType {
  @HiveField(0)
  remove,
  @HiveField(1)
  replace,
  @HiveField(2)
  edit,
  @HiveField(3)
  custom,
}

@HiveType(typeId: 4)
class MarkerPosition {
  const MarkerPosition({required this.x, required this.y});

  factory MarkerPosition.fromJson(Map<String, dynamic> json) {
    return MarkerPosition(x: json['x'] as double, y: json['y'] as double);
  }
  @HiveField(0)
  final double x;

  @HiveField(1)
  final double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

@HiveType(typeId: 5)
class Marker {
  const Marker({
    required this.x,
    required this.y,
    required this.type,
    this.customType,
    this.position,
  });

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(
      x: json['x'] as double,
      y: json['y'] as double,
      type: MarkerType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MarkerType.custom,
      ),
      customType: json['customType'] as String?,
      position:
          json['position'] != null
              ? Vector3(
                json['position']['x'] as double,
                json['position']['y'] as double,
                json['position']['z'] as double,
              )
              : null,
    );
  }
  @HiveField(0)
  final double x;

  @HiveField(1)
  final double y;

  @HiveField(2)
  final MarkerType type;

  @HiveField(3)
  final String? customType;

  @HiveField(4)
  final Vector3? position;

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'type': type.toString().split('.').last,
      'customType': customType,
      'position':
          position != null
              ? {'x': position!.x, 'y': position!.y, 'z': position!.z}
              : null,
    };
  }

  Marker copyWith({
    double? x,
    double? y,
    MarkerType? type,
    String? customType,
    Vector3? position,
  }) {
    return Marker(
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      customType: customType ?? this.customType,
      position: position ?? this.position,
    );
  }
}

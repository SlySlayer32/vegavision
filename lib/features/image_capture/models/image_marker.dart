import 'package:flutter/material.dart';

class ImageMarker {
  final String id;
  final Offset position;
  final double size;
  final Color color;
  final String? label;

  const ImageMarker({
    required this.id,
    required this.position,
    this.size = 20.0,
    this.color = Colors.red,
    this.label,
  });

  ImageMarker copyWith({
    String? id,
    Offset? position,
    double? size,
    Color? color,
    String? label,
  }) {
    return ImageMarker(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': position.dx,
      'y': position.dy,
      'size': size,
      'color': color.value,
      'label': label,
    };
  }

  factory ImageMarker.fromJson(Map<String, dynamic> json) {
    return ImageMarker(
      id: json['id'] as String,
      position: Offset(json['x'] as double, json['y'] as double),
      size: json['size'] as double? ?? 20.0,
      color: Color(json['color'] as int),
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageMarker && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

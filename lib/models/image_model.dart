import 'package:hive/hive.dart';

part 'image_model.g.dart';

@HiveType(typeId: 0)
class ImageModel {

  ImageModel({
    required this.id,
    required this.localPath,
    this.cloudPath,
    required this.createdAt,
    this.metadata,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      cloudPath: json['cloudPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String localPath;

  @HiveField(2)
  final String? cloudPath;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'cloudPath': cloudPath,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

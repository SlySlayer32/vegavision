import 'package:hive/hive.dart';

part 'edit_result.g.dart';

@HiveType(typeId: 2)
class EditResult {

  EditResult({
    required this.id,
    required this.requestId,
    required this.imageId,
    required this.editedImagePath,
    required this.createdAt,
    this.metadata,
  });

  factory EditResult.fromJson(Map<String, dynamic> json) {
    return EditResult(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      imageId: json['imageId'] as String,
      editedImagePath: json['editedImagePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String requestId;

  @HiveField(2)
  final String imageId;

  @HiveField(3)
  final String editedImagePath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'imageId': imageId,
      'editedImagePath': editedImagePath,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

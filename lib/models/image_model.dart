import 'package:hive/hive.dart';
import 'package:vegavision/models/image_status.dart';

part 'image_model.g.dart';

@HiveType(typeId: 1)
class ImageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String localPath;

  @HiveField(2)
  final String? cloudPath;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? updatedAt;

  @HiveField(5)
  final int fileSize;

  @HiveField(6)
  final String mimeType;

  @HiveField(7)
  final ImageStatus status;

  @HiveField(8)
  final Map<String, dynamic>? metadata;

  @HiveField(9)
  final ImageDimensions? dimensions;

  ImageModel({
    required this.id,
    required this.localPath,
    this.cloudPath,
    required this.createdAt,
    this.updatedAt,
    required this.fileSize,
    required this.mimeType,
    required this.status,
    this.metadata,
    this.dimensions,
  });

  ImageModel copyWith({
    String? id,
    String? localPath,
    String? cloudPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? fileSize,
    String? mimeType,
    ImageStatus? status,
    Map<String, dynamic>? metadata,
    ImageDimensions? dimensions,
  }) {
    return ImageModel(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      cloudPath: cloudPath ?? this.cloudPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      dimensions: dimensions ?? this.dimensions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'cloudPath': cloudPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fileSize': fileSize,
      'mimeType': mimeType,
      'status': status.toString(),
      'metadata': metadata,
      'dimensions': dimensions?.toJson(),
    };
  }

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      cloudPath: json['cloudPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      fileSize: json['fileSize'] as int,
      mimeType: json['mimeType'] as String,
      status: ImageStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ImageStatus.pending,
      ),
      metadata:
          json['metadata'] != null
              ? Map<String, dynamic>.from(json['metadata'] as Map)
              : null,
      dimensions:
          json['dimensions'] != null
              ? ImageDimensions.fromJson(
                Map<String, dynamic>.from(json['dimensions'] as Map),
              )
              : null,
    );
  }
}

@HiveType(typeId: 2)
class ImageDimensions {
  @HiveField(0)
  final int width;

  @HiveField(1)
  final int height;

  const ImageDimensions({required this.width, required this.height});

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }

  factory ImageDimensions.fromJson(Map<String, dynamic> json) {
    return ImageDimensions(
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
}

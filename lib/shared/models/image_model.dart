import 'package:hive/hive.dart';
import 'package:vegavision/models/image_status.dart';

part 'image_model.g.dart';

class ImageDimensions {
  ImageDimensions({required this.width, required this.height});

  factory ImageDimensions.fromJson(Map<String, dynamic> json) {
    return ImageDimensions(
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
  final int width;
  final int height;

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }
}

@HiveType(typeId: 1)
class ImageModel {
  ImageModel({
    required this.id,
    required this.localPath,
    this.cloudPath,
    required this.createdAt,
    this.status = ImageStatus.created,
    this.fileSize,
    this.mimeType,
    this.dimensions,
    required this.source,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      cloudPath: json['cloudPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ImageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ImageStatus.created,
      ),
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
      dimensions:
          json['dimensions'] != null
              ? ImageDimensions.fromJson(
                json['dimensions'] as Map<String, dynamic>,
              )
              : null,
      source: json['source'] as String,
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
  final ImageStatus status;

  @HiveField(5)
  final int? fileSize;

  @HiveField(6)
  final String? mimeType;

  @HiveField(7)
  final ImageDimensions? dimensions;

  @HiveField(8)
  final String source;

  ImageModel copyWith({
    String? id,
    String? localPath,
    String? cloudPath,
    DateTime? createdAt,
    ImageStatus? status,
    int? fileSize,
    String? mimeType,
    ImageDimensions? dimensions,
    String? source,
  }) {
    return ImageModel(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      cloudPath: cloudPath ?? this.cloudPath,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      dimensions: dimensions ?? this.dimensions,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'cloudPath': cloudPath,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'dimensions': dimensions?.toJson(),
      'source': source,
    };
  }
}

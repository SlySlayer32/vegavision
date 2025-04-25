import 'package:hive/hive.dart';
import 'package:vegavision/models/edit_result_status.dart';

part 'edit_result.g.dart';

class ProcessingMetrics {
  ProcessingMetrics({
    required this.confidenceScore,
    this.objectDetectionScores,
    this.segmentationScores,
    this.labels,
  });

  factory ProcessingMetrics.fromJson(Map<String, dynamic> json) {
    return ProcessingMetrics(
      confidenceScore: json['confidenceScore'] as double,
      objectDetectionScores:
          json['objectDetectionScores'] != null
              ? Map<String, double>.from(json['objectDetectionScores'])
              : null,
      segmentationScores:
          json['segmentationScores'] != null
              ? Map<String, double>.from(json['segmentationScores'])
              : null,
      labels: json['labels'] != null ? Map<String, String>.from(json['labels']) : null,
    );
  }
  final double confidenceScore;
  final Map<String, double>? objectDetectionScores;
  final Map<String, double>? segmentationScores;
  final Map<String, String>? labels;

  Map<String, dynamic> toJson() {
    return {
      'confidenceScore': confidenceScore,
      'objectDetectionScores': objectDetectionScores,
      'segmentationScores': segmentationScores,
      'labels': labels,
    };
  }
}

@HiveType(typeId: 2)
class EditResult {
  EditResult({
    required this.id,
    required this.imageId,
    required this.originalImageId,
    required this.editedImagePath,
    this.resultImagePath,
    this.downloadUrl,
    required this.createdAt,
    this.expiresAt,
    this.status = EditResultStatus.created,
    this.errorMessage,
    this.processingTimeMs,
    this.confidenceScores,
    this.metrics,
  });

  factory EditResult.fromJson(Map<String, dynamic> json) {
    return EditResult(
      id: json['id'] as String,
      imageId: json['imageId'] as String,
      originalImageId: json['originalImageId'] as String,
      editedImagePath: json['editedImagePath'] as String,
      resultImagePath: json['resultImagePath'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      status: EditResultStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => EditResultStatus.created,
      ),
      errorMessage: json['errorMessage'] as String?,
      processingTimeMs: json['processingTimeMs'] as int?,
      confidenceScores:
          json['confidenceScores'] != null
              ? Map<String, double>.from(json['confidenceScores'])
              : null,
      metrics:
          json['metrics'] != null
              ? ProcessingMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
              : null,
    );
  }
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imageId;

  @HiveField(2)
  final String originalImageId;

  @HiveField(3)
  final String editedImagePath;

  @HiveField(4)
  final String? resultImagePath;

  @HiveField(5)
  final String? downloadUrl;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? expiresAt;

  @HiveField(8)
  final EditResultStatus status;

  @HiveField(9)
  final String? errorMessage;

  @HiveField(10)
  final int? processingTimeMs;

  @HiveField(11)
  final Map<String, double>? confidenceScores;

  @HiveField(12)
  final ProcessingMetrics? metrics;

  bool get isDownloadUrlExpired {
    if (expiresAt == null) return true;
    return DateTime.now().isAfter(expiresAt!);
  }

  EditResult copyWith({
    String? id,
    String? imageId,
    String? originalImageId,
    String? editedImagePath,
    String? resultImagePath,
    String? downloadUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    EditResultStatus? status,
    String? errorMessage,
    int? processingTimeMs,
    Map<String, double>? confidenceScores,
    ProcessingMetrics? metrics,
  }) {
    return EditResult(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      originalImageId: originalImageId ?? this.originalImageId,
      editedImagePath: editedImagePath ?? this.editedImagePath,
      resultImagePath: resultImagePath ?? this.resultImagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      confidenceScores: confidenceScores ?? this.confidenceScores,
      metrics: metrics ?? this.metrics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageId': imageId,
      'originalImageId': originalImageId,
      'editedImagePath': editedImagePath,
      'resultImagePath': resultImagePath,
      'downloadUrl': downloadUrl,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status.toString().split('.').last,
      'errorMessage': errorMessage,
      'processingTimeMs': processingTimeMs,
      'confidenceScores': confidenceScores,
      'metrics': metrics?.toJson(),
    };
  }
}

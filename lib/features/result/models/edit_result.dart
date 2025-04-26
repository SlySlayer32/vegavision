import 'package:hive/hive.dart';
import 'package:vegavision/features/result/models/edit_result_status.dart';
import 'package:vegavision/features/result/models/processing_metrics.dart';

part 'edit_result.g.dart';

@HiveType(typeId: 2)
class EditResult {
  const EditResult({
    required this.id,
    required this.imageId,
    required this.originalImageId,
    required this.editedImagePath,
    required this.createdAt,
    required this.status,
    this.resultImagePath,
    this.downloadUrl,
    this.expiresAt,
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
      expiresAt:
          json['expiresAt'] == null
              ? null
              : DateTime.parse(json['expiresAt'] as String),
      status: EditResultStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => EditResultStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
      processingTimeMs: json['processingTimeMs'] as int?,
      confidenceScores: (json['confidenceScores'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as double)),
      metrics:
          json['metrics'] == null
              ? null
              : ProcessingMetrics.fromJson(
                json['metrics'] as Map<String, dynamic>,
              ),
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
      'status': status.toString(),
      'errorMessage': errorMessage,
      'processingTimeMs': processingTimeMs,
      'confidenceScores': confidenceScores,
      'metrics': metrics?.toJson(),
    };
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
}

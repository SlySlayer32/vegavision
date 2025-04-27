import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/image_model.dart';

part 'edit_result.g.dart';

/// The status of an edit result in the system
enum EditResultStatus {
  /// Result processing has not yet started
  pending,

  /// Result is being generated
  processing,

  /// Result has been successfully generated
  completed,

  /// Result generation failed
  failed,

  /// Result was cancelled
  cancelled,
}

/// A model representing the result of an image edit operation
@immutable
@JsonSerializable()
class EditResult {
  /// Unique identifier for the edit result
  final String id;

  /// Identifier for the edit request that produced this result
  final String requestId;

  /// Identifier for the original image that was edited
  final String imageId;

  /// Current status of the edit result
  final EditResultStatus status;

  /// When the result was created
  final DateTime createdAt;

  /// When the result was last updated
  final DateTime updatedAt;

  /// Path to the output image file
  final String? outputImagePath;

  /// Optional description of the changes made to the image
  final String? outputDescription;

  /// Optional processing metrics data
  final ProcessingMetrics? processingMetrics;

  /// Reference to the original edit request if available
  @JsonKey(ignore: true)
  final EditRequest? request;

  /// Reference to the original image model if available
  @JsonKey(ignore: true)
  final ImageModel? image;

  /// Any error message associated with failed processing
  final String? errorMessage;

  /// Creates a new edit result
  EditResult({
    String? id,
    required this.requestId,
    required this.imageId,
    this.status = EditResultStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.outputImagePath,
    this.outputDescription,
    this.processingMetrics,
    this.request,
    this.image,
    this.errorMessage,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this result with the given field values changed
  EditResult copyWith({
    String? id,
    String? requestId,
    String? imageId,
    EditResultStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? outputImagePath,
    String? outputDescription,
    ProcessingMetrics? processingMetrics,
    EditRequest? request,
    ImageModel? image,
    String? errorMessage,
  }) {
    return EditResult(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      imageId: imageId ?? this.imageId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      outputImagePath: outputImagePath ?? this.outputImagePath,
      outputDescription: outputDescription ?? this.outputDescription,
      processingMetrics: processingMetrics ?? this.processingMetrics,
      request: request ?? this.request,
      image: image ?? this.image,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Creates a failed result with the given error message
  factory EditResult.failed({
    required String requestId,
    required String imageId,
    required String errorMessage,
  }) {
    return EditResult(
      requestId: requestId,
      imageId: imageId,
      status: EditResultStatus.failed,
      errorMessage: errorMessage,
    );
  }

  /// Factory constructor for creating a new [EditResult] instance from JSON data
  factory EditResult.fromJson(Map<String, dynamic> json) =>
      _$EditResultFromJson(json);

  /// Converts this [EditResult] instance to a JSON map
  Map<String, dynamic> toJson() => _$EditResultToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          requestId == other.requestId &&
          imageId == other.imageId &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^ requestId.hashCode ^ imageId.hashCode ^ status.hashCode;
}

/// Processing metrics for the edit operation
@immutable
@JsonSerializable()
class ProcessingMetrics {
  /// Total time in milliseconds to process the edit
  final int processingTimeMs;

  /// AI model used for processing
  final String model;

  /// Size of the input image in bytes
  final int inputImageSizeBytes;

  /// Size of the output image in bytes
  final int outputImageSizeBytes;

  /// Original dimensions of the input image (width x height)
  final String inputDimensions;

  /// Dimensions of the output image (width x height)
  final String outputDimensions;

  /// Additional processing metadata
  final Map<String, dynamic>? metadata;

  /// Creates new processing metrics
  const ProcessingMetrics({
    required this.processingTimeMs,
    required this.model,
    required this.inputImageSizeBytes,
    required this.outputImageSizeBytes,
    required this.inputDimensions,
    required this.outputDimensions,
    this.metadata,
  });

  /// Creates a copy of these metrics with the given field values changed
  ProcessingMetrics copyWith({
    int? processingTimeMs,
    String? model,
    int? inputImageSizeBytes,
    int? outputImageSizeBytes,
    String? inputDimensions,
    String? outputDimensions,
    Map<String, dynamic>? metadata,
  }) {
    return ProcessingMetrics(
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      model: model ?? this.model,
      inputImageSizeBytes: inputImageSizeBytes ?? this.inputImageSizeBytes,
      outputImageSizeBytes: outputImageSizeBytes ?? this.outputImageSizeBytes,
      inputDimensions: inputDimensions ?? this.inputDimensions,
      outputDimensions: outputDimensions ?? this.outputDimensions,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Factory constructor for creating new [ProcessingMetrics] from JSON data
  factory ProcessingMetrics.fromJson(Map<String, dynamic> json) =>
      _$ProcessingMetricsFromJson(json);

  /// Converts these metrics to a JSON map
  Map<String, dynamic> toJson() => _$ProcessingMetricsToJson(this);
}

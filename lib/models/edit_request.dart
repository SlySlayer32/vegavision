import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/models/marker_type.dart';

part 'edit_request.g.dart';

/// The status of an edit request in the system
enum EditRequestStatus {
  /// Request is newly created and not yet submitted
  created,

  /// Request has been submitted and is queued for processing
  submitted,

  /// Request is currently being processed by the AI
  processing,

  /// Request processing has completed successfully
  completed,

  /// Request processing failed
  failed,

  /// Request has been cancelled by the user
  cancelled,
}

/// A request to edit an image with specific instructions and markers
@immutable
@JsonSerializable()
class EditRequest {
  /// Creates a new edit request
  EditRequest({
    required this.imageId,
    required this.instruction,
    String? id,
    this.status = EditRequestStatus.created,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.estimatedProcessingTimeSec,
    this.metadata,
    this.markers,
    this.image,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Factory constructor for creating a new [EditRequest] instance from JSON data
  factory EditRequest.fromJson(Map<String, dynamic> json) =>
      _$EditRequestFromJson(json);

  /// Unique identifier for the edit request
  final String id;

  /// Unique identifier for the image being edited
  final String imageId;

  /// User's instructions for the edit
  final String instruction;

  /// Current status of the edit request
  final EditRequestStatus status;

  /// When the request was created
  final DateTime createdAt;

  /// When the request was last updated
  final DateTime updatedAt;

  /// The estimated processing time in seconds
  final int? estimatedProcessingTimeSec;

  /// Additional metadata about the request
  final Map<String, dynamic>? metadata;

  /// List of markers that define regions to edit
  final List<Marker>? markers;

  /// Reference to the original image model if available
  @JsonKey(ignore: true)
  final ImageModel? image;

  /// Creates a copy of this request with the given field values changed
  EditRequest copyWith({
    String? id,
    String? imageId,
    String? instruction,
    EditRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? estimatedProcessingTimeSec,
    Map<String, dynamic>? metadata,
    List<Marker>? markers,
    ImageModel? image,
  }) {
    return EditRequest(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      instruction: instruction ?? this.instruction,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedProcessingTimeSec:
          estimatedProcessingTimeSec ?? this.estimatedProcessingTimeSec,
      metadata: metadata ?? this.metadata,
      markers: markers ?? this.markers,
      image: image ?? this.image,
    );
  }

  /// Converts this [EditRequest] instance to a JSON map
  Map<String, dynamic> toJson() => _$EditRequestToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          imageId == other.imageId &&
          instruction == other.instruction &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^ imageId.hashCode ^ instruction.hashCode ^ status.hashCode;
}

/// A marker representing a region of interest on an image
@immutable
@JsonSerializable()
class Marker {
  /// Creates a new marker
  Marker({
    required this.type,
    required this.points,
    String? id,
    this.properties,
  }) : id = id ?? const Uuid().v4();

  /// Factory constructor for creating a new [Marker] instance from JSON data
  factory Marker.fromJson(Map<String, dynamic> json) => _$MarkerFromJson(json);

  /// Unique identifier for the marker
  final String id;

  /// The type of marker (line, rectangle, etc.)
  final MarkerType type;

  /// List of points defining the marker shape
  final List<MarkerPosition> points;

  /// Any extra properties for the marker
  final Map<String, dynamic>? properties;

  /// Creates a copy of this marker with the given fields changed
  Marker copyWith({
    String? id,
    MarkerType? type,
    List<MarkerPosition>? points,
    Map<String, dynamic>? properties,
  }) {
    return Marker(
      id: id ?? this.id,
      type: type ?? this.type,
      points: points ?? this.points,
      properties: properties ?? this.properties,
    );
  }

  /// Converts this [Marker] instance to a JSON map
  Map<String, dynamic> toJson() => _$MarkerToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Marker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

/// A position on an image, defined by x and y coordinates
@immutable
@JsonSerializable()
class MarkerPosition {
  /// Creates a new position
  const MarkerPosition({required this.x, required this.y});

  /// Factory constructor for creating a new [MarkerPosition] instance from JSON data
  factory MarkerPosition.fromJson(Map<String, dynamic> json) =>
      _$MarkerPositionFromJson(json);

  /// X coordinate (0.0 to 1.0 as percentage of image width)
  final double x;

  /// Y coordinate (0.0 to 1.0 as percentage of image height)
  final double y;

  /// Creates a copy of this position with the given fields changed
  MarkerPosition copyWith({double? x, double? y}) {
    return MarkerPosition(x: x ?? this.x, y: y ?? this.y);
  }

  /// Converts this [MarkerPosition] instance to a JSON map
  Map<String, dynamic> toJson() => _$MarkerPositionToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

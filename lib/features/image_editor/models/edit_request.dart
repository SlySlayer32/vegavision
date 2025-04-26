import 'package:hive/hive.dart';
import 'package:vegavision/features/image_capture/models/marker.dart';
import 'package:vegavision/features/image_editor/models/edit_request_status.dart';

part 'edit_request.g.dart';

@HiveType(typeId: 1)
class EditRequest {
  EditRequest({
    required this.id,
    required this.imageId,
    required this.markers,
    required this.instruction,
    required this.createdAt,
    this.status = EditRequestStatus.pending,
    this.errorMessage,
    this.additionalOptions,
    this.userId,
  });

  factory EditRequest.fromJson(Map<String, dynamic> json) {
    return EditRequest(
      id: json['id'] as String,
      imageId: json['imageId'] as String,
      markers:
          (json['markers'] as List)
              .map((m) => Marker.fromJson(m as Map<String, dynamic>))
              .toList(),
      instruction: json['instruction'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: EditRequestStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => EditRequestStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
      additionalOptions: json['additionalOptions'] as Map<String, dynamic>?,
      userId: json['userId'] as String?,
    );
  }
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imageId;

  @HiveField(2)
  final List<Marker> markers;

  @HiveField(3)
  final String instruction;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final EditRequestStatus status;

  @HiveField(6)
  final String? errorMessage;

  @HiveField(7)
  final Map<String, dynamic>? additionalOptions;

  @HiveField(8)
  final String? userId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageId': imageId,
      'markers': markers.map((m) => m.toJson()).toList(),
      'instruction': instruction,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString(),
      'errorMessage': errorMessage,
      'additionalOptions': additionalOptions,
      'userId': userId,
    };
  }

  EditRequest copyWith({
    String? id,
    String? imageId,
    List<Marker>? markers,
    String? instruction,
    DateTime? createdAt,
    EditRequestStatus? status,
    String? errorMessage,
    Map<String, dynamic>? additionalOptions,
    String? userId,
  }) {
    return EditRequest(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      markers: markers ?? this.markers,
      instruction: instruction ?? this.instruction,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      userId: userId ?? this.userId,
    );
  }
}

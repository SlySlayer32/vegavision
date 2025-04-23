import 'package:hive/hive.dart';

part 'edit_request.g.dart';

@HiveType(typeId: 1)
class EditRequest {

  EditRequest({
    required this.id,
    required this.imageId,
    required this.instruction,
    required this.markers,
    required this.createdAt,
    this.status = 'pending',
  });

  factory EditRequest.fromJson(Map<String, dynamic> json) {
    return EditRequest(
      id: json['id'] as String,
      imageId: json['imageId'] as String,
      instruction: json['instruction'] as String,
      markers:
          (json['markers'] as List<dynamic>)
              .map((m) => Map<String, double>.from(m as Map))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imageId;

  @HiveField(2)
  final String instruction;

  @HiveField(3)
  final List<Map<String, double>> markers;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageId': imageId,
      'instruction': instruction,
      'markers': markers,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}

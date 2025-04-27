import 'package:hive/hive.dart';

part 'edit_request_status.g.dart';

@HiveType(typeId: 3)
enum EditRequestStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,

  @HiveField(4)
  cancelled,
}

import 'package:hive/hive.dart';

part 'edit_result_status.g.dart';

@HiveType(typeId: 4)
enum EditResultStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  processing,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,

  @HiveField(4)
  cancelled,
}

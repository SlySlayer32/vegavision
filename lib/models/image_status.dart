import 'package:hive/hive.dart';

part 'image_status.g.dart';

@HiveType(typeId: 0)
enum ImageStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  uploading,

  @HiveField(2)
  uploaded,

  @HiveField(3)
  processing,

  @HiveField(4)
  completed,

  @HiveField(5)
  failed,
}

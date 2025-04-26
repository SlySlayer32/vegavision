import 'package:hive/hive.dart';

@HiveType(typeId: 5)
enum MarkerType {
  @HiveField(0)
  remove,

  @HiveField(1)
  replace,

  @HiveField(2)
  enhance,
}

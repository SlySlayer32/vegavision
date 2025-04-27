import 'package:hive/hive.dart';

part 'marker_type.g.dart';

@HiveType(typeId: 5)
enum MarkerType {
  @HiveField(0)
  remove,

  @HiveField(1)
  replace,

  @HiveField(2)
  enhance,
}

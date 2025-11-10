import 'package:hive/hive.dart';

part 'driver.g.dart';

@HiveType(typeId: 1)
class Driver extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  Driver({
    required this.id,
    required this.name,
  });
}

import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 0)
class Vehicle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? plate;

  @HiveField(3)
  bool active;

  @HiveField(4)
  String? currencyCode;

  Vehicle({
    required this.id,
    required this.title,
    this.plate,
    this.active = true,
    this.currencyCode,
  });
}

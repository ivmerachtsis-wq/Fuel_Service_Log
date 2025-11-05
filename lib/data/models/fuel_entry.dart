import 'package:hive/hive.dart';

part 'fuel_entry.g.dart';

@HiveType(typeId: 2)
class FuelEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double odometerKm;

  @HiveField(4)
  double liters;

  @HiveField(5)
  double pricePerLiter;

  @HiveField(6)
  double amount;

  @HiveField(7)
  bool fullTank;

  @HiveField(8)
  String? notes;

  FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.liters,
    required this.pricePerLiter,
    required this.amount,
    this.fullTank = true,
    this.notes,
  });
}

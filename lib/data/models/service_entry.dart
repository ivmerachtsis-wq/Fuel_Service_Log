import 'package:hive/hive.dart';

part 'service_entry.g.dart';

@HiveType(typeId: 3)
class ServiceEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double odometerKm;

  @HiveField(4)
  String description;

  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  String? invoicePhotoPath;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? currencyCode;

  @HiveField(9)
  String? driverId;

  ServiceEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.description,
    required this.totalAmount,
    this.invoicePhotoPath,
    this.notes,
    this.currencyCode,
    this.driverId,
  });
}

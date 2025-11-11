import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/vehicle.dart';
import '../data/models/driver.dart';
import '../data/models/fuel_entry.dart';
import '../data/models/service_entry.dart';

/// Αρχικοποίηση Hive και άνοιγμα όλων των boxes
Future<void> initHive() async {
  // Αρχικοποίηση Hive για Flutter
  await Hive.initFlutter();

  // Καταχώριση adapters
  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(DriverAdapter());
  Hive.registerAdapter(FuelEntryAdapter());
  Hive.registerAdapter(ServiceEntryAdapter());

  // Άνοιγμα boxes
  await Hive.openBox<Vehicle>('vehicles');
  await Hive.openBox<Driver>('drivers');
  await Hive.openBox<FuelEntry>('fuel_entries');
  await Hive.openBox<ServiceEntry>('service_entries');
  await Hive.openBox('ui_prefs'); // UI preferences (filter selections, etc.)
}

// Temporary Greek data seeding script for Unicode PDF QA.
// DO NOT COMMIT.
import 'package:flutter/widgets.dart';
import 'bootstrap/app_bootstrap.dart';
import 'data/models/vehicle.dart';
import 'data/models/fuel_entry.dart';
import 'data/models/service_entry.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();

  final vehicles = Hive.box<Vehicle>('vehicles');
  final fuels = Hive.box<FuelEntry>('fuel_entries');
  final services = Hive.box<ServiceEntry>('service_entries');

  const vehicleId = 'gr-test-vehicle';
  const vehicleTitle = 'Δοκιμή Ελληνικά – Άλφα';

  // Create or update Greek vehicle
  Vehicle vehicle = vehicles.get(vehicleId) ?? Vehicle(id: vehicleId, title: vehicleTitle, plate: 'ΕΛ-1234', active: true);
  if (vehicle.title != vehicleTitle) {
    vehicle.title = vehicleTitle;
    await vehicles.put(vehicleId, vehicle);
  } else if (vehicles.get(vehicleId) == null) {
    await vehicles.put(vehicleId, vehicle);
  }

  DateTime now = DateTime.now();

  // Seed a couple of fuel entries
  final fuelSeed = [
    FuelEntry(
      id: 'gr-fuel-1',
      vehicleId: vehicleId,
      date: now.subtract(const Duration(days: 10)),
      odometerKm: 15230,
      liters: 42.7,
      pricePerLiter: 1.85,
      amount: 42.7 * 1.85,
      fullTank: true,
      notes: 'Γέμισμα πριν ταξίδι',
      currencyCode: 'EUR',
    ),
    FuelEntry(
      id: 'gr-fuel-2',
      vehicleId: vehicleId,
      date: now.subtract(const Duration(days: 3)),
      odometerKm: 15580,
      liters: 35.2,
      pricePerLiter: 1.82,
      amount: 35.2 * 1.82,
      fullTank: true,
      notes: 'Γέμισμα επιστροφής',
      currencyCode: 'EUR',
    ),
  ];

  for (final f in fuelSeed) {
    if (fuels.get(f.id) == null) {
      await fuels.put(f.id, f);
    }
  }

  // Seed service entries
  final serviceSeed = [
    ServiceEntry(
      id: 'gr-serv-1',
      vehicleId: vehicleId,
      date: now.subtract(const Duration(days: 40)),
      odometerKm: 14800,
      description: 'Σέρβις αλλαγή λαδιών',
      totalAmount: 95.0,
      notes: 'Χρήση πλήρως συνθετικού',
      currencyCode: 'EUR',
    ),
    ServiceEntry(
      id: 'gr-serv-2',
      vehicleId: vehicleId,
      date: now.subtract(const Duration(days: 15)),
      odometerKm: 15100,
      description: 'Έλεγχος φρένων',
      totalAmount: 40.0,
      notes: 'Μικρή φθορά εμπρός',
      currencyCode: 'EUR',
    ),
  ];

  for (final s in serviceSeed) {
    if (services.get(s.id) == null) {
      await services.put(s.id, s);
    }
  }

  print('Seed Greek data inserted/updated successfully.');
}
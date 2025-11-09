import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import '../data/models/vehicle.dart';
import '../data/models/driver.dart';
import '../data/models/fuel_entry.dart';
import '../data/models/service_entry.dart';

/// Φορτώνει δοκιμαστικά δεδομένα με γνωστά αποτελέσματα για verification
Future<void> loadTestData() async {
  debugPrint('[TestData] Loading sample data...');
  
  final vehiclesBox = Hive.box<Vehicle>('vehicles');
  final driversBox = Hive.box<Driver>('drivers');
  final fuelBox = Hive.box<FuelEntry>('fuel_entries');
  final serviceBox = Hive.box<ServiceEntry>('service_entries');

  // Clear existing data
  await vehiclesBox.clear();
  await driversBox.clear();
  await fuelBox.clear();
  await serviceBox.clear();

  // Create test vehicle
  final testVehicle = Vehicle(
    id: 'test_veh_1',
    title: 'Test Car',
    plate: 'ABC-1234',
    active: true,
  );
  await vehiclesBox.put(testVehicle.id, testVehicle);

  // Create test driver
  final testDriver = Driver(
    id: 'test_driver_1',
    name: 'Test Driver',
  );
  await driversBox.put(testDriver.id, testDriver);

  // Ρεαλιστικό σενάριο: Δεξαμενή 65L, συνήθως γεμίσματα ~60L, κατανάλωση 9 L/100km
  // Με 60L διανύουμε περίπου: 60 / 9 * 100 ≈ 667 km
  // Γεμίσματα από 1/10/2024 έως 31/10/2025 (12 μήνες + 1 μήνα), πάντα full tank
  
  int entryId = 0;
  double currentOdo = 10000.0; // Starting odometer
  final startDate = DateTime(2024, 10, 1);
  final endDate = DateTime(2025, 10, 31);
  
  final List<Map<String, dynamic>> fuelDebug = [];
  final List<Map<String, dynamic>> serviceDebug = [];
  
  // Θα δημιουργήσουμε γεμίσματα κάθε ~667 km (≈ κάθε 10 ημέρες)
  // Από 1/10/2024 έως 31/10/2025 ≈ 395 ημέρες → ~39-40 γεμίσματα
  
  int daysOffset = 0;
  final refillIntervalDays = 10; // Κάθε 10 ημέρες περίπου
  
  // Διακύμανση λίτρων: 55-62L (μέσος όρος ~60L)
  final refillLiters = [58.5, 61.2, 59.8, 60.5, 57.3, 62.0, 59.1, 60.8, 58.9, 61.5];
  int refillIndex = 0;
  
  while (true) {
    final refillDate = startDate.add(Duration(days: daysOffset));
    if (refillDate.isAfter(endDate)) break;
    
    final liters = refillLiters[refillIndex % refillLiters.length];
    final kmPerRefill = (liters / 9.0) * 100; // Με 9 L/100km
    
    // Γέμισμα full tank με διακυμάνσεις
    final fuelEntry = FuelEntry(
      id: 'fuel_${entryId++}',
      vehicleId: testVehicle.id,
      driverId: testDriver.id,
      date: refillDate,
      odometerKm: currentOdo,
      liters: liters,
      pricePerLiter: 1.65 + (refillIndex % 3) * 0.02, // €1.65-1.69/L
      amount: liters * (1.65 + (refillIndex % 3) * 0.02),
      fullTank: true,
    );
    await fuelBox.put(fuelEntry.id, fuelEntry);
    fuelDebug.add({'date': refillDate, 'odo': currentOdo, 'liters': liters});
    
    currentOdo += kmPerRefill;
    daysOffset += refillIntervalDays;
    refillIndex++;
    
    // Service κάθε ~5.000 km (περίπου κάθε 7-8 γεμίσματα)
    if (refillIndex > 0 && refillIndex % 8 == 0) {
      final serviceDate = refillDate.add(const Duration(days: 2));
      final service = ServiceEntry(
        id: 'service_${entryId++}',
        vehicleId: testVehicle.id,
        driverId: testDriver.id,
        date: serviceDate,
        odometerKm: currentOdo - 350, // Service λίγο πριν το επόμενο γέμισμα
        description: 'Τακτική συντήρηση ${(refillIndex / 8).floor()}',
        totalAmount: 120.0 + (refillIndex % 2) * 30.0, // €120 ή €150
      );
      await serviceBox.put(service.id, service);
      serviceDebug.add({'date': serviceDate, 'amount': service.totalAmount});
    }
  }  // Υπολογισμός πραγματικών αθροισμάτων για verification
  final totalFuel = fuelBox.values.fold<double>(0, (sum, e) => sum + e.amount);
  final totalLiters = fuelBox.values.fold<double>(0, (sum, e) => sum + e.liters);
  final totalService = serviceBox.values.fold<double>(0, (sum, e) => sum + e.totalAmount);

  // Χρησιμοποιούμε την ΚΑΤΑΓΕΓΡΑΜΜΕΝΗ απόσταση (διαφορά πρώτου / τελευταίου fuel entry)
  double recordedDistance = 0;
  if (fuelBox.isNotEmpty) {
    final odos = fuelBox.values.map((e) => e.odometerKm).toList();
    final minOdo = odos.reduce(min);
    final maxOdo = odos.reduce(max);
    recordedDistance = (maxOdo - minOdo);
  }
  
  // Debug output
  debugPrint('\n[TestData] ================');
  debugPrint('[TestData] Fuel Entries:');
  for (var f in fuelDebug) {
    debugPrint('  ${f['date']}: odo=${f['odo']}, L=${f['liters']}');
  }
  debugPrint('[TestData] Service Entries:');
  for (var s in serviceDebug) {
    debugPrint('  ${s['date']}: €${s['amount']}');
  }
  debugPrint('[TestData] ================\n');
  
  debugPrint('[TestData] Loaded successfully!');
  debugPrint('[TestData] Summary:');
  debugPrint('  - Vehicle: ${testVehicle.title}');
  debugPrint('  - Fuel entries: ${fuelBox.length}');
  debugPrint('  - Service entries: ${serviceBox.length}');
  debugPrint('  - Total distance (recorded): ${recordedDistance.toStringAsFixed(0)} km');
  debugPrint('  - Total liters: ${totalLiters.toStringAsFixed(1)} L');
  debugPrint('  - Total fuel cost: €${totalFuel.toStringAsFixed(2)}');
  debugPrint('  - Total service cost: €${totalService.toStringAsFixed(2)}');
  debugPrint('  - Total cost: €${(totalFuel + totalService).toStringAsFixed(2)}');
  debugPrint('[TestData] Expected KPIs:');
  if (recordedDistance > 0) {
    debugPrint('  - €/km = €${((totalFuel + totalService) / recordedDistance).toStringAsFixed(3)}');
    debugPrint('  - L/100km = ${((totalLiters / recordedDistance) * 100).toStringAsFixed(2)}');
  } else {
    debugPrint('  - €/km = —');
    debugPrint('  - L/100km = —');
  }
  debugPrint('[TestData] Πήγαινε στο Stats tab για να επιβεβαιώσεις!');
}

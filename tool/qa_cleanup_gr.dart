// Temporary Greek data cleanup script for Unicode PDF QA.
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

  // Remove seeded fuel entries
  for (final id in ['gr-fuel-1', 'gr-fuel-2']) {
    await fuels.delete(id);
  }

  // Remove seeded service entries
  for (final id in ['gr-serv-1', 'gr-serv-2']) {
    await services.delete(id);
  }

  // Remove vehicle
  await vehicles.delete(vehicleId);

  print('Cleanup of Greek QA data completed.');
}
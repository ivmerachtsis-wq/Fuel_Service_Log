import 'package:hive_flutter/hive_flutter.dart';
import 'cached_box_service.dart';
import 'models/cached_state.dart';
import '../../data/models/vehicle.dart';
import '../../data/models/driver.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/service_entry.dart';

/// Aggregates all `CachedBoxService` instances (L1 caches) for domain models.
/// Supports optional preload from L2 `CachedState` snapshot.
class CachedServices {
  static final CachedServices _instance = CachedServices._();
  factory CachedServices() => _instance;
  CachedServices._();

  late CachedBoxService<Vehicle> vehicles;
  late CachedBoxService<Driver> drivers;
  late CachedBoxService<FuelEntry> fuelEntries;
  late CachedBoxService<ServiceEntry> serviceEntries;

  bool _initialized = false;

  /// Initialize services. If [snapshot] provided, hydrate from its box items
  /// instead of iterating Hive boxes (faster cold-start).
  Future<void> init({CachedState? snapshot}) async {
    if (_initialized) return;

    final vehiclesBox = Hive.box<Vehicle>('vehicles');
    final driversBox = Hive.box<Driver>('drivers');
    final fuelBox = Hive.box<FuelEntry>('fuel_entries');
    final serviceBox = Hive.box<ServiceEntry>('service_entries');

    vehicles = CachedBoxService<Vehicle>(vehiclesBox, 'vehicles');
    drivers = CachedBoxService<Driver>(driversBox, 'drivers');
    fuelEntries = CachedBoxService<FuelEntry>(fuelBox, 'fuel_entries');
    serviceEntries = CachedBoxService<ServiceEntry>(serviceBox, 'service_entries');

    // Build preload maps if snapshot available
    Map<dynamic, Vehicle>? vehPreload;
    Map<dynamic, Driver>? drvPreload;
    Map<dynamic, FuelEntry>? fuelPreload;
    Map<dynamic, ServiceEntry>? svcPreload;

    if (snapshot != null) {
      vehPreload = _mapPreload<Vehicle>(snapshot, 'vehicles', _vehicleFromJson);
      drvPreload = _mapPreload<Driver>(snapshot, 'drivers', _driverFromJson);
      fuelPreload = _mapPreload<FuelEntry>(snapshot, 'fuel_entries', _fuelFromJson);
      svcPreload = _mapPreload<ServiceEntry>(snapshot, 'service_entries', _serviceFromJson);
    }

    await vehicles.init(preload: vehPreload);
    await drivers.init(preload: drvPreload);
    await fuelEntries.init(preload: fuelPreload);
    await serviceEntries.init(preload: svcPreload);

    _initialized = true;
  }

  /// Rehydrate all L1 caches from Hive (source of truth) ignoring snapshot.
  Future<void> rehydrateFromHive() async {
    await vehicles.init();
    await drivers.init();
    await fuelEntries.init();
    await serviceEntries.init();
  }

  /// Produce data ready for SnapshotStore.write[Now] — each box serialized to map list.
  Map<String, List<Map<String, dynamic>>> toSnapshotData() {
    return {
      'vehicles': vehicles.getAll().map(_vehicleToJson).toList(),
      'drivers': drivers.getAll().map(_driverToJson).toList(),
      'fuel_entries': fuelEntries.getAll().map(_fuelToJson).toList(),
      'service_entries': serviceEntries.getAll().map(_serviceToJson).toList(),
    };
  }

  Map<dynamic, T>? _mapPreload<T>(CachedState snapshot, String boxName, T Function(Map<String,dynamic>) factory) {
    final snap = snapshot.boxes[boxName];
    if (snap == null) return null;
    final map = <dynamic, T>{};
    for (final item in snap.items) {
      final obj = factory(item);
      // Use 'id' as key if present
      final key = item['id'];
      map[key] = obj;
    }
    return map;
  }

  Vehicle _vehicleFromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        title: j['title'] as String,
        plate: j['plate'] as String?,
        active: (j['active'] as bool?) ?? true,
      );
  Map<String, dynamic> _vehicleToJson(Vehicle v) => {
        'id': v.id,
        'title': v.title,
        'plate': v.plate,
        'active': v.active,
      };

  Driver _driverFromJson(Map<String, dynamic> j) => Driver(
        id: j['id'] as String,
        name: j['name'] as String,
      );
  Map<String, dynamic> _driverToJson(Driver d) => {
        'id': d.id,
        'name': d.name,
      };

  FuelEntry _fuelFromJson(Map<String, dynamic> j) => FuelEntry(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        date: DateTime.parse(j['date'] as String),
        odometerKm: (j['odometerKm'] as num).toDouble(),
        liters: (j['liters'] as num).toDouble(),
        pricePerLiter: (j['pricePerLiter'] as num).toDouble(),
        amount: (j['amount'] as num).toDouble(),
        fullTank: (j['fullTank'] as bool?) ?? true,
        notes: j['notes'] as String?,
        currencyCode: j['currencyCode'] as String?,
        driverId: j['driverId'] as String?,
      );
  Map<String, dynamic> _fuelToJson(FuelEntry e) => {
        'id': e.id,
        'vehicleId': e.vehicleId,
        'date': e.date.toIso8601String(),
        'odometerKm': e.odometerKm,
        'liters': e.liters,
        'pricePerLiter': e.pricePerLiter,
        'amount': e.amount,
        'fullTank': e.fullTank,
        'notes': e.notes,
        'currencyCode': e.currencyCode,
        'driverId': e.driverId,
      };

  ServiceEntry _serviceFromJson(Map<String, dynamic> j) => ServiceEntry(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        date: DateTime.parse(j['date'] as String),
        odometerKm: (j['odometerKm'] as num).toDouble(),
        description: j['description'] as String,
        totalAmount: (j['totalAmount'] as num).toDouble(),
        invoicePhotoPath: j['invoicePhotoPath'] as String?,
        notes: j['notes'] as String?,
        currencyCode: j['currencyCode'] as String?,
        driverId: j['driverId'] as String?,
      );
  Map<String, dynamic> _serviceToJson(ServiceEntry e) => {
        'id': e.id,
        'vehicleId': e.vehicleId,
        'date': e.date.toIso8601String(),
        'odometerKm': e.odometerKm,
        'description': e.description,
        'totalAmount': e.totalAmount,
        'invoicePhotoPath': e.invoicePhotoPath,
        'notes': e.notes,
        'currencyCode': e.currencyCode,
        'driverId': e.driverId,
      };
}
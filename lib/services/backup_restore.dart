import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/vehicle.dart';
import '../data/models/driver.dart';
import '../data/models/fuel_entry.dart';
import '../data/models/service_entry.dart';

class BackupRestoreService {
  Future<Directory> _ensureBackupsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final backups = Directory('${dir.path}${Platform.pathSeparator}FuelServiceLog${Platform.pathSeparator}backups');
    if (!backups.existsSync()) backups.createSync(recursive: true);
    return backups;
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<bool> exportToJson() async {
    try {
      final dir = await _ensureBackupsDir();

    final vehicles = Hive.box<Vehicle>('vehicles').values.map((v) => {
          'id': v.id,
          'title': v.title,
          'plate': v.plate,
          'active': v.active,
        }).toList();

    final drivers = Hive.box<Driver>('drivers').values.map((d) => {
          'id': d.id,
          'name': d.name,
        }).toList();

    final fuelEntries = Hive.box<FuelEntry>('fuel_entries').values.map((e) => {
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
        }).toList();

    final serviceEntries = Hive.box<ServiceEntry>('service_entries').values.map((e) => {
          'id': e.id,
          'vehicleId': e.vehicleId,
          'date': e.date.toIso8601String(),
          'odometerKm': e.odometerKm,
          'description': e.description,
          'totalAmount': e.totalAmount,
          'invoicePhotoPath': e.invoicePhotoPath,
          'notes': e.notes,
        }).toList();

    final payload = jsonEncode({
      'vehicles': vehicles,
      'drivers': drivers,
      'fuel_entries': fuelEntries,
      'service_entries': serviceEntries,
    });

    final file = File('${dir.path}${Platform.pathSeparator}backup_${_timestamp()}.json');
    await file.create(recursive: true);
    await file.writeAsString(payload, encoding: utf8);
    return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> importFromJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Το αρχείο δεν βρέθηκε: $filePath');
    }

    final content = await file.readAsString(encoding: utf8);
    final data = jsonDecode(content) as Map<String, dynamic>;

    final vehicleBox = Hive.box<Vehicle>('vehicles');
    final driverBox = Hive.box<Driver>('drivers');
    final fuelBox = Hive.box<FuelEntry>('fuel_entries');
    final serviceBox = Hive.box<ServiceEntry>('service_entries');

    await vehicleBox.clear();
    await driverBox.clear();
    await fuelBox.clear();
    await serviceBox.clear();

    for (final v in (data['vehicles'] as List<dynamic>? ?? const [])) {
      final m = v as Map<String, dynamic>;
      await vehicleBox.put(m['id'] as String, Vehicle(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        plate: m['plate'] as String?,
        active: (m['active'] as bool?) ?? true,
      ));
    }

    for (final d in (data['drivers'] as List<dynamic>? ?? const [])) {
      final m = d as Map<String, dynamic>;
      await driverBox.put(m['id'] as String, Driver(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
      ));
    }

    for (final e in (data['fuel_entries'] as List<dynamic>? ?? const [])) {
      final m = e as Map<String, dynamic>;
      await fuelBox.put(m['id'] as String, FuelEntry(
        id: m['id'] as String,
        vehicleId: (m['vehicleId'] as String?) ?? '',
        date: DateTime.parse(m['date'] as String),
        odometerKm: (m['odometerKm'] as num?)?.toDouble() ?? 0,
        liters: (m['liters'] as num?)?.toDouble() ?? 0,
        pricePerLiter: (m['pricePerLiter'] as num?)?.toDouble() ?? 0,
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        fullTank: (m['fullTank'] as bool?) ?? true,
        notes: m['notes'] as String?,
        currencyCode: m['currencyCode'] as String?,
      ));
    }

    for (final e in (data['service_entries'] as List<dynamic>? ?? const [])) {
      final m = e as Map<String, dynamic>;
      await serviceBox.put(m['id'] as String, ServiceEntry(
        id: m['id'] as String,
        vehicleId: (m['vehicleId'] as String?) ?? '',
        date: DateTime.parse(m['date'] as String),
        odometerKm: (m['odometerKm'] as num?)?.toDouble() ?? 0,
        description: (m['description'] as String?) ?? '',
        totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0,
        invoicePhotoPath: m['invoicePhotoPath'] as String?,
        notes: m['notes'] as String?,
      ));
    }

    // Οι repos/λίστες που βασίζονται στο Hive.box.watch() θα ενημερωθούν αυτόματα.
  }
}

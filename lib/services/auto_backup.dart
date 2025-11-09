import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/vehicle.dart';
import '../data/models/driver.dart';
import '../data/models/fuel_entry.dart';
import '../data/models/service_entry.dart';

/// Service για αυτόματο backup με rotation και validation
class AutoBackupService {
  /// Δημιουργεί το directory για τα backups
  Future<Directory> _ensureBackupsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final backups = Directory('${dir.path}${Platform.pathSeparator}FuelServiceLog${Platform.pathSeparator}backups');
    if (!backups.existsSync()) {
      backups.createSync(recursive: true);
    }
    return backups;
  }

  /// Δημιουργεί timestamp string για το filename
  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  /// Επιστρέφει λίστα με όλα τα auto backup files, ταξινομημένα από νεότερο σε παλαιότερο
  Future<List<File>> listAutoBackupsSorted() async {
    final dir = await _ensureBackupsDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('auto_') && f.path.endsWith('.json'))
        .toList();
    
    // Ταξινόμηση από νεότερο προς παλαιότερο
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Διαγράφει παλαιότερα auto backups, κρατώντας μόνο τα 2 πιο πρόσφατα
  Future<void> _rotateAutoBackups() async {
    final backups = await listAutoBackupsSorted();
    
    // Κράτα μόνο τα 2 πιο πρόσφατα
    if (backups.length > 2) {
      for (int i = 2; i < backups.length; i++) {
        try {
          await backups[i].delete();
          // Deleted old backup: ${backups[i].path}
        } catch (e) {
          // Failed to delete ${backups[i].path}: $e
        }
      }
    }
  }

  /// Εκτελεί validation του backup file
  Future<bool> _validateBackupFile(File file) async {
    try {
      // Έλεγχος μεγέθους
      if (await file.length() == 0) {
        // Validation failed - empty file
        return false;
      }

      // Έλεγχος ότι το JSON είναι valid
      final content = await file.readAsString(encoding: utf8);
      final data = jsonDecode(content);
      
      // Έλεγχος ότι έχει τα απαραίτητα keys
      if (data is! Map<String, dynamic>) {
        // Validation failed - invalid JSON structure
        return false;
      }

      final requiredKeys = ['vehicles', 'drivers', 'fuel_entries', 'service_entries'];
      for (final key in requiredKeys) {
        if (!data.containsKey(key)) {
          // Validation failed - missing key: $key
          return false;
        }
      }

      // Validation passed
      return true;
    } catch (e) {
      // Validation failed - exception: $e
      return false;
    }
  }

  /// Εκτελεί αυτόματο backup με validation και rotation
  Future<bool> createAutoBackup() async {
    try {
      // Log: Starting auto backup...
      final dir = await _ensureBackupsDir();

      // Συλλογή δεδομένων
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
            'currencyCode': e.currencyCode,
          }).toList();

      final payload = jsonEncode({
        'vehicles': vehicles,
        'drivers': drivers,
        'fuel_entries': fuelEntries,
        'service_entries': serviceEntries,
      });

      // Δημιουργία αρχείου με auto_ prefix
      final filename = 'auto_${_timestamp()}.json';
      final file = File('${dir.path}${Platform.pathSeparator}$filename');
      
      await file.create(recursive: true);
      await file.writeAsString(payload, encoding: utf8);
      // File written: ${file.path}

      // Post-write validation
      if (!await _validateBackupFile(file)) {
        // Validation failed, deleting file
        await file.delete();
        return false;
      }

      // Rotation - κράτα μόνο τα 2 πιο πρόσφατα
      await _rotateAutoBackups();

      // Completed successfully
      return true;
    } catch (e) {
      // Failed with exception: $e
      return false;
    }
  }
}

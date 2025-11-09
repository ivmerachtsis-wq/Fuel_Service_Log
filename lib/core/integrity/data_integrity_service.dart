import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../cache/models/cached_state.dart';
import '../../data/models/vehicle.dart';
import '../../data/models/driver.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/service_entry.dart';
import 'package:hive/hive.dart';

class IntegrityResult {
  final bool ok;
  final Map<String, String> snapshotChecksums;
  final Map<String, String> hiveChecksums;
  final List<String> mismatches;

  IntegrityResult({
    required this.ok,
    required this.snapshotChecksums,
    required this.hiveChecksums,
    required this.mismatches,
  });
}

/// Validates that snapshot checksums match the live Hive box contents.
/// If snapshot is null, returns ok=false with no mismatches (caller can ignore).
class DataIntegrityService {
  Future<IntegrityResult> validate(CachedState? snapshot) async {
    final snapSums = <String, String>{};
    final hiveSums = <String, String>{};
    final mismatches = <String>[];

    final boxes = <String, List<Map<String, dynamic>>>{
      'vehicles': Hive.box<Vehicle>('vehicles')
          .values
          .map((v) => {
                'id': v.id,
                'title': v.title,
                'plate': v.plate,
                'active': v.active,
              })
          .toList(),
      'drivers': Hive.box<Driver>('drivers')
          .values
          .map((d) => {
                'id': d.id,
                'name': d.name,
              })
          .toList(),
      'fuel_entries': Hive.box<FuelEntry>('fuel_entries')
          .values
          .map((e) => {
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
              })
          .toList(),
      'service_entries': Hive.box<ServiceEntry>('service_entries')
          .values
          .map((e) => {
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
              })
          .toList(),
    };

    // Compute hive checksums
    for (final e in boxes.entries) {
      hiveSums[e.key] = _checksum(e.value);
    }

    // Snapshot checksums (if present)
    if (snapshot != null) {
      for (final e in snapshot.boxes.entries) {
        snapSums[e.key] = e.value.checksum;
      }
    }

    // Compare
    for (final boxName in hiveSums.keys) {
      final s = snapSums[boxName];
      final h = hiveSums[boxName]!;
      if (s == null || s != h) {
        mismatches.add(boxName);
      }
    }

    return IntegrityResult(
      ok: mismatches.isEmpty && snapshot != null,
      snapshotChecksums: snapSums,
      hiveChecksums: hiveSums,
      mismatches: mismatches,
    );
  }

  String _checksum(List<Map<String, dynamic>> items) {
    // Stable JSON (keys sorted) then MD5
    final normalized = items
        .map((m) {
          final keys = m.keys.toList()..sort();
          return {for (final k in keys) k: m[k]};
        })
        .toList();
    final payload = jsonEncode(normalized);
    return md5.convert(utf8.encode(payload)).toString();
  }
}

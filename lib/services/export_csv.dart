import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../data/repo/fuel_repo.dart';
import '../data/repo/service_repo.dart';

class ExportCsvService {
  final _fuelRepo = FuelRepo();
  final _serviceRepo = ServiceRepo();

  Future<Directory> _ensureExportsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exports = Directory('${dir.path}${Platform.pathSeparator}FuelServiceLog${Platform.pathSeparator}exports');
    if (!exports.existsSync()) {
      exports.createSync(recursive: true);
    }
    return exports;
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<File> exportFuelToCsv(String vehicleId) async {
    final dir = await _ensureExportsDir();
    final entries = _fuelRepo.listByVehicle(vehicleId);
    final rows = <List<dynamic>>[];
    
    // Headers με currencyCode
    rows.add(const [
      'id',
      'vehicleId',
      'date',
      'odometerKm',
      'liters',
      'pricePerLiter',
      'amount',
      'fullTank',
      'currencyCode',
      'notes',
    ]);
    
    for (final e in entries) {
      // Date σε ISO format: yyyy-MM-dd
      final dateStr = '${e.date.year.toString().padLeft(4, '0')}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      
      rows.add([
        e.id,
        e.vehicleId,
        dateStr,
        e.odometerKm,
        e.liters,
        e.pricePerLiter,
        e.amount,
        e.fullTank,
        e.currencyCode ?? '',
        e.notes ?? '',
      ]);
    }
    
    final csv = const ListToCsvConverter().convert(rows);
    final file = File('${dir.path}${Platform.pathSeparator}fuel_${vehicleId}_${_timestamp()}.csv');
    
    // Write as UTF-8 with BOM for Excel/Notepad compatibility
    const bom = [0xEF, 0xBB, 0xBF];
    final contentBytes = utf8.encode(csv);
    final bytes = <int>[...bom, ...contentBytes];
    await file.writeAsBytes(bytes, flush: true);
    
    return file;
  }

  Future<File> exportServiceToCsv(String vehicleId) async {
    final dir = await _ensureExportsDir();
    final entries = _serviceRepo.listByVehicle(vehicleId);
    final rows = <List<dynamic>>[];
    
    // Headers με currencyCode
    rows.add(const [
      'id',
      'vehicleId',
      'date',
      'odometerKm',
      'description',
      'totalAmount',
      'currencyCode',
      'notes',
    ]);
    
    for (final e in entries) {
      // Date σε ISO format: yyyy-MM-dd
      final dateStr = '${e.date.year.toString().padLeft(4, '0')}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      
      rows.add([
        e.id,
        e.vehicleId,
        dateStr,
        e.odometerKm,
        e.description,
        e.totalAmount,
        e.currencyCode ?? '',
        e.notes ?? '',
      ]);
    }
    
    final csv = const ListToCsvConverter().convert(rows);
    final file = File('${dir.path}${Platform.pathSeparator}service_${vehicleId}_${_timestamp()}.csv');
    
    // Write as UTF-8 with BOM for Excel/Notepad compatibility
    const bom = [0xEF, 0xBB, 0xBF];
    final contentBytes = utf8.encode(csv);
    final bytes = <int>[...bom, ...contentBytes];
    await file.writeAsBytes(bytes, flush: true);
    
    return file;
  }
}

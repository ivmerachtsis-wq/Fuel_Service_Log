import 'package:flutter/material.dart';
import '../../services/export_csv.dart';
import '../../services/backup_restore.dart';
import '../../state/active_vehicle_controller.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final exportSvc = ExportCsvService();
    final backupSvc = BackupRestoreService();
    final active = ActiveVehicleController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          subtitle: Text('General preferences'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Export CSV (active vehicle)'),
          subtitle: const Text('Fuel & Service entries as CSV files'),
          onTap: () async {
            try {
              final vehicleId = await active.getActiveVehicleId();
              final fuelPath = await exportSvc.exportFuelToCsv(vehicleId);
              final servicePath = await exportSvc.exportServiceToCsv(vehicleId);
              _showSnack(context, 'Εξαγωγή ολοκληρώθηκε: \n$fuelPath\n$servicePath');
            } catch (e) {
              _showSnack(context, 'Σφάλμα εξαγωγής: $e');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup JSON'),
          onTap: () async {
            try {
              final path = await backupSvc.exportToJson();
              _showSnack(context, 'Backup δημιουργήθηκε: $path');
            } catch (e) {
              _showSnack(context, 'Σφάλμα backup: $e');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restore JSON (last backup)'),
          subtitle: const Text('Εισαγωγή από το τελευταίο αρχείο στο backups'),
          onTap: () async {
            try {
              // Βρίσκουμε το πιο πρόσφατο backup στο φάκελο μας
              final path = await _latestBackupPath();
              if (path == null) {
                _showSnack(context, 'Δεν βρέθηκε backup');
                return;
              }
              await backupSvc.importFromJson(path);
              _showSnack(context, 'Restore ολοκληρώθηκε');
            } catch (e) {
              _showSnack(context, 'Σφάλμα restore: $e');
            }
          },
        ),
      ],
    );
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

Future<String?> _latestBackupPath() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final backups = Directory('${dir.path}${Platform.pathSeparator}FuelServiceLog${Platform.pathSeparator}backups');
    if (!backups.existsSync()) return null;
    final files = backups
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (files.isEmpty) return null;
    return files.first.path;
  } catch (_) {
    return null;
  }
}

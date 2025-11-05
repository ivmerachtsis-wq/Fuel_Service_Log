import 'package:flutter/material.dart';
import '../../services/export_csv.dart';
import '../../services/backup_restore.dart';
import '../../state/active_vehicle_controller.dart';
import '../../state/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsTab extends StatelessWidget {
  final SettingsController settings;
  const SettingsTab({required this.settings, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exportSvc = ExportCsvService();
    final backupSvc = BackupRestoreService();
    final active = ActiveVehicleController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(l10n.settingsTitle),
          subtitle: const Text('General preferences'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.payments),
          title: Text(l10n.currency),
          trailing: DropdownButton<String>(
            value: settings.currencyCode,
            items: [
              DropdownMenuItem(value: 'EUR', child: Text(l10n.currencyEUR)),
              DropdownMenuItem(value: 'USD', child: Text(l10n.currencyUSD)),
              DropdownMenuItem(value: 'GBP', child: Text(l10n.currencyGBP)),
            ],
            onChanged: (value) {
              if (value != null) {
                settings.setCurrency(value);
              }
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          trailing: DropdownButton<String>(
            value: settings.currentLocale.languageCode,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'el', child: Text('Ελληνικά')),
            ],
            onChanged: (value) {
              if (value != null) {
                settings.setLocale(Locale(value));
              }
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: Text(l10n.exportCsv),
          subtitle: const Text('Fuel & Service entries as CSV files'),
          onTap: () async {
            try {
              final vehicleId = await active.getActiveVehicleId();
              await exportSvc.exportFuelToCsv(vehicleId);
              await exportSvc.exportServiceToCsv(vehicleId);
              if (context.mounted) {
                _showSnack(context, l10n.successExport);
              }
            } catch (e) {
              if (context.mounted) {
                _showSnack(context, 'Error: $e');
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: Text(l10n.backupJson),
          onTap: () async {
            try {
              await backupSvc.exportToJson();
              if (context.mounted) {
                _showSnack(context, l10n.successBackup);
              }
            } catch (e) {
              if (context.mounted) {
                _showSnack(context, 'Error: $e');
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: Text(l10n.restoreJson),
          subtitle: const Text('Εισαγωγή από το τελευταίο αρχείο στο backups'),
          onTap: () async {
            try {
              // Βρίσκουμε το πιο πρόσφατο backup στο φάκελο μας
              final path = await _latestBackupPath();
              if (path == null) {
                if (context.mounted) {
                  _showSnack(context, 'Δεν βρέθηκε backup');
                }
                return;
              }
              await backupSvc.importFromJson(path);
              if (context.mounted) {
                _showSnack(context, l10n.successRestore);
              }
            } catch (e) {
              if (context.mounted) {
                _showSnack(context, 'Error: $e');
              }
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

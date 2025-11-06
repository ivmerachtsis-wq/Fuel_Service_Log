import 'package:flutter/material.dart';
import '../../services/export_csv.dart';
import '../../services/backup_restore.dart';
import '../../services/data_integrity_service.dart';
import '../../data/repo/fuel_repo.dart';
import '../../data/repo/service_repo.dart';
import '../../state/active_vehicle_controller.dart';
import '../../state/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/app_version.dart';
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
          subtitle: Text(l10n.settingsGeneral),
        ),
        const Divider(),
        // Version Info
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.version),
          trailing: Text(appVersion, style: Theme.of(context).textTheme.bodyMedium),
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
            items: [
              DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
              DropdownMenuItem(value: 'el', child: Text(l10n.languageGreek)),
            ],
            onChanged: (value) {
              if (value != null) {
                settings.setLocale(Locale(value));
              }
            },
          ),
        ),
        const Divider(),
        
        // Data Integrity & Maintenance Section
        ListTile(
          leading: const Icon(Icons.verified_user),
          title: Text(l10n.settingsMaintenance),
          subtitle: Text(l10n.runIntegrityCheck),
        ),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(l10n.runIntegrityCheck),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () async {
            _runIntegrityCheck(context);
          },
        ),
        const Divider(),
        
        ListTile(
          leading: const Icon(Icons.file_download),
          title: Text(l10n.exportCsv),
          subtitle: Text(AppLocalizations.of(context)!.settingsExportCsvSubtitle),
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
              final ok = await backupSvc.exportToJson();
              if (context.mounted) {
                _showSnack(context, ok ? l10n.successBackup : 'Error');
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
          subtitle: Text(AppLocalizations.of(context)!.settingsRestoreSubtitle),
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

  static Future<void> _runIntegrityCheck(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final settings = SettingsController();
      final fuelRepo = FuelRepo();
      final serviceRepo = ServiceRepo();
      
      final report = await DataIntegrityService.runFullCheck(
        settings: settings,
        fuelRepo: fuelRepo,
        serviceRepo: serviceRepo,
      );
      
      if (!context.mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (report.ok) {
        // Καμία issue
        _showSnack(context, l10n.integrityOk);
      } else {
        // Εμφάνιση dialog με issues
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.integrityReportTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fuel: ${report.fuelCount}, Service: ${report.serviceCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.integrityIssuesFound}: ${report.issues.length}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...report.issues.map((issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $issue',
                          style: const TextStyle(fontSize: 13),
                        ),
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading
      _showSnack(context, 'Error: $e');
    }
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

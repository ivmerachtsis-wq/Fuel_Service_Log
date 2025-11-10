import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:hive/hive.dart';
import '../../data/models/vehicle.dart';
import '../../data/models/driver.dart';
import '../../services/export_csv.dart';
import '../../services/backup_restore.dart';
import '../../services/export_pdf.dart';
import '../../services/data_integrity_service.dart';
import '../../data/repo/fuel_repo.dart';
import '../../data/repo/service_repo.dart';
import '../../state/active_vehicle_controller.dart';
import '../../state/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/app_version.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/service_entry.dart';
import '../../features/exports/pdf/active_vehicle_report.dart';
import '../../state/stats_cache_provider.dart';
import '../../features/stats/stats_cache.dart';
import 'package:open_filex/open_filex.dart';

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
        // Appearance Section
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n.appearance),
          subtitle: Text(l10n.theme),
        ),
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: Text(l10n.theme),
          trailing: DropdownButton<ThemeMode>(
            value: settings.themeMode,
            items: [
              DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.themeSystem)),
              DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.themeLight)),
              DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.themeDark)),
            ],
            onChanged: (value) {
              if (value != null) {
                settings.setThemeMode(value);
              }
            },
          ),
        ),
        const Divider(),
        // Performance Section
        ListTile(
          leading: const Icon(Icons.speed),
          title: Text(l10n.useSnapshotCache),
          subtitle: Text(l10n.useSnapshotCacheDesc),
          trailing: Switch(
            value: settings.useSnapshotCache,
            onChanged: (value) {
              settings.setUseSnapshotCache(value);
            },
          ),
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
              final fuelFile = await exportSvc.exportFuelToCsv(vehicleId);
              await exportSvc.exportServiceToCsv(vehicleId);
              
              if (context.mounted) {
                final fuelName = p.basename(fuelFile.path);
                final folder = p.dirname(fuelFile.path);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.exportSuccess}: $fuelName + service CSV'),
                    action: SnackBarAction(
                      label: l10n.openFolder,
                      onPressed: () async {
                        final uri = Uri.file(folder);
                        await launchUrl(uri);
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                _showSnack(context, 'Error: $e');
              }
            }
          },
        ),
        // PDF Fuel Export
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: Text(l10n.exportFuelPdf),
          onTap: () async {
            try {
              final vehicleId = await active.getActiveVehicleId();
              final fuelRepo = FuelRepo();
              final vehicleBox = Hive.box<Vehicle>('vehicles');
              final driverBox = Hive.box<Driver>('drivers');
              final vehicle = vehicleBox.get(vehicleId);
              // Επιλογή πρώτου οδηγού (placeholder) – μελλοντική σύνδεση active driver.
              final driver = driverBox.values.isNotEmpty ? driverBox.values.first : null;
              final entries = fuelRepo.listByVehicle(vehicleId).toList()..sort((a,b)=>a.date.compareTo(b.date));
              final file = await ExportPdfService.exportFuelToPdf(
                vehicleId: vehicleId,
                entries: entries,
                vehicle: vehicle,
                driver: driver,
              );
              if (context.mounted) {
                final name = p.basename(file.path);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.exportSuccess}: $name')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                _showSnack(context, 'Error: $e');
              }
            }
          },
        ),
        // PDF Service Export
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: Text(l10n.exportServicePdf),
          onTap: () async {
            try {
              final vehicleId = await active.getActiveVehicleId();
              final serviceRepo = ServiceRepo();
              final vehicleBox = Hive.box<Vehicle>('vehicles');
              final driverBox = Hive.box<Driver>('drivers');
              final vehicle = vehicleBox.get(vehicleId);
              final driver = driverBox.values.isNotEmpty ? driverBox.values.first : null;
              final entries = serviceRepo.listByVehicle(vehicleId).toList()..sort((a,b)=>a.date.compareTo(b.date));
              final file = await ExportPdfService.exportServiceToPdf(
                vehicleId: vehicleId,
                entries: entries,
                vehicle: vehicle,
                driver: driver,
              );
              if (context.mounted) {
                final name = p.basename(file.path);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.exportSuccess}: $name')),
                );
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
              final file = await backupSvc.exportToJson();
              if (context.mounted) {
                if (file != null) {
                  final fileName = p.basename(file.path);
                  final folder = p.dirname(file.path);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.successBackup}: $fileName'),
                      action: SnackBarAction(
                        label: l10n.openFolder,
                        onPressed: () async {
                          final uri = Uri.file(folder);
                          await launchUrl(uri);
                        },
                      ),
                    ),
                  );
                } else {
                  _showSnack(context, 'Error: Backup failed');
                }
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
        const Divider(),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: Text(l10n.exportPdfActiveVehicle),
          subtitle: Text(l10n.activeVehicleReport),
          onTap: () async {
            try {
              final vehicleBox = Hive.box<Vehicle>('vehicles');
              if (vehicleBox.values.isEmpty) {
                if (context.mounted) _showSnack(context, l10n.noActiveVehicle);
                return;
              }
              final vehicle = vehicleBox.values.firstWhere(
                (v) => v.active,
                orElse: () => vehicleBox.values.first,
              );
              // Collect last entries for tables
              final fuelBox = Hive.box<FuelEntry>('fuel_entries');
              final serviceBox = Hive.box<ServiceEntry>('service_entries');
              final fuel = fuelBox.values.where((e) => e.vehicleId == vehicle.id).toList()
                ..sort((a,b)=>b.date.compareTo(a.date));
              final service = serviceBox.values.where((e) => e.vehicleId == vehicle.id).toList()
                ..sort((a,b)=>b.date.compareTo(a.date));

              // KPIs via StatsCache
              final now = DateTime.now();
              final from = DateTime(now.year, now.month - 5, 1); // last 6 months window
              final to = DateTime(now.year, now.month, 31);
              final statsCache = StatsCacheProvider().cache;
              final Kpis k = await statsCache.getKpis(
                vehicleId: vehicle.id,
                from: from,
                to: to,
                months: 6,
                driverId: null,
              );
              final kpis = StatsKpis(
                avgConsumption: k.avgConsumptionLPer100km,
                costPerKm: k.costPerKm,
                monthlyCost: k.monthlyCost,
              );

              final bytes = await buildActiveVehicleReport(
                v: vehicle,
                fuel: fuel,
                service: service,
                kpis: kpis,
                l10n: l10n,
                currencyCode: settings.currencyCode,
              );
              Directory? downloads;
              try { downloads = await getDownloadsDirectory(); } catch (_) {}
              downloads ??= await getApplicationDocumentsDirectory();
              final datePart = DateTime.now().toIso8601String().split('T').first;
              final platePart = (vehicle.plate ?? vehicle.title).replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
              final filePath = '${downloads.path}/ActiveVehicle_${platePart}_$datePart.pdf';
              final file = File(filePath);
              await file.writeAsBytes(bytes, flush: true);
              debugPrint('[PDF] Saved active vehicle report to $filePath');
              if (context.mounted) {
                _showSnack(context, 'Saved PDF to $filePath');
              }
              // Optional: open the file for the user
              try { await OpenFilex.open(filePath); } catch (_) {}
            } catch (e) {
              if (context.mounted) _showSnack(context, 'Error: $e');
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

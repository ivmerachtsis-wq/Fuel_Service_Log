import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_controller.dart';
import '../../utils/currency_formatter.dart';
import '../service/service_form.dart';
import '../widgets/app_dialogs.dart';
import '../../data/models/service_entry.dart';
import '../../data/models/vehicle.dart';
import '../../data/repo/service_repo.dart';
import '../../services/ui_prefs_service.dart';
import '../../state/active_vehicle_controller.dart';
import '../widgets/vehicle_filter_bar.dart';

class ServiceTab extends StatefulWidget {
  final SettingsController settings;
  final UiPrefs? uiPrefs;
  const ServiceTab({required this.settings, this.uiPrefs, super.key});

  @override
  State<ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends State<ServiceTab> {
  final _repo = ServiceRepo();
  late final ActiveVehicleController _activeController;
  VehicleFilter _vehicleFilter = VehicleFilter.active();
  bool _loading = true;

  UiPrefs get _uiPrefs => widget.uiPrefs ?? UiPrefsService();

  @override
  void initState() {
    super.initState();
    _activeController = ActiveVehicleController();
    _loadState();
  }

  Future<void> _loadState() async {
    final filter = _uiPrefs.loadServiceVehicleFilter();
    if (mounted) {
      setState(() {
        _vehicleFilter = filter;
        _loading = false;
      });
    }
  }

  Future<void> _handleFilterChanged(VehicleFilter filter) async {
    setState(() {
      _vehicleFilter = filter;
    });
    await _uiPrefs.saveServiceVehicleFilter(filter.scope, filter.specificVehicleId);
  }

  List<ServiceEntry> _applyFilter(List<ServiceEntry> entries, String? activeVehicleId) {
    switch (_vehicleFilter.scope) {
      case VehicleFilterScope.active:
        return entries.where((e) => e.vehicleId == activeVehicleId).toList();
      case VehicleFilterScope.all:
        return entries;
      case VehicleFilterScope.specific:
        final vid = _vehicleFilter.specificVehicleId;
        return vid == null
            ? entries
            : entries.where((e) => e.vehicleId == vid).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<String?>(
      valueListenable: _activeController.activeVehicleIdNotifier,
      builder: (context, activeVehicleId, _) {
        if (activeVehicleId == null) {
          return Center(child: Text(AppLocalizations.of(context)!.noActiveVehicle));
        }

        return Stack(
          children: [
            Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: Hive.box<Vehicle>('vehicles').listenable(),
                  builder: (context, Box<Vehicle> box, _) {
                    final vehicles = box.values.toList()
                      ..sort((a, b) => a.title.compareTo(b.title));
                    return VehicleFilterBar(
                      activeVehicleId: activeVehicleId,
                      vehicles: vehicles,
                      currentFilter: _vehicleFilter,
                      onFilterChanged: _handleFilterChanged,
                    );
                  },
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box<ServiceEntry>('service_entries').listenable(),
                    builder: (context, Box<ServiceEntry> box, _) {
                      final allEntries = box.values.toList()
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final items = _applyFilter(allEntries, activeVehicleId);

                      if (items.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context)!.serviceNoEntries));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final e = items[i];
                          final currency = e.currencyCode ?? widget.settings.currencyCode;
                          return Dismissible(
                            key: ValueKey(e.id),
                            background: Container(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: Icon(Icons.delete, color: Colors.red[900]),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              final deleted = e;
                              await _repo.delete(e.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.deleted),
                                  action: SnackBarAction(
                                    label: AppLocalizations.of(context)!.actionUndo,
                                    onPressed: () async {
                                      await _repo.add(deleted);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              child: ListTile(
                                key: ValueKey(e.id),
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                title: Text(
                                  e.description,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(e.date)}  •  ${e.odometerKm.toStringAsFixed(1)} km',
                                ),
                                trailing: Text(
                                  formatCurrency(e.totalAmount, currencyCode: currency, context: context),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                onTap: () => _showForm(context, activeVehicleId, entry: e),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => _showForm(context, activeVehicleId),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }  Future<void> _showForm(BuildContext context, String? activeVehicleId, {ServiceEntry? entry}) async {
    if (activeVehicleId == null) return;

    await showFormSheet(
      context,
      entry == null
          ? ServiceForm.add(vehicleId: activeVehicleId, settings: widget.settings)
          : ServiceForm.edit(initial: entry, settings: widget.settings),
    );
  }
}

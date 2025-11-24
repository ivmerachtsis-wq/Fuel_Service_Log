import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_controller.dart';
import '../../services/ui_prefs_service.dart';
import '../../utils/currency_formatter.dart';
import '../fuel/fuel_form.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/vehicle_filter_bar.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/vehicle.dart';
import '../../data/repo/fuel_repo.dart';
import '../../state/active_vehicle_controller.dart';

class FuelTab extends StatefulWidget {
  final SettingsController settings;
  final UiPrefs? uiPrefs; // Optional DI for tests
  const FuelTab({required this.settings, this.uiPrefs, super.key});

  @override
  State<FuelTab> createState() => _FuelTabState();
}

class _FuelTabState extends State<FuelTab> {
  final _repo = FuelRepo();
  late final UiPrefs _uiPrefs;
  late final ActiveVehicleController _activeController;
  VehicleFilter _vehicleFilter = const VehicleFilter.active();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _uiPrefs = widget.uiPrefs ?? UiPrefsService();
    _activeController = ActiveVehicleController();
    _loadState();
  }

  Future<void> _loadState() async {
    final filter = _uiPrefs.loadFuelVehicleFilter();

    if (mounted) {
      setState(() {
        _vehicleFilter = filter;
        _loading = false;
      });
    }
  }

  Future<void> _handleFilterChanged(VehicleFilter newFilter) async {
    setState(() => _vehicleFilter = newFilter);
    
    // Persist filter
    await _uiPrefs.saveFuelVehicleFilter(newFilter.scope, newFilter.specificVehicleId);
  }

  List<FuelEntry> _applyFilter(Box<FuelEntry> box, String? activeVehicleId) {
    List<FuelEntry> items;
    
    if (_vehicleFilter.scope == VehicleFilterScope.active) {
      if (activeVehicleId == null) return [];
      items = box.values.where((e) => e.vehicleId == activeVehicleId).toList();
    } else if (_vehicleFilter.scope == VehicleFilterScope.all) {
      items = box.values.toList();
    } else {
      // Specific vehicle
      final vehicleId = _vehicleFilter.specificVehicleId;
      if (vehicleId == null) return [];
      items = box.values.where((e) => e.vehicleId == vehicleId).toList();
    }
    
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<String?>(
      valueListenable: _activeController.activeVehicleIdNotifier,
      builder: (context, activeVehicleId, _) {
        return Stack(
          children: [
            Column(
              children: [
                // Vehicle filter bar
                ValueListenableBuilder(
                  valueListenable: Hive.box<Vehicle>('vehicles').listenable(),
                  builder: (context, Box<Vehicle> vehiclesBox, _) {
                    final vehicles = vehiclesBox.values.toList()
                      ..sort((a, b) => a.title.compareTo(b.title));
                    
                    return VehicleFilterBar(
                      currentFilter: _vehicleFilter,
                      activeVehicleId: activeVehicleId,
                      vehicles: vehicles,
                      onFilterChanged: _handleFilterChanged,
                    );
                  },
                ),
                const Divider(height: 1),
                // Entries list
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box<FuelEntry>('fuel_entries').listenable(),
                    builder: (context, Box<FuelEntry> box, _) {
                      final items = _applyFilter(box, activeVehicleId);
                      
                      if (items.isEmpty) {
                        return Center(child: Text(l10n.noFuelEntries));
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
                                  content: Text(l10n.deleted),
                                  action: SnackBarAction(
                                    label: l10n.actionUndo,
                                    onPressed: () async {
                                      await _repo.add(deleted);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${e.liters.toStringAsFixed(0)}L'),
                                ),
                                title: Text(DateFormat.yMd().format(e.date)),
                                subtitle: Text(
                                  '${e.odometerKm.toStringAsFixed(0)} km • ${formatCurrency(e.amount, currencyCode: currency, context: context)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showForm(context, activeVehicleId, entry: e),
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
  }

  Future<void> _showForm(BuildContext context, String? activeVehicleId, {FuelEntry? entry}) async {
    if (activeVehicleId == null) return;

    await showFormSheet(
      context,
      entry == null
          ? FuelForm.add(vehicleId: activeVehicleId, settings: widget.settings)
          : FuelForm.edit(initial: entry, settings: widget.settings),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_controller.dart';
import '../../utils/currency_formatter.dart';
import '../fuel/fuel_form.dart';
import '../widgets/app_dialogs.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/repo/fuel_repo.dart';
import '../../state/active_vehicle_controller.dart';

class FuelTab extends StatefulWidget {
  final SettingsController settings;
  const FuelTab({required this.settings, super.key});

  @override
  State<FuelTab> createState() => _FuelTabState();
}

class _FuelTabState extends State<FuelTab> {
  final _repo = FuelRepo();
  String? _vehicleId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveVehicle();
  }

  Future<void> _loadActiveVehicle() async {
    final id = await ActiveVehicleController().getActiveVehicleId();
    if (mounted) {
      setState(() {
        _vehicleId = id;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicleId == null) {
      return Center(child: Text(l10n.noActiveVehicle));
    }

    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: Hive.box<FuelEntry>('fuel_entries').listenable(),
          builder: (context, Box<FuelEntry> box, _) {
            // Φιλτράρισμα και ταξινόμηση
            final items = box.values
                .where((e) => e.vehicleId == _vehicleId)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            
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
                      key: ValueKey(e.id),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      title: Text(
                        '${e.liters.toStringAsFixed(2)} ${l10n.liters}  @  ${formatCurrency(e.pricePerLiter, currencyCode: currency, context: context)} / L',
                      ),
                      subtitle: Text(
                        '${DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(e.date)}  •  ${e.odometerKm.toStringAsFixed(1)} km',
                      ),
                      trailing: Text(
                        formatCurrency(e.amount, currencyCode: currency, context: context),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () async {
                        await showFormSheet(context, FuelForm.edit(initial: e, settings: widget.settings));
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: () async {
              await showFormSheet(context, FuelForm.add(vehicleId: _vehicleId!, settings: widget.settings));
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_controller.dart';
import '../../utils/currency_formatter.dart';
import '../service/service_form.dart';
import '../widgets/app_dialogs.dart';
import '../../data/models/service_entry.dart';
import '../../data/repo/service_repo.dart';
import '../../state/active_vehicle_controller.dart';

class ServiceTab extends StatefulWidget {
  final SettingsController settings;
  const ServiceTab({required this.settings, super.key});

  @override
  State<ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends State<ServiceTab> {
  final _repo = ServiceRepo();
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicleId == null) {
      return Center(child: Text(AppLocalizations.of(context)!.noActiveVehicle));
    }

    return Stack(
      children: [
        StreamBuilder<List<ServiceEntry>>(
          stream: _repo.watchByVehicle(_vehicleId!),
          initialData: _repo.listByVehicle(_vehicleId!),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <ServiceEntry>[];
            
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
                  background: Container(color: Colors.redAccent.withValues(alpha: 0.2)),
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
                      onTap: () async {
                        await showFormSheet(context, ServiceForm.edit(initial: e, settings: widget.settings));
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
              await showFormSheet(context, ServiceForm.add(vehicleId: _vehicleId!, settings: widget.settings));
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

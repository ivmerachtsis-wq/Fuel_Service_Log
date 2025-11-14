import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/vehicle.dart';
import '../../state/settings_controller.dart';
import '../../l10n/app_localizations.dart';

class VehiclesTab extends StatelessWidget {
  final SettingsController settings;
  const VehiclesTab({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final box = Hive.box<Vehicle>('vehicles');
    final vehicles = box.values.toList(growable: false);

    if (vehicles.isEmpty) {
      return Center(child: Text(l10n.noActiveVehicle));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, i) {
        final v = vehicles[i];
        final active = settings.activeVehicleId == v.id;
        return Card(
          child: ListTile(
            leading: Icon(Icons.directions_car, color: active ? Theme.of(context).colorScheme.primary : null),
            title: Text(v.title ?? v.id),
            subtitle: Text(v.plate ?? ''),
            trailing: active ? const Icon(Icons.star, color: Colors.amber) : null,
            onTap: () {
              settings.setActiveVehicle(v.id);
            },
          ),
        );
      },
    );
  }
}

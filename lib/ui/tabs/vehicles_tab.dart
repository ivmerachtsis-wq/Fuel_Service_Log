import 'package:flutter/material.dart';
import '../../data/models/vehicle.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../l10n/app_localizations.dart';

class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<Box<Vehicle>>(
      valueListenable: Hive.box<Vehicle>('vehicles').listenable(),
      builder: (context, box, _) {
        final vehicles = box.values.toList(growable: false);
        if (vehicles.isEmpty) {
          return Center(child: Text(l10n.noActiveVehicle));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, i) {
            final v = vehicles[i];
            final active = v.active;
            return Card(
              child: ListTile(
                leading: Icon(Icons.directions_car, color: active ? Theme.of(context).colorScheme.primary : null),
                title: Text(v.title),
                subtitle: Text(v.plate ?? ''),
                trailing: active ? const Icon(Icons.star, color: Colors.amber) : null,
                onTap: () async {
                  // Toggle active vehicle: set this one active, others false
                  final all = box.values.toList();
                  for (final existing in all) {
                    final shouldBeActive = existing.id == v.id;
                    if (existing.active != shouldBeActive) {
                      final updated = Vehicle(
                        id: existing.id,
                        title: existing.title,
                        plate: existing.plate,
                        active: shouldBeActive,
                        currencyCode: existing.currencyCode,
                      );
                      await box.put(existing.id, updated);
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

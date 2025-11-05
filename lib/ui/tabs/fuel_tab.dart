import 'package:flutter/material.dart';
import '../../../state/settings_controller.dart';
import '../../../utils/currency_formatter.dart';

import '../fuel/fuel_form.dart';
import '../widgets/app_dialogs.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/repo/fuel_repo.dart';
import '../../../state/active_vehicle_controller.dart';

class FuelTab extends StatelessWidget {
  final SettingsController settings;
  const FuelTab({required this.settings, super.key});

  @override
  Widget build(BuildContext context) {
    final repo = FuelRepo();
    final active = ActiveVehicleController();

    return FutureBuilder<String>(
      future: active.getActiveVehicleId(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final vehicleId = snap.data;
        if (vehicleId == null) {
          return const Center(child: Text('No active vehicle'));
        }

        return Stack(
          children: [
            StreamBuilder<List<FuelEntry>>(
              stream: repo.watchByVehicle(vehicleId),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <FuelEntry>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No fuel entries yet'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = items[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${e.liters.toStringAsFixed(2)} L  @  '
                          '${formatCurrency(e.pricePerLiter, currencyCode: settings.currencyCode, context: context)} / L',
                        ),
                        subtitle: Text('${e.date.toLocal().toString().split('.').first}  •  ${e.odometerKm.toStringAsFixed(0)} km'),
                        trailing: Text(
                          formatCurrency(e.amount, currencyCode: settings.currencyCode, context: context),
                        ),
                        onTap: () async {
                          // Placeholder για Edit: άνοιγμα ίδιας φόρμας με αρχικές τιμές
                          await showFormSheet(context, FuelForm.edit(initial: e));
                        },
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
                  await showFormSheet(context, FuelForm.add(vehicleId: vehicleId));
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

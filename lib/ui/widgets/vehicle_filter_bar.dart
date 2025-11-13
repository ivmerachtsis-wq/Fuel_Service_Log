import 'package:flutter/material.dart';
import '../../data/models/vehicle.dart';
import '../../l10n/app_localizations.dart';

/// Filter scope for vehicle selection
enum VehicleFilterScope {
  active,  // Active vehicle only
  all,     // All vehicles
  specific // Specific vehicle by ID
}

/// Vehicle filter state
class VehicleFilter {
  final VehicleFilterScope scope;
  final String? specificVehicleId;

  const VehicleFilter({
    required this.scope,
    this.specificVehicleId,
  });

  const VehicleFilter.active() : scope = VehicleFilterScope.active, specificVehicleId = null;
  const VehicleFilter.all() : scope = VehicleFilterScope.all, specificVehicleId = null;
  VehicleFilter.specific(String vehicleId) : scope = VehicleFilterScope.specific, specificVehicleId = vehicleId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleFilter &&
          runtimeType == other.runtimeType &&
          scope == other.scope &&
          specificVehicleId == other.specificVehicleId;

  @override
  int get hashCode => scope.hashCode ^ specificVehicleId.hashCode;
}

/// Reusable vehicle filter bar widget matching Stats tab style
class VehicleFilterBar extends StatelessWidget {
  final VehicleFilter currentFilter;
  final String? activeVehicleId;
  final List<Vehicle> vehicles;
  final ValueChanged<VehicleFilter> onFilterChanged;

  const VehicleFilterBar({
    required this.currentFilter,
    required this.activeVehicleId,
    required this.vehicles,
    required this.onFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Build dropdown value based on current filter
    String? dropdownValue;
    if (currentFilter.scope == VehicleFilterScope.active) {
      dropdownValue = '__active__';
    } else if (currentFilter.scope == VehicleFilterScope.all) {
      dropdownValue = '__all__';
    } else {
      dropdownValue = currentFilter.specificVehicleId;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            l10n.filterVehicle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: dropdownValue,
              isExpanded: true,
              items: [
                // Active vehicle option
                DropdownMenuItem(
                  value: '__active__',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n.filtersVehicleActive),
                    ],
                  ),
                ),
                // All vehicles option
                DropdownMenuItem(
                  value: '__all__',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 18, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(l10n.filtersVehicleAll),
                    ],
                  ),
                ),
                const DropdownMenuItem(
                  value: '__divider__',
                  enabled: false,
                  child: Divider(),
                ),
                // Individual vehicles
                for (final vehicle in vehicles)
                  DropdownMenuItem(
                    value: vehicle.id,
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 18,
                          color: vehicle.id == activeVehicleId
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vehicle.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vehicle.id == activeVehicleId)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null || value == '__divider__') return;

                VehicleFilter newFilter;
                if (value == '__active__') {
                  newFilter = const VehicleFilter.active();
                } else if (value == '__all__') {
                  newFilter = const VehicleFilter.all();
                } else {
                  newFilter = VehicleFilter.specific(value);
                }

                onFilterChanged(newFilter);
              },
            ),
          ),
        ],
      ),
    );
  }
}

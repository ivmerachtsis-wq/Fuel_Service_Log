import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/ui/widgets/vehicle_filter_bar.dart';

void main() {
  group('Service Vehicle Filter', () {
    late UiPrefsMemory prefs;

    setUp(() {
      prefs = UiPrefsMemory();
    });

    test('default filter is active vehicle', () {
      final filter = prefs.loadServiceVehicleFilter();
      expect(filter.scope, VehicleFilterScope.active);
      expect(filter.specificVehicleId, isNull);
    });

    test('saves and loads active vehicle filter', () async {
      await prefs.saveServiceVehicleFilter(VehicleFilterScope.active, null);
      final filter = prefs.loadServiceVehicleFilter();
      expect(filter.scope, VehicleFilterScope.active);
      expect(filter.specificVehicleId, isNull);
    });

    test('saves and loads all vehicles filter', () async {
      await prefs.saveServiceVehicleFilter(VehicleFilterScope.all, null);
      final filter = prefs.loadServiceVehicleFilter();
      expect(filter.scope, VehicleFilterScope.all);
      expect(filter.specificVehicleId, isNull);
    });

    test('saves and loads specific vehicle filter', () async {
      await prefs.saveServiceVehicleFilter(
        VehicleFilterScope.specific,
        'vehicle-789',
      );
      final filter = prefs.loadServiceVehicleFilter();
      expect(filter.scope, VehicleFilterScope.specific);
      expect(filter.specificVehicleId, 'vehicle-789');
    });

    test('persisted filter survives preference reloads', () async {
      await prefs.saveServiceVehicleFilter(
        VehicleFilterScope.specific,
        'service-vehicle',
      );
      
      // Simulate reload
      final filter1 = prefs.loadServiceVehicleFilter();
      final filter2 = prefs.loadServiceVehicleFilter();
      
      expect(filter1.scope, filter2.scope);
      expect(filter1.specificVehicleId, filter2.specificVehicleId);
    });

    test('switching between filters preserves correct state', () async {
      // Save active
      await prefs.saveServiceVehicleFilter(VehicleFilterScope.active, null);
      var filter = prefs.loadServiceVehicleFilter();
      expect(filter.scope, VehicleFilterScope.active);

      // Switch to all
      await prefs.saveServiceVehicleFilter(VehicleFilterScope.all, null);
      filter = prefs.loadServiceVehicleFilter();
      expect(filter.scope, VehicleFilterScope.all);

      // Switch to specific
      await prefs.saveServiceVehicleFilter(
        VehicleFilterScope.specific,
        'truck-1',
      );
      filter = prefs.loadServiceVehicleFilter();
      expect(filter.scope, VehicleFilterScope.specific);
      expect(filter.specificVehicleId, 'truck-1');
    });

    test('fuel and service filters are independent', () async {
      // Save different filters for fuel and service
      await prefs.saveFuelVehicleFilter(VehicleFilterScope.all, null);
      await prefs.saveServiceVehicleFilter(
        VehicleFilterScope.specific,
        'car-1',
      );

      // Verify they don't interfere
      final fuelFilter = prefs.loadFuelVehicleFilter();
      final serviceFilter = prefs.loadServiceVehicleFilter();

      expect(fuelFilter.scope, VehicleFilterScope.all);
      expect(fuelFilter.specificVehicleId, isNull);

      expect(serviceFilter.scope, VehicleFilterScope.specific);
      expect(serviceFilter.specificVehicleId, 'car-1');
    });
  });
}

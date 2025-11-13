import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/ui/widgets/vehicle_filter_bar.dart';

void main() {
  group('Fuel Vehicle Filter', () {
    late UiPrefsMemory prefs;

    setUp(() {
      prefs = UiPrefsMemory();
    });

    test('default filter is active vehicle', () {
      final filter = prefs.loadFuelVehicleFilter();
      expect(filter.scope, VehicleFilterScope.active);
      expect(filter.specificVehicleId, isNull);
    });

    test('saves and loads active vehicle filter', () async {
      await prefs.saveFuelVehicleFilter(VehicleFilterScope.active, null);
      final filter = prefs.loadFuelVehicleFilter();
      expect(filter.scope, VehicleFilterScope.active);
      expect(filter.specificVehicleId, isNull);
    });

    test('saves and loads all vehicles filter', () async {
      await prefs.saveFuelVehicleFilter(VehicleFilterScope.all, null);
      final filter = prefs.loadFuelVehicleFilter();
      expect(filter.scope, VehicleFilterScope.all);
      expect(filter.specificVehicleId, isNull);
    });

    test('saves and loads specific vehicle filter', () async {
      await prefs.saveFuelVehicleFilter(
        VehicleFilterScope.specific,
        'vehicle-123',
      );
      final filter = prefs.loadFuelVehicleFilter();
      expect(filter.scope, VehicleFilterScope.specific);
      expect(filter.specificVehicleId, 'vehicle-123');
    });

    test('VehicleFilter.active() creates active scope filter', () {
      final filter = VehicleFilter.active();
      expect(filter.scope, VehicleFilterScope.active);
      expect(filter.specificVehicleId, isNull);
    });

    test('VehicleFilter.all() creates all scope filter', () {
      final filter = VehicleFilter.all();
      expect(filter.scope, VehicleFilterScope.all);
      expect(filter.specificVehicleId, isNull);
    });

    test('VehicleFilter.specific() creates specific scope filter', () {
      final filter = VehicleFilter.specific('vehicle-456');
      expect(filter.scope, VehicleFilterScope.specific);
      expect(filter.specificVehicleId, 'vehicle-456');
    });

    test('persisted filter survives preference reloads', () async {
      await prefs.saveFuelVehicleFilter(
        VehicleFilterScope.specific,
        'test-vehicle',
      );
      
      // Simulate reload
      final filter1 = prefs.loadFuelVehicleFilter();
      final filter2 = prefs.loadFuelVehicleFilter();
      
      expect(filter1.scope, filter2.scope);
      expect(filter1.specificVehicleId, filter2.specificVehicleId);
    });

    test('switching between filters preserves correct state', () async {
      // Save active
      await prefs.saveFuelVehicleFilter(VehicleFilterScope.active, null);
      var filter = prefs.loadFuelVehicleFilter();
      expect(filter.scope, VehicleFilterScope.active);

      // Switch to all
      await prefs.saveFuelVehicleFilter(VehicleFilterScope.all, null);
      filter = prefs.loadFuelVehicleFilter();
      expect(filter.scope, VehicleFilterScope.all);

      // Switch to specific
      await prefs.saveFuelVehicleFilter(
        VehicleFilterScope.specific,
        'my-car',
      );
      filter = prefs.loadFuelVehicleFilter();
      expect(filter.scope, VehicleFilterScope.specific);
      expect(filter.specificVehicleId, 'my-car');
    });
  });
}

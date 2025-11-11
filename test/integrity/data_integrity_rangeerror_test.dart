import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/repo/fuel_repo.dart';
import 'package:fuel_service_log/data/repo/service_repo.dart';
import 'package:fuel_service_log/services/data_integrity_service.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:hive/hive.dart';

void main() {
  group('DataIntegrity RangeError guard (#26)', () {
    late FuelRepo fuelRepo;
    late ServiceRepo serviceRepo;
    late SettingsController settings;

    setUpAll(() async {
      // Initialize Hive with temporary directory for tests
      Hive.init('./test_hive_temp_integrity');
      Hive.registerAdapter(FuelEntryAdapter());
      Hive.registerAdapter(ServiceEntryAdapter());
      
      // Open the boxes that repos expect
      await Hive.openBox<FuelEntry>('fuel_entries');
      await Hive.openBox<ServiceEntry>('service_entries');
      await Hive.openBox('settings');
    });

    setUp(() async {
      fuelRepo = FuelRepo();
      serviceRepo = ServiceRepo();
      settings = SettingsController();
      await settings.init();
      
      // Clear data before each test
      final fuelBox = Hive.box<FuelEntry>('fuel_entries');
      final serviceBox = Hive.box<ServiceEntry>('service_entries');
      await fuelBox.clear();
      await serviceBox.clear();
    });

    test('does not throw RangeError on short fuel entry IDs (< 8 chars)', () async {
      // Create fuel entry with very short ID (triggers substring(0, 8) RangeError)
      final shortIdEntry = FuelEntry(
        id: 'f1', // Only 2 chars - will cause RangeError in substring(0, 8)
        vehicleId: 'v1',
        date: DateTime.now(),
        odometerKm: 100,
        liters: 10,
        pricePerLiter: 1.5,
        amount: 15,
        fullTank: true,
        currencyCode: null, // Null currency triggers the code path with substring
        notes: 'Α',
      );
      
      await fuelRepo.add(shortIdEntry);

      // This should NOT throw RangeError
      final report = await DataIntegrityService.runFullCheck(
        settings: settings,
        fuelRepo: fuelRepo,
        serviceRepo: serviceRepo,
      );

      expect(report, isNotNull);
      expect(report.issues, isNotEmpty); // Should report null currency
      expect(report.fuelCount, equals(1));
      // Should not crash, just report the issue
    });

    test('does not throw RangeError on short service entry IDs (< 8 chars)', () async {
      // Create service entry with short ID and empty description
      final shortIdEntry = ServiceEntry(
        id: 's', // Only 1 char - will cause RangeError
        vehicleId: 'v1',
        date: DateTime.now(),
        odometerKm: 200,
        description: '  ', // Empty when trimmed - triggers code path
        totalAmount: 50,
        currencyCode: null, // Null currency triggers the code path with substring
        notes: null,
      );
      
      await serviceRepo.add(shortIdEntry);

      // This should NOT throw RangeError
      final report = await DataIntegrityService.runFullCheck(
        settings: settings,
        fuelRepo: fuelRepo,
        serviceRepo: serviceRepo,
      );

      expect(report, isNotNull);
      expect(report.issues.length, greaterThanOrEqualTo(2)); // Empty description + null currency
      expect(report.serviceCount, equals(1));
    });

    test('does not throw on empty ID strings', () async {
      // Edge case: completely empty ID
      final emptyIdFuel = FuelEntry(
        id: '', // Empty string - triggers 'Κενό id' but also would fail substring
        vehicleId: 'v1',
        date: DateTime.now(),
        odometerKm: 100,
        liters: 10,
        pricePerLiter: 1.5,
        amount: 15,
        currencyCode: null,
      );
      
      await fuelRepo.add(emptyIdFuel);

      final report = await DataIntegrityService.runFullCheck(
        settings: settings,
        fuelRepo: fuelRepo,
        serviceRepo: serviceRepo,
      );

      expect(report, isNotNull);
      expect(report.issues, contains(contains('Κενό id')));
    });

    test('handles mixed valid and invalid IDs without crashing', () async {
      // Mix of short and normal IDs
      await fuelRepo.add(FuelEntry(
        id: 'abc', // 3 chars
        vehicleId: 'v1',
        date: DateTime.now(),
        odometerKm: 100,
        liters: 10,
        pricePerLiter: 1.5,
        amount: 15,
        currencyCode: null,
      ));
      
      await fuelRepo.add(FuelEntry(
        id: '12345678-abcd-1234', // Normal UUID-like
        vehicleId: 'v1',
        date: DateTime.now(),
        odometerKm: 200,
        liters: 15,
        pricePerLiter: 1.6,
        amount: 24,
        currencyCode: 'EUR',
      ));

      await serviceRepo.add(ServiceEntry(
        id: 'xy', // 2 chars
        vehicleId: 'v1',
        date: DateTime.now(),
        odometerKm: 300,
        description: '', // Empty
        totalAmount: 100,
        currencyCode: null,
      ));

      final report = await DataIntegrityService.runFullCheck(
        settings: settings,
        fuelRepo: fuelRepo,
        serviceRepo: serviceRepo,
      );

      expect(report, isNotNull);
      expect(report.fuelCount, equals(2));
      expect(report.serviceCount, equals(1));
      // Should have multiple issues but no crash
      expect(report.issues.length, greaterThan(0));
    });
  });
}

import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/repo/fuel_repo.dart';
import 'package:fuel_service_log/data/repo/service_repo.dart';
import 'package:fuel_service_log/services/export_csv.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup fake method channel for path_provider
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.current.path;
      }
      return null;
    },
  );

  group('CSV UTF-8 with BOM (#25)', () {
    late FuelRepo fuelRepo;
    late ServiceRepo serviceRepo;
    late ExportCsvService exportService;

    setUpAll(() async {
      // Initialize Hive with temporary directory for tests
      Hive.init('./test_hive_temp_csv_bom');
      Hive.registerAdapter(FuelEntryAdapter());
      Hive.registerAdapter(ServiceEntryAdapter());
      
      // Open the boxes that repos expect
      await Hive.openBox<FuelEntry>('fuel_entries');
      await Hive.openBox<ServiceEntry>('service_entries');
    });

    setUp(() async {
      fuelRepo = FuelRepo();
      serviceRepo = ServiceRepo();
      exportService = ExportCsvService();
      
      // Clear data before each test
      final fuelBox = Hive.box<FuelEntry>('fuel_entries');
      final serviceBox = Hive.box<ServiceEntry>('service_entries');
      await fuelBox.clear();
      await serviceBox.clear();
    });

    test('Fuel CSV is written as UTF-8 with BOM and preserves Greek text', () async {
      // Create fuel entry with Greek text in notes
      final greekEntry = FuelEntry(
        id: 'fuel-test-1',
        vehicleId: 'v1',
        date: DateTime(2025, 11, 11),
        odometerKm: 15000,
        liters: 45.5,
        pricePerLiter: 1.65,
        amount: 75.08,
        fullTank: true,
        currencyCode: 'EUR',
        notes: 'Τακτική συντήρηση 5 - γεμάτο ρεζερβουάρ',
      );
      
      await fuelRepo.add(greekEntry);

      // Export to CSV
      final file = await exportService.exportFuelToCsv('v1');
      final bytes = await file.readAsBytes();

      // Assert BOM (UTF-8 BOM: EF BB BF)
      expect(bytes.length, greaterThan(3), reason: 'File should contain BOM + content');
      expect(bytes[0], 0xEF, reason: 'First byte of BOM should be 0xEF');
      expect(bytes[1], 0xBB, reason: 'Second byte of BOM should be 0xBB');
      expect(bytes[2], 0xBF, reason: 'Third byte of BOM should be 0xBF');

      // Decode remainder as UTF-8 (skip BOM)
      final text = utf8.decode(bytes.sublist(3));
      
      // Verify Greek text is preserved
      expect(text, contains('Τακτική συντήρηση'), reason: 'Greek text should be readable');
      expect(text, contains('γεμάτο ρεζερβουάρ'), reason: 'Greek text should be complete');
      
      // Verify headers are present
      final lines = text.split('\n');
      expect(lines.first, contains('date'), reason: 'Header row should contain "date"');
      expect(lines.first, contains('currencyCode'), reason: 'Header row should contain "currencyCode"');
      
      // Verify ISO date format (yyyy-MM-dd)
      expect(text, contains('2025-11-11'), reason: 'Date should be in ISO format');
      
      // Verify no currency symbols (amounts should be raw numbers)
      expect(text, isNot(contains('€')), reason: 'Should not contain currency symbols');
      expect(text, isNot(contains('EUR75')), reason: 'Currency code should be separate from amount');
      
      // Clean up
      await file.delete();
    });

    test('Service CSV is written as UTF-8 with BOM and preserves Greek text', () async {
      // Create service entry with Greek description
      final greekEntry = ServiceEntry(
        id: 'service-test-1',
        vehicleId: 'v1',
        date: DateTime(2025, 10, 15),
        odometerKm: 14500,
        description: 'Αλλαγή λαδιών και φίλτρων',
        totalAmount: 120.50,
        currencyCode: 'EUR',
        notes: 'Περιλαμβάνει λάδι 5W-30 συνθετικό',
      );
      
      await serviceRepo.add(greekEntry);

      // Export to CSV
      final file = await exportService.exportServiceToCsv('v1');
      final bytes = await file.readAsBytes();

      // Assert BOM
      expect(bytes.length, greaterThan(3));
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);

      // Decode as UTF-8
      final text = utf8.decode(bytes.sublist(3));
      
      // Verify Greek text
      expect(text, contains('Αλλαγή λαδιών'), reason: 'Greek description should be preserved');
      expect(text, contains('φίλτρων'), reason: 'Greek text should be complete');
      expect(text, contains('συνθετικό'), reason: 'Greek notes should be preserved');
      
      // Verify headers
      expect(text.split('\n').first, contains('description'));
      
      // Verify ISO date
      expect(text, contains('2025-10-15'));
      
      // Verify no currency symbols
      expect(text, isNot(contains('€')));
      
      // Clean up
      await file.delete();
    });

    test('CSV with mixed Greek/English and special chars preserves encoding', () async {
      // Mix of characters that could expose encoding issues
      final mixedEntry = FuelEntry(
        id: 'fuel-mixed-1',
        vehicleId: 'v1',
        date: DateTime(2025, 11, 10),
        odometerKm: 10000,
        liters: 50,
        pricePerLiter: 1.5,
        amount: 75,
        currencyCode: 'EUR',
        notes: 'Test with Ελληνικά, English, άέήίόύώ, and numbers 123',
      );
      
      await fuelRepo.add(mixedEntry);

      final file = await exportService.exportFuelToCsv('v1');
      final bytes = await file.readAsBytes();

      // BOM check
      expect(bytes.sublist(0, 3), equals([0xEF, 0xBB, 0xBF]));

      // Full decode should work without errors
      final text = utf8.decode(bytes.sublist(3));
      
      // All special Greek characters should be preserved
      expect(text, contains('Ελληνικά'));
      expect(text, contains('άέήίόύώ'));
      expect(text, contains('English'));
      expect(text, contains('123'));
      
      await file.delete();
    });
  });
}

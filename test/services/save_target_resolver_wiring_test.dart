import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/services/export_csv.dart';
import 'package:fuel_service_log/services/export_pdf.dart';
import 'package:fuel_service_log/services/backup_restore.dart';
import 'package:fuel_service_log/services/save_target_resolver.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/data/models/driver.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../fakes/fake_save_target_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup fake method channel for path_provider
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    },
  );

  group('SaveTargetResolver wiring (CSV/PDF/Backup)', () {
    late FakeSaveTargetResolver fakeResolver;
    late UiPrefsMemory fakePrefs;
    late ExportCsvService csvService;
    late ExportPdfService pdfService;
    late BackupRestoreService backupService;
    late Directory tempDir;

    setUpAll(() async {
      await Hive.initFlutter();
      Hive.registerAdapter(VehicleAdapter());
      Hive.registerAdapter(FuelEntryAdapter());
      Hive.registerAdapter(ServiceEntryAdapter());
      Hive.registerAdapter(DriverAdapter());
    });

    setUp(() async {
      fakeResolver = FakeSaveTargetResolver();
      fakePrefs = UiPrefsMemory();
      csvService = ExportCsvService(resolver: fakeResolver, prefs: fakePrefs);
      pdfService = ExportPdfService(resolver: fakeResolver, prefs: fakePrefs);
      backupService = BackupRestoreService(resolver: fakeResolver, prefs: fakePrefs);

      tempDir = await Directory.systemTemp.createTemp('save_wiring_test');
      fakeResolver.fixed = tempDir;

      // Open Hive boxes for test data
      await Hive.openBox<Vehicle>('vehicles');
      await Hive.openBox<Driver>('drivers');
      await Hive.openBox<FuelEntry>('fuel_entries');
      await Hive.openBox<ServiceEntry>('service_entries');
    });

    tearDown(() async {
      fakeResolver.reset();
      fakePrefs.storage.clear();
      await Hive.box<Vehicle>('vehicles').clear();
      await Hive.box<Driver>('drivers').clear();
      await Hive.box<FuelEntry>('fuel_entries').clear();
      await Hive.box<ServiceEntry>('service_entries').clear();
      await Hive.box<Vehicle>('vehicles').close();
      await Hive.box<Driver>('drivers').close();
      await Hive.box<FuelEntry>('fuel_entries').close();
      await Hive.box<ServiceEntry>('service_entries').close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    group('ExportCsvService', () {
      test('exportFuelToCsv honors askWhereToSave=false (uses default dir)', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final fuelBox = Hive.box<FuelEntry>('fuel_entries');
        await fuelBox.put(
          'f1',
          FuelEntry(
            id: 'f1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            liters: 50,
            pricePerLiter: 1.5,
            amount: 75,
          ),
        );

        fakePrefs.saveAskWhereToSave(false);

        final file = await csvService.exportFuelToCsv('v1');

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, false);
        expect(fakeResolver.lastKind, SaveKind.csv);
        expect(fakeResolver.lastDefaultDir, isNotNull, reason: 'Should pass exports subdirectory as defaultDir');
      });

      test('exportFuelToCsv honors askWhereToSave=true (shows picker)', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final fuelBox = Hive.box<FuelEntry>('fuel_entries');
        await fuelBox.put(
          'f1',
          FuelEntry(
            id: 'f1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            liters: 50,
            pricePerLiter: 1.5,
            amount: 75,
          ),
        );

        fakePrefs.saveAskWhereToSave(true);

        final file = await csvService.exportFuelToCsv('v1');

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, true);
        expect(fakeResolver.lastKind, SaveKind.csv);
      });

      test('exportFuelToCsv returns null when user cancels picker', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final fuelBox = Hive.box<FuelEntry>('fuel_entries');
        await fuelBox.put(
          'f1',
          FuelEntry(
            id: 'f1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            liters: 50,
            pricePerLiter: 1.5,
            amount: 75,
          ),
        );

        fakePrefs.saveAskWhereToSave(true);
        fakeResolver.simulateCancel = true;

        final file = await csvService.exportFuelToCsv('v1');

        expect(file, isNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, true);
      });

      test('exportServiceToCsv honors askWhereToSave flag', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final serviceBox = Hive.box<ServiceEntry>('service_entries');
        await serviceBox.put(
          's1',
          ServiceEntry(
            id: 's1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            description: 'Oil change',
            totalAmount: 100,
          ),
        );

        fakePrefs.saveAskWhereToSave(false);

        final file = await csvService.exportServiceToCsv('v1');

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, false);
        expect(fakeResolver.lastKind, SaveKind.csv);
      });
    });

    group('ExportPdfService', () {
      test('exportFuelToPdf honors askWhereToSave=false', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final entries = [
          FuelEntry(
            id: 'f1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            liters: 50,
            pricePerLiter: 1.5,
            amount: 75,
          ),
        ];

        fakePrefs.saveAskWhereToSave(false);

        final file = await pdfService.exportFuelToPdf(
          vehicleId: 'v1',
          entries: entries,
          vehicle: vehiclesBox.get('v1'),
          driver: null,
        );

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, false);
        expect(fakeResolver.lastKind, SaveKind.pdf);
        expect(file!.path, contains('.pdf'));
      });

      test('exportFuelToPdf honors askWhereToSave=true', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final entries = [
          FuelEntry(
            id: 'f1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            liters: 50,
            pricePerLiter: 1.5,
            amount: 75,
          ),
        ];

        fakePrefs.saveAskWhereToSave(true);

        final file = await pdfService.exportFuelToPdf(
          vehicleId: 'v1',
          entries: entries,
          vehicle: vehiclesBox.get('v1'),
          driver: null,
        );

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, true);
        expect(fakeResolver.lastKind, SaveKind.pdf);
      });

      test('exportFuelToPdf returns null on cancel', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final entries = [
          FuelEntry(
            id: 'f1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            liters: 50,
            pricePerLiter: 1.5,
            amount: 75,
          ),
        ];

        fakePrefs.saveAskWhereToSave(true);
        fakeResolver.simulateCancel = true;

        final file = await pdfService.exportFuelToPdf(
          vehicleId: 'v1',
          entries: entries,
          vehicle: vehiclesBox.get('v1'),
          driver: null,
        );

        expect(file, isNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, true);
      });

      test('exportServiceToPdf honors askWhereToSave flag', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final entries = [
          ServiceEntry(
            id: 's1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            description: 'Oil change',
            totalAmount: 100,
          ),
        ];

        fakePrefs.saveAskWhereToSave(false);

        final file = await pdfService.exportServiceToPdf(
          vehicleId: 'v1',
          entries: entries,
          vehicle: vehiclesBox.get('v1'),
          driver: null,
        );

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, false);
        expect(fakeResolver.lastKind, SaveKind.pdf);
      });
    });

    group('BackupRestoreService', () {
      test('exportToJson honors askWhereToSave=false', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));

        fakePrefs.saveAskWhereToSave(false);

        final file = await backupService.exportToJson();

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, false);
        expect(fakeResolver.lastKind, SaveKind.backup);
        expect(file!.path, contains('backup_'));
        expect(file.path, contains('.json'));
      });

      test('exportToJson honors askWhereToSave=true', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));

        fakePrefs.saveAskWhereToSave(true);

        final file = await backupService.exportToJson();

        expect(file, isNotNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, true);
        expect(fakeResolver.lastKind, SaveKind.backup);
      });

      test('exportToJson returns null on cancel', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));

        fakePrefs.saveAskWhereToSave(true);
        fakeResolver.simulateCancel = true;

        final file = await backupService.exportToJson();

        expect(file, isNull);
        expect(fakeResolver.calls, 1);
        expect(fakeResolver.lastAsk, true);
      });
    });

    group('Integration: Toggle state changes behavior', () {
      test('Toggling askWhereToSave affects subsequent exports', () async {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        await vehiclesBox.put('v1', Vehicle(id: 'v1', title: 'Test Car'));
        final fuelBox = Hive.box<FuelEntry>('fuel_entries');
        await fuelBox.put(
          'f1',
          FuelEntry(
            id: 'f1',
            vehicleId: 'v1',
            date: DateTime(2025, 1, 1),
            odometerKm: 10000,
            liters: 50,
            pricePerLiter: 1.5,
            amount: 75,
          ),
        );

        // First export with ask=false
        fakePrefs.saveAskWhereToSave(false);
        final file1 = await csvService.exportFuelToCsv('v1');
        expect(fakeResolver.lastAsk, false);

        // Reset and toggle
        fakeResolver.reset();
        fakePrefs.saveAskWhereToSave(true);

        // Second export with ask=true
        final file2 = await csvService.exportFuelToCsv('v1');
        expect(fakeResolver.lastAsk, true);

        expect(file1, isNotNull);
        expect(file2, isNotNull);
        expect(fakeResolver.calls, 1); // Only counts the second call after reset
      });
    });
  });
}

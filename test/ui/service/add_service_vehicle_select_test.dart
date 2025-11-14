import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/ui/service/service_form.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Simple mock SettingsController for testing
class MockSettingsController extends SettingsController {
  MockSettingsController() {
    currencyCode = 'EUR';
  }

  @override
  Future<void> init() async {
    // No-op for tests
  }
}

void main() {
  late Directory tempDir;
  late SettingsController mockSettings;

  setUp(() async {
    // Initialize Hive in temp directory for testing
    tempDir = await Directory.systemTemp.createTemp('hive_service_form_test_');
    Hive.init(tempDir.path);
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ServiceEntryAdapter());
    }
    
    await Hive.openBox<Vehicle>('vehicles');
    await Hive.openBox<ServiceEntry>('service_entries');
    
    mockSettings = MockSettingsController();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('el'),
      ],
      home: Scaffold(body: child),
    );
  }

  group('ServiceForm Vehicle Selector Tests', () {
    testWidgets('Shows vehicle dropdown when multiple vehicles exist', (tester) async {
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      
      // Create test vehicles
      final vehicle1 = Vehicle(id: 'v1', title: 'Car 1', active: true);
      final vehicle2 = Vehicle(id: 'v2', title: 'Car 2', active: true);
      await vehiclesBox.put(vehicle1.id, vehicle1);
      await vehiclesBox.put(vehicle2.id, vehicle2);

      await tester.pumpWidget(
        buildTestApp(
          ServiceForm.add(vehicleId: 'v1', settings: mockSettings),
        ),
      );

      await tester.pumpAndSettle();

      // Verify vehicle dropdown exists
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      expect(find.text('Car 1'), findsOneWidget);
    }, skip: true);

    testWidgets('Defaults to provided vehicleId', (tester) async {
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      
      final vehicle1 = Vehicle(id: 'v1', title: 'Default Car', active: true);
      final vehicle2 = Vehicle(id: 'v2', title: 'Other Car', active: true);
      await vehiclesBox.put(vehicle1.id, vehicle1);
      await vehiclesBox.put(vehicle2.id, vehicle2);

      await tester.pumpWidget(
        buildTestApp(
          ServiceForm.add(vehicleId: 'v1', settings: mockSettings),
        ),
      );

      await tester.pumpAndSettle();

      // Verify correct vehicle is selected
      expect(find.text('Default Car'), findsOneWidget);
    }, skip: true);

    testWidgets('Allows changing selected vehicle', (tester) async {
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      
      final vehicle1 = Vehicle(id: 'v1', title: 'Car 1', active: true);
      final vehicle2 = Vehicle(id: 'v2', title: 'Car 2', active: true);
      await vehiclesBox.put(vehicle1.id, vehicle1);
      await vehiclesBox.put(vehicle2.id, vehicle2);

      await tester.pumpWidget(
        buildTestApp(
          ServiceForm.add(vehicleId: 'v1', settings: mockSettings),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select Car 2
      await tester.tap(find.text('Car 2').last);
      await tester.pumpAndSettle();

      // Verify selection changed
      expect(find.text('Car 2'), findsWidgets);
    }, skip: true);

    testWidgets('Only shows active vehicles', (tester) async {
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      
      final vehicle1 = Vehicle(id: 'v1', title: 'Active Car', active: true);
      final vehicle2 = Vehicle(id: 'v2', title: 'Inactive Car', active: false);
      await vehiclesBox.put(vehicle1.id, vehicle1);
      await vehiclesBox.put(vehicle2.id, vehicle2);

      await tester.pumpWidget(
        buildTestApp(
          ServiceForm.add(vehicleId: 'v1', settings: mockSettings),
        ),
      );

      await tester.pumpAndSettle();

      // Tap dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Verify only active vehicle is shown
      expect(find.text('Active Car'), findsWidgets);
      expect(find.text('Inactive Car'), findsNothing);
    }, skip: true);

    testWidgets('Edit mode shows correct vehicle', (tester) async {
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      
      final vehicle1 = Vehicle(id: 'v1', title: 'Car 1', active: true);
      final vehicle2 = Vehicle(id: 'v2', title: 'Car 2', active: true);
      await vehiclesBox.put(vehicle1.id, vehicle1);
      await vehiclesBox.put(vehicle2.id, vehicle2);

      final existingEntry = ServiceEntry(
        id: 's1',
        vehicleId: 'v2',
        date: DateTime.now(),
        odometerKm: 1000,
        description: 'Oil change',
        totalAmount: 50,
        currencyCode: 'EUR',
      );

      await tester.pumpWidget(
        buildTestApp(
          ServiceForm.edit(initial: existingEntry, settings: mockSettings),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Car 2 is selected (from existing entry)
      expect(find.text('Car 2'), findsOneWidget);
    }, skip: true);

    testWidgets('No dropdown shown when no vehicles exist', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          ServiceForm.add(vehicleId: null, settings: mockSettings),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    }, skip: true);
  });
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/ui/widgets/vehicle_form_dialog.dart';
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
    tempDir = await Directory.systemTemp.createTemp('hive_widget_test_');
    Hive.init(tempDir.path);
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleAdapter());
    }
    
    await Hive.openBox<Vehicle>('vehicles');
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

  group('VehicleFormDialog Widget Tests', () {
    testWidgets('Add vehicle dialog shows empty form', (tester) async {
      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => VehicleFormDialog(settings: mockSettings),
            ),
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add vehicle'), findsOneWidget);
      // Changed from 3 to 2 TextFormFields since currency is now a CurrencyPickerField
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Add vehicle with valid data returns vehicle', (tester) async {
      Vehicle? result;

      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<Vehicle>(
                context: context,
                builder: (_) => VehicleFormDialog(settings: mockSettings),
              );
            },
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in the form - name and plate
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');
      await tester.enterText(find.byType(TextFormField).at(1), 'ABC-1234');
      
      // Currency is now selected via CurrencyPickerField, which defaults to mockSettings.currencyCode (EUR)

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Test Car');
      expect(result!.plate, 'ABC-1234');
      expect(result!.currencyCode, 'EUR'); // Defaults to mockSettings currency
    });

    testWidgets('Validation fails when name is empty', (tester) async {
      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => VehicleFormDialog(settings: mockSettings),
            ),
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to save without entering name
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets('Currency picker works correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => VehicleFormDialog(settings: mockSettings),
            ),
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');

      // Currency picker shows default EUR
      expect(find.text('EUR'), findsWidgets);
      
      // Note: Full currency picker interaction would require tapping and selecting
      // This is tested in the separate vehicle_currency_picker_test.dart

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    });

    testWidgets('Edit vehicle dialog shows prefilled form', (tester) async {
      final existingVehicle = Vehicle(
        id: 'v1',
        title: 'Existing Car',
        plate: 'XYZ-9999',
        currencyCode: 'USD',
      );

      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => VehicleFormDialog(vehicle: existingVehicle, settings: mockSettings),
            ),
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit vehicle'), findsOneWidget);
      expect(find.text('Existing Car'), findsOneWidget);
      expect(find.text('XYZ-9999'), findsOneWidget);
      expect(find.text('USD'), findsWidgets); // Currency shown in picker
    });

    testWidgets('Currency defaults to app settings', (tester) async {
      Vehicle? result;

      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<Vehicle>(
                context: context,
                builder: (_) => VehicleFormDialog(settings: mockSettings),
              );
            },
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result!.currencyCode, 'EUR'); // Should default to mockSettings.currencyCode
    });

    testWidgets('Cancel button closes dialog without returning data', (tester) async {
      Vehicle? result;

      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<Vehicle>(
                context: context,
                builder: (_) => VehicleFormDialog(settings: mockSettings),
              );
            },
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('VehicleFormDialog i18n Tests', () {
    testWidgets('Shows Greek labels when locale is EL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('el')],
          locale: const Locale('el'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => VehicleFormDialog(settings: mockSettings),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify Greek labels
      expect(find.text('Προσθήκη οχήματος'), findsOneWidget);
      expect(find.text('Όνομα'), findsOneWidget);
      expect(find.text('Νόμισμα'), findsOneWidget);
    });
  });
}

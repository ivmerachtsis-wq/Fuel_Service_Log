import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/ui/widgets/vehicle_form_dialog.dart';
import 'package:fuel_service_log/ui/widgets/currency_picker_field.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Simple mock SettingsController for testing
class MockSettingsController extends SettingsController {
  MockSettingsController({String currency = 'EUR'}) {
    currencyCode = currency;
  }

  @override
  Future<void> init() async {
    // No-op for tests
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    // Initialize Hive in temp directory for testing
    tempDir = await Directory.systemTemp.createTemp('hive_currency_test_');
    Hive.init(tempDir.path);
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleAdapter());
    }
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

  group('CurrencyPickerField Tests', () {
    testWidgets('Shows currency picker dialog on tap', (tester) async {
      String? selectedCurrency;

      await tester.pumpWidget(
        buildTestApp(
          CurrencyPickerField(
            value: 'EUR',
            onChanged: (value) => selectedCurrency = value,
          ),
        ),
      );

      // Tap the picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Currency'), findsWidgets);
      expect(find.text('Euro'), findsOneWidget);
      expect(find.text('US Dollar'), findsOneWidget);
      expect(find.text('British Pound'), findsOneWidget);
    });

    testWidgets('Search filters currencies correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CurrencyPickerField(
            value: 'EUR',
            onChanged: (_) {},
          ),
        ),
      );

      // Open picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'USD');
      await tester.pumpAndSettle();

      // Verify filtered results
      expect(find.text('US Dollar'), findsOneWidget);
      expect(find.text('Euro'), findsNothing);
    });

    testWidgets('Selecting currency updates value', (tester) async {
      String? selectedCurrency;

      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return CurrencyPickerField(
                value: selectedCurrency ?? 'EUR',
                onChanged: (value) => setState(() => selectedCurrency = value),
              );
            },
          ),
        ),
      );

      // Open picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Select USD
      await tester.tap(find.text('US Dollar'));
      await tester.pumpAndSettle();

      // Verify currency was selected
      expect(selectedCurrency, 'USD');
    });

    testWidgets('Clear button clears search', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CurrencyPickerField(
            value: 'EUR',
            onChanged: (_) {},
          ),
        ),
      );

      // Open picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'USD');
      await tester.pumpAndSettle();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Verify search is cleared and all currencies shown
      expect(find.text('Euro'), findsOneWidget);
      expect(find.text('US Dollar'), findsOneWidget);
    });
  });

  group('VehicleFormDialog Currency Integration Tests', () {
    testWidgets('Vehicle form defaults to app currency', (tester) async {
      final mockSettings = MockSettingsController(currency: 'USD');

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => VehicleFormDialog(settings: mockSettings),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify USD is shown (default from settings)
      expect(find.text('USD'), findsWidgets);
    });

    testWidgets('Vehicle form allows changing currency', (tester) async {
      final mockSettings = MockSettingsController();
      Vehicle? result;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<Vehicle>(
                  context: context,
                  builder: (_) => VehicleFormDialog(settings: mockSettings),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in name
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');

      // Open currency picker
      await tester.tap(find.byType(CurrencyPickerField));
      await tester.pumpAndSettle();

      // Select GBP
      await tester.tap(find.text('British Pound'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify currency was set
      expect(result!.currencyCode, 'GBP');
    });

    testWidgets('Edit vehicle shows correct currency', (tester) async {
      final mockSettings = MockSettingsController();
      final existingVehicle = Vehicle(
        id: 'v1',
        title: 'Test Car',
        currencyCode: 'JPY',
      );

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => VehicleFormDialog(
                  vehicle: existingVehicle,
                  settings: mockSettings,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify JPY is shown
      expect(find.text('JPY'), findsWidgets);
    });

    testWidgets('Currency picker search by symbol works', (tester) async {
      final mockSettings = MockSettingsController();

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => VehicleFormDialog(settings: mockSettings),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Open currency picker
      await tester.tap(find.byType(CurrencyPickerField));
      await tester.pumpAndSettle();

      // Find the search TextField in the currency picker dialog
      final searchField = find.descendant(
        of: find.byType(Dialog).last,
        matching: find.byType(TextField),
      );

      // Search by symbol
      await tester.enterText(searchField.first, '£');
      await tester.pumpAndSettle();

      // Should find British Pound
      expect(find.text('British Pound'), findsOneWidget);
    });

    testWidgets('Currency picker search is case insensitive', (tester) async {
      final mockSettings = MockSettingsController();

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => VehicleFormDialog(settings: mockSettings),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Open currency picker
      await tester.tap(find.byType(CurrencyPickerField));
      await tester.pumpAndSettle();

      // Find the search TextField in the currency picker dialog
      final searchField = find.descendant(
        of: find.byType(Dialog).last,
        matching: find.byType(TextField),
      );

      // Search with lowercase
      await tester.enterText(searchField.first, 'euro');
      await tester.pumpAndSettle();

      // Should find Euro
      expect(find.text('Euro'), findsOneWidget);
    });
  });
}

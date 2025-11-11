import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/ui/widgets/vehicle_form_dialog.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Initialize Hive in temp directory for testing
    tempDir = await Directory.systemTemp.createTemp('hive_widget_test_');
    Hive.init(tempDir.path);
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleAdapter());
    }
    
    await Hive.openBox<Vehicle>('vehicles');
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
              builder: (_) => const VehicleFormDialog(),
            ),
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add vehicle'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('Add vehicle with valid data returns vehicle', (tester) async {
      Vehicle? result;

      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<Vehicle>(
                context: context,
                builder: (_) => const VehicleFormDialog(),
              );
            },
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in the form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');
      await tester.enterText(find.byType(TextFormField).at(1), 'ABC-1234');
      await tester.enterText(find.byType(TextFormField).at(2), 'EUR');

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Test Car');
      expect(result!.plate, 'ABC-1234');
      expect(result!.currencyCode, 'EUR');
    });

    testWidgets('Validation fails when name is empty', (tester) async {
      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const VehicleFormDialog(),
            ),
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to save without entering name
      await tester.enterText(find.byType(TextFormField).at(2), 'EUR');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets('Validation fails when currency is not 3 letters', (tester) async {
      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const VehicleFormDialog(),
            ),
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');
      await tester.enterText(find.byType(TextFormField).at(2), 'EU'); // Only 2 letters

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('3-letter currency code'), findsOneWidget);
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
              builder: (_) => VehicleFormDialog(vehicle: existingVehicle),
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
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('Currency code is uppercased', (tester) async {
      Vehicle? result;

      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<Vehicle>(
                context: context,
                builder: (_) => const VehicleFormDialog(),
              );
            },
            child: const Text('Show Dialog'),
          ),
        )),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Car');
      await tester.enterText(find.byType(TextFormField).at(2), 'eur'); // lowercase

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result!.currencyCode, 'EUR'); // Should be uppercased
    });

    testWidgets('Cancel button closes dialog without returning data', (tester) async {
      Vehicle? result;

      await tester.pumpWidget(
        buildTestApp(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<Vehicle>(
                context: context,
                builder: (_) => const VehicleFormDialog(),
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
                  builder: (_) => const VehicleFormDialog(),
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

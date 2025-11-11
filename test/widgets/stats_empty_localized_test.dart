import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';

/// Issue #30: Widget test for localized "No data in selected filters"
/// Validates that the stats_noDataInSelectedFilters key renders correctly in UI
void main() {
  group('Stats empty localized widget (issue #30)', () {
    testWidgets('displays Greek "No data" text in EL locale', (WidgetTester tester) async {
      // Arrange: MaterialApp with Greek locale
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('el'),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final l10n = AppLocalizations.of(context)!;
                return Center(
                  child: Text(l10n.stats_noDataInSelectedFilters),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Greek text should be displayed
      expect(
        find.text('Δεν υπάρχουν δεδομένα για τα επιλεγμένα φίλτρα'),
        findsOneWidget,
        reason: 'Greek localized text should be rendered in EL locale',
      );
    });

    testWidgets('displays English "No data" text in EN locale', (WidgetTester tester) async {
      // Arrange: MaterialApp with English locale
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final l10n = AppLocalizations.of(context)!;
                return Center(
                  child: Text(l10n.stats_noDataInSelectedFilters),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: English text should be displayed
      expect(
        find.text('No data in selected filters'),
        findsOneWidget,
        reason: 'English localized text should be rendered in EN locale',
      );
    });

    testWidgets('locale switching changes displayed text', (WidgetTester tester) async {
      // Arrange: Start with EN locale
      const enLocale = Locale('en');
      const elLocale = Locale('el');
      
      late void Function(Locale) setLocale;
      Locale currentLocale = enLocale;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setLocale = (Locale newLocale) {
              setState(() {
                currentLocale = newLocale;
              });
            };

            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: currentLocale,
              home: Scaffold(
                body: Builder(
                  builder: (BuildContext context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.stats_noDataInSelectedFilters),
                        ElevatedButton(
                          onPressed: () {
                            setLocale(currentLocale == enLocale ? elLocale : enLocale);
                          },
                          child: const Text('Switch'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Initially shows English
      expect(find.text('No data in selected filters'), findsOneWidget);
      expect(find.text('Δεν υπάρχουν δεδομένα για τα επιλεγμένα φίλτρα'), findsNothing);

      // Act: Switch locale
      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      // Assert: Now shows Greek
      expect(find.text('No data in selected filters'), findsNothing);
      expect(find.text('Δεν υπάρχουν δεδομένα για τα επιλεγμένα φίλτρα'), findsOneWidget);
    });
  });
}

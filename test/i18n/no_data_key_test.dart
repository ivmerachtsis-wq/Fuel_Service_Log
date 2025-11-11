import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:fuel_service_log/l10n/app_localizations_en.dart';
import 'package:fuel_service_log/l10n/app_localizations_el.dart';

/// Issue #30: i18n test for "No data in selected filters" key
/// Validates that the stats_noDataInSelectedFilters key exists in EN and EL
void main() {
  group('stats_noDataInSelectedFilters i18n key (issue #30)', () {
    test('English (EN) localization has correct text', () {
      final l10n = AppLocalizationsEn();
      expect(
        l10n.stats_noDataInSelectedFilters,
        equals('No data in selected filters'),
        reason: 'EN key should match the expected English text',
      );
    });

    test('Greek (EL) localization has correct text', () {
      final l10n = AppLocalizationsEl();
      expect(
        l10n.stats_noDataInSelectedFilters,
        equals('Δεν υπάρχουν δεδομένα για τα επιλεγμένα φίλτρα'),
        reason: 'EL key should match the expected Greek text',
      );
    });

    test('Localization delegates include AppLocalizations', () {
      // Smoke test: ensure AppLocalizations.localizationsDelegates is available
      expect(AppLocalizations.localizationsDelegates, isNotEmpty);
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('el')));
    });
  });
}

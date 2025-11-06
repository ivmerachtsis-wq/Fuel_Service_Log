import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Controller for app-wide settings like language and theme
class SettingsController extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _localeKey = 'locale';
  static const String _currencyKey = 'currency';
  static const String _themeModeKey = 'themeMode';

  late Box _box;
  Locale _currentLocale = const Locale('el'); // Default to Greek
  String currencyCode = 'EUR'; // Default currency
  ThemeMode themeMode = ThemeMode.system; // Default theme mode

  Locale get currentLocale => _currentLocale;

  /// Initialize Hive box and load saved locale
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final savedLocale = _box.get(_localeKey, defaultValue: 'el') as String;
    _currentLocale = Locale(savedLocale);
    currencyCode = (_box.get(_currencyKey, defaultValue: 'EUR') as String);
    final savedTheme = (_box.get(_themeModeKey, defaultValue: 'system') as String);
    themeMode = _parseThemeMode(savedTheme);
    notifyListeners();
  }

  /// Set new locale and persist to storage
  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    await _box.put(_localeKey, locale.languageCode);
    notifyListeners();
  }

  /// Set currency code and persist
  Future<void> setCurrency(String code) async {
    if (currencyCode == code) return;
    currencyCode = code;
    await _box.put(_currencyKey, code);
    notifyListeners();
  }

  /// Θέτει νέο ThemeMode και αποθηκεύει στο Hive.
  Future<void> setThemeMode(ThemeMode m) async {
    if (themeMode == m) return;
    themeMode = m;
    await _box.put(_themeModeKey, _themeModeToString(m));
    notifyListeners();
  }

  String _themeModeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

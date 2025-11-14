import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// App theme options beyond ThemeMode
enum AppTheme {
  system,
  light,
  dark,
  comfortLight,
  midnight,
}

/// Controller for app-wide settings like language and theme
class SettingsController extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _localeKey = 'locale';
  static const String _currencyKey = 'currency';
  static const String _themeModeKey = 'themeMode';
  static const String _appThemeKey = 'appTheme';
  static const String _useSnapshotCacheKey = 'useSnapshotCache';

  late Box _box;
  Locale _currentLocale = const Locale('el'); // Default to Greek
  String currencyCode = 'EUR'; // Default currency
  ThemeMode themeMode = ThemeMode.system; // Default theme mode
  AppTheme appTheme = AppTheme.system; // Default app theme
  bool useSnapshotCache = true; // Default: enabled

  Locale get currentLocale => _currentLocale;

  /// Initialize Hive box and load saved locale
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final savedLocale = _box.get(_localeKey, defaultValue: 'el') as String;
    _currentLocale = Locale(savedLocale);
    currencyCode = (_box.get(_currencyKey, defaultValue: 'EUR') as String);
  final savedTheme = (_box.get(_themeModeKey, defaultValue: 'system') as String);
  themeMode = _parseThemeMode(savedTheme);
  final savedAppTheme = (_box.get(_appThemeKey, defaultValue: 'system') as String);
  appTheme = _parseAppTheme(savedAppTheme);
    useSnapshotCache = (_box.get(_useSnapshotCacheKey, defaultValue: true) as bool);
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

  /// Set AppTheme and persist.
  Future<void> setAppTheme(AppTheme t) async {
    if (appTheme == t) return;
    appTheme = t;
    // For backward compatibility, also update themeMode
    switch (t) {
      case AppTheme.system:
        themeMode = ThemeMode.system;
      case AppTheme.light:
      case AppTheme.comfortLight:
        themeMode = ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.midnight:
        themeMode = ThemeMode.dark;
    }
    await _box.put(_appThemeKey, _appThemeToString(t));
    await _box.put(_themeModeKey, _themeModeToString(themeMode));
    notifyListeners();
  }

  /// Set snapshot cache enabled/disabled and persist.
  Future<void> setUseSnapshotCache(bool enabled) async {
    if (useSnapshotCache == enabled) return;
    useSnapshotCache = enabled;
    await _box.put(_useSnapshotCacheKey, enabled);
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

  String _appThemeToString(AppTheme t) {
    switch (t) {
      case AppTheme.system:
        return 'system';
      case AppTheme.light:
        return 'light';
      case AppTheme.dark:
        return 'dark';
      case AppTheme.comfortLight:
        return 'comfortLight';
      case AppTheme.midnight:
        return 'midnight';
    }
  }

  AppTheme _parseAppTheme(String value) {
    switch (value) {
      case 'light':
        return AppTheme.light;
      case 'dark':
        return AppTheme.dark;
      case 'comfortLight':
        return AppTheme.comfortLight;
      case 'midnight':
        return AppTheme.midnight;
      case 'system':
      default:
        return AppTheme.system;
    }
  }
}

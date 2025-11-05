import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Controller for app-wide settings like language and theme
class SettingsController extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _localeKey = 'locale';
  static const String _currencyKey = 'currency';

  late Box _box;
  Locale _currentLocale = const Locale('el'); // Default to Greek
  String currencyCode = 'EUR'; // Default currency

  Locale get currentLocale => _currentLocale;

  /// Initialize Hive box and load saved locale
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final savedLocale = _box.get(_localeKey, defaultValue: 'el') as String;
    _currentLocale = Locale(savedLocale);
    currencyCode = (_box.get(_currencyKey, defaultValue: 'EUR') as String);
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
}

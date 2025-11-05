import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/shell.dart';
import 'state/navigation_controller.dart';
import 'state/settings_controller.dart';
import 'bootstrap/app_bootstrap.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Αρχικοποίηση Hive
  await initHive();
  
  final nav = NavigationController(0);
  final settings = SettingsController();
  await settings.init();
  
  runApp(MyApp(controller: nav, settings: settings));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller, required this.settings});

  final NavigationController controller;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Fuel & Service Log',
          debugShowCheckedModeBanner: false,
          locale: settings.currentLocale,
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
          home: Shell(controller: controller, settings: settings),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/shell.dart';
import 'state/navigation_controller.dart';
import 'state/settings_controller.dart';
import 'state/stats_cache_provider.dart';
import 'bootstrap/app_bootstrap.dart';
import 'core/diagnostics/app_start_metrics.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppStartMetrics.markT0();
  
  // Αρχικοποίηση Hive
  await initHive();
  
  final nav = NavigationController(0);
  final settings = SettingsController();
  await settings.init();
  
  AppStartMetrics.markT1(); // Snapshot hydration placeholder (L2 not wired yet)
  
  // Initialize StatsCache
  StatsCacheProvider().init();
  
  runApp(MyApp(controller: nav, settings: settings));
  
  // Post-UI initialization (Hive fully ready)
  AppStartMetrics.markT2();
  debugPrint('[AppStart] ${AppStartMetrics.summary()}');
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
          themeMode: settings.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
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

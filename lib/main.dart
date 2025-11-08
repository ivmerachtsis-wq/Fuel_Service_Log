import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/shell.dart';
import 'state/navigation_controller.dart';
import 'state/settings_controller.dart';
import 'state/stats_cache_provider.dart';
import 'bootstrap/app_bootstrap.dart';
import 'core/diagnostics/app_start_metrics.dart';
import 'l10n/app_localizations.dart';
import 'core/cache/snapshot_store.dart';
import 'core/cache/cached_services.dart';
import 'core/integrity/data_integrity_service.dart';
import 'core/cache/models/cached_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppStartMetrics.markT0();

  final settings = SettingsController();
  await settings.init();

  // Attempt snapshot preload BEFORE opening Hive boxes (fast path)
  final snapshotStore = SnapshotStore();
  snapshotStore.setEnabled(settings.useSnapshotCache);
  CachedState? snapshot;
  if (settings.useSnapshotCache) {
    snapshot = await snapshotStore.readIfValid();
  }

  // Open Hive boxes (register adapters + open) — now we can hydrate L1
  await initHive();

  // Initialize aggregated cached services with optional snapshot preload
  final cachedServices = CachedServices();
  await cachedServices.init(snapshot: snapshot);

  // t1 after L1 hydration (snapshot or direct)
  AppStartMetrics.markT1();

  // Integrity check & reconciliation
  final integrity = await DataIntegrityService().validate(snapshot);
  if (!integrity.ok) {
    debugPrint('[Integrity] Mismatches detected: ${integrity.mismatches} → fallback to Hive & rewrite snapshot');
    // Rehydrate from Hive (source of truth)
    await cachedServices.rehydrateFromHive();
    // Write fresh snapshot from current Hive state
    snapshotStore.writeNow(cachedServices.toSnapshotData());
  } else {
    debugPrint('[Integrity] Snapshot checksums match Hive');
  }

  // t2 after validation + reconciliation
  AppStartMetrics.markT2();

  // Initialize StatsCache (after caches ready)
  StatsCacheProvider().init();

  final nav = NavigationController(0);
  runApp(MyApp(controller: nav, settings: settings));

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

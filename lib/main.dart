import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/shell.dart';
import 'state/navigation_controller.dart';
import 'state/settings_controller.dart';
import 'state/stats_cache_provider.dart';
import 'state/stats_filter_controller.dart';
import 'services/ui_prefs_service.dart';
import 'bootstrap/app_bootstrap.dart';
import 'core/diagnostics/app_start_metrics.dart';
import 'l10n/app_localizations.dart';
import 'core/cache/snapshot_store.dart';
import 'core/cache/cached_services.dart';
import 'core/integrity/data_integrity_service.dart';
import 'core/cache/models/cached_state.dart';
import 'package:hive/hive.dart';
import 'data/models/vehicle.dart';
import 'data/models/fuel_entry.dart';
import 'data/models/service_entry.dart';
import 'core/cache/snapshot_auto_writer.dart';
import 'utils/test_data_loader.dart';

// Benchmark mode flag (enable with --dart-define=BENCHMARK_MODE=true)
const bool kBenchmark = bool.fromEnvironment('BENCHMARK_MODE');
// Test data mode (enable with --dart-define=TEST_DATA=true)
const bool kLoadTestData = bool.fromEnvironment('TEST_DATA');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppStartMetrics.markT0();
  // TODO(copilot): Step 1 parity scan
  // Current situation:
  // - This root lib/main.dart already boots the multi-tab Shell (Fuel / Service / Stats / Settings) for desktop.
  // - Android CI & release workflows call `flutter build apk` with default entrypoint, so Android also uses this Shell.
  // - A legacy template entrypoint still exists at fuel_service_log/lib/main.dart (counter demo) and appears unused.
  // Planned next steps:
  // - Remove/deprecate the legacy duplicate main.
  // - Confirm bottom navigation on mobile matches parity requirements.
  // - Proceed to unify shell explicitly and then hide manual ID fields.

  // Open Hive boxes (register adapters + open) - MUST be first!
  await initHive();

  // Load test data if requested
  if (kLoadTestData) {
    await loadTestData();
  }

  final settings = SettingsController();
  await settings.init();

  // Attempt snapshot preload BEFORE opening other boxes (fast path)
  final snapshotStore = SnapshotStore();
  snapshotStore.setEnabled(settings.useSnapshotCache);
  CachedState? snapshot;
  if (settings.useSnapshotCache) {
    snapshot = await snapshotStore.readIfValid();
  }

  // Synthetic data generation (only if benchmark mode)

  if (kBenchmark) {
    // Generate synthetic data only if boxes are empty (avoid duplication)
    final vehBox = Hive.box<Vehicle>('vehicles');
    if (vehBox.isEmpty) {
      vehBox.put('veh_bench', Vehicle(id: 'veh_bench', title: 'Benchmark Vehicle'));
    }
    final fuelBox = Hive.box<FuelEntry>('fuel_entries');
    final serviceBox = Hive.box<ServiceEntry>('service_entries');
    if (fuelBox.isEmpty) {
      for (int i = 0; i < 5000; i++) {
        fuelBox.put('f_$i', FuelEntry(
          id: 'f_$i',
          vehicleId: 'veh_bench',
          date: DateTime.now().subtract(Duration(days: i % 365)),
          odometerKm: 10000 + i.toDouble(),
          liters: (30 + (i % 20)).toDouble(),
          pricePerLiter: 1.7,
          amount: (30 + (i % 20)) * 1.7,
          fullTank: true,
        ));
      }
    }
    if (serviceBox.isEmpty) {
      for (int i = 0; i < 2000; i++) {
        serviceBox.put('s_$i', ServiceEntry(
          id: 's_$i',
          vehicleId: 'veh_bench',
          date: DateTime.now().subtract(Duration(days: i % 365)),
          odometerKm: 10000 + i.toDouble(),
          description: 'Service item $i',
          totalAmount: 50 + (i % 30),
        ));
      }
    }
    debugPrint('[Benchmark] Synthetic data generated: fuel=${fuelBox.length}, service=${serviceBox.length}');
  }

  // Initialize aggregated cached services with optional snapshot preload
  final cachedServices = CachedServices();
  final preloadSw = Stopwatch()..start();
  await cachedServices.init(snapshot: snapshot);

  // Start auto snapshot writer on mutations
  final autoWriter = SnapshotAutoWriter(snapshotStore, cachedServices);
  autoWriter.start();

  // t1 after L1 hydration (snapshot or direct)
  AppStartMetrics.markT1();
  preloadSw.stop();
  final preloadMs = preloadSw.elapsedMilliseconds;

  // Integrity check & reconciliation
  final integrityStart = Stopwatch()..start();
  final integrity = await DataIntegrityService().validate(snapshot);
  integrityStart.stop();
  final validationMs = integrityStart.elapsedMilliseconds;
  if (!integrity.ok) {
    debugPrint('[Integrity] Mismatches detected: ${integrity.mismatches} → fallback to Hive & rewrite snapshot');
    // Rehydrate from Hive (source of truth)
    await cachedServices.rehydrateFromHive();
    final freshState = cachedServices.toCachedState(1, '1.1.0');
    final writeMs = await snapshotStore.measureWriteState(freshState);
    if (kBenchmark) {
      debugPrint('[Benchmark] preload=${preloadMs}ms validation=${validationMs}ms write=${writeMs}ms');
    }
  } else {
    debugPrint('[Integrity] Snapshot checksums match Hive');
    if (kBenchmark) {
      // Measure write anyway for benchmarking
      final benchState = cachedServices.toCachedState(1, '1.1.0');
  final writeMs = await snapshotStore.measureWriteState(benchState);
  debugPrint('[Benchmark] preload=${preloadMs}ms validation=${validationMs}ms write=${writeMs}ms');
    }
  }

  // t2 after validation + reconciliation
  AppStartMetrics.markT2();

  // Initialize StatsCache (after caches ready)
  StatsCacheProvider().init();

  // Initialize UI preferences and stats filter controller
  final uiPrefs = UiPrefsService();
  final statsFilterController = StatsFilterController(uiPrefs);
  statsFilterController.load();

  final nav = NavigationController(0);
  runApp(MyApp(controller: nav, settings: settings, statsFilterController: statsFilterController));

  debugPrint('[AppStart] ${AppStartMetrics.summary()}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller, required this.settings, required this.statsFilterController});

  final NavigationController controller;
  final SettingsController settings;
  final StatsFilterController statsFilterController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        // Build theme variants
        final lightBase = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32), // softer green
            brightness: Brightness.light,
          ),
        );
        final comfortLight = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // calm blue
            brightness: Brightness.light,
            // Softer contrast by slightly raising surface and lowering primary container contrast
          ),
          // Soften surfaces
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          cardColor: const Color(0xFFF9FAFB),
        );
        final darkBase = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF90CAF9),
            brightness: Brightness.dark,
          ),
        );
        final midnight = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF80CBC4), // teal-ish, softer
            brightness: Brightness.dark,
          ).copyWith(
            surface: const Color(0xFF121418),
            surfaceContainer: const Color(0xFF161A1F),
            surfaceContainerHigh: const Color(0xFF1B2026),
            onSurface: const Color(0xFFE6E8EA),
          ),
          scaffoldBackgroundColor: const Color(0xFF0E1116),
          cardColor: const Color(0xFF131820),
        );

        ThemeData theme;
        ThemeData darkTheme;
        ThemeMode mode;
        switch (settings.appTheme) {
          case AppTheme.system:
            theme = lightBase;
            darkTheme = darkBase;
            mode = ThemeMode.system;
          case AppTheme.light:
            theme = lightBase;
            darkTheme = darkBase;
            mode = ThemeMode.light;
          case AppTheme.dark:
            theme = lightBase;
            darkTheme = darkBase;
            mode = ThemeMode.dark;
          case AppTheme.comfortLight:
            theme = comfortLight;
            darkTheme = darkBase;
            mode = ThemeMode.light;
          case AppTheme.midnight:
            theme = lightBase;
            darkTheme = midnight;
            mode = ThemeMode.dark;
        }

        return MaterialApp(
          title: 'Fuel & Service Log',
          debugShowCheckedModeBanner: false,
          locale: settings.currentLocale,
          themeMode: mode,
          theme: theme,
          darkTheme: darkTheme,
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
          home: Shell(controller: controller, settings: settings, statsFilterController: statsFilterController),
        );
      },
    );
  }
}

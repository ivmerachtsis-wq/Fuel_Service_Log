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
import 'package:hive/hive.dart';
import 'data/models/vehicle.dart';
import 'data/models/fuel_entry.dart';
import 'data/models/service_entry.dart';
import 'core/cache/snapshot_auto_writer.dart';

// Benchmark mode flag (enable with --dart-define=BENCHMARK_MODE=true)
const bool kBenchmark = bool.fromEnvironment('BENCHMARK_MODE');

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

  // Synthetic data generation (before Hive open) only if benchmark mode.
  // We open Hive first because we need adapters and boxes to insert.

  // Open Hive boxes (register adapters + open)
  await initHive();

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
  await cachedServices.init(snapshot: snapshot);

  // Start auto snapshot writer on mutations
  final autoWriter = SnapshotAutoWriter(snapshotStore, cachedServices);
  autoWriter.start();

  // t1 after L1 hydration (snapshot or direct)
  AppStartMetrics.markT1();

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
    debugPrint('[Benchmark] write(after-mismatch)=${writeMs}ms validation=${validationMs}ms');
  } else {
    debugPrint('[Integrity] Snapshot checksums match Hive');
    if (kBenchmark) {
      // Measure write anyway for benchmarking
      final benchState = cachedServices.toCachedState(1, '1.1.0');
      final writeMs = await snapshotStore.measureWriteState(benchState);
      debugPrint('[Benchmark] validation=${validationMs}ms write=${writeMs}ms');
    }
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

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../state/active_vehicle_controller.dart';
import '../../state/settings_controller.dart';
import '../../data/models/fuel_entry.dart';
import '../../features/stats/stats_controller.dart';

class StatsDashboard extends StatefulWidget {
  final SettingsController settings;
  const StatsDashboard({super.key, required this.settings});

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard> {
  final _stats = StatsController();
  String? _vehicleId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveVehicle();
  }

  Future<void> _loadActiveVehicle() async {
    final id = await ActiveVehicleController().getActiveVehicleId();
    if (!mounted) return;
    setState(() {
      _vehicleId = id;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(l10n.localeName);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_vehicleId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.stats_title)),
        body: Center(child: Text(l10n.noActiveVehicle)),
      );
    }

    // Reactive: ξαναχτίζουμε όταν αλλάζουν fuel_entries (και κατ' επέκταση service μέσω refresh κουμπιού αν χρειαστεί)
    return Scaffold(
      appBar: AppBar(title: Text(l10n.stats_title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder(
          valueListenable: Hive.box<FuelEntry>('fuel_entries').listenable(),
          builder: (context, box, _) {
            final avgConsumption = _stats.averageConsumptionForVehicle(_vehicleId!);
            final monthly = _stats.costPerMonth(_vehicleId!, months: 6);
            final avgServiceDays = _stats.averageServiceFrequencyDays(_vehicleId!);

            final currency = widget.settings.currencyCode;

            return ListView(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Kpi(title: l10n.kpi_fuel_consumption, value: avgConsumption > 0 ? number.format(avgConsumption) : '—'),
                    _Kpi(title: l10n.kpi_cost_per_month, value: _formatMonthlyAvg(monthly, currency, context)),
                    _Kpi(title: l10n.kpi_service_frequency, value: avgServiceDays > 0 ? '${number.format(avgServiceDays)} d' : '—'),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: SizedBox(
                    height: 240,
                    child: Center(child: Text(l10n.chart_fuel_cost_per_month)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatMonthlyAvg(Map<String, double> monthMap, String currency, BuildContext context) {
    if (monthMap.isEmpty) return '—';
    final vals = monthMap.values.where((v) => v > 0).toList();
    if (vals.isEmpty) return '—';
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    // Απλό format, αξιοποιούμε το NumberFormat currency αν χρειαστεί στο μέλλον
    return NumberFormat.simpleCurrency(name: currency).format(avg);
  }
}

class _Kpi extends StatelessWidget {
  final String title;
  final String value;
  const _Kpi({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/vehicle.dart';
import '../../data/models/driver.dart';
import '../../data/models/service_entry.dart';
import '../../domain/stats_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_controller.dart';
import '../../state/stats_cache_provider.dart';
import '../../state/stats_filter.dart';
import '../../state/stats_filter_controller.dart';
import '../../state/stats_metric.dart';
import '../../utils/currency_formatter.dart';
import '../../features/stats/pdf/stats_report_pdf.dart';
import '../../pdf/active_vehicle_report.dart';
import '../../domain/stats_aggregator.dart';

class StatsTab extends StatefulWidget {
  final SettingsController settings;
  final StatsFilterController statsFilterController;
  const StatsTab({required this.settings, required this.statsFilterController, super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  String? _selectedVehicleId;
  String? _selectedDriverId; // null ή '' => All
  final int _rangeMonths = 6; // 3 / 6 / 12 (legacy, kept for PDF export compatibility)

  // Legacy export (pre Day 12) kept for compatibility
  Future<void> _exportPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Collect stats data for PDF
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      final fuelBox = Hive.box<FuelEntry>('fuel_entries');
      final serviceBox = Hive.box<ServiceEntry>('service_entries');
      final statsService = StatsService();

      final selectedVehicle = vehiclesBox.values.firstWhere(
        (v) => v.id == _selectedVehicleId,
        orElse: () => vehiclesBox.values.first,
      );

      final allVehicleEntries = fuelBox.values
          .where((e) => e.vehicleId == _selectedVehicleId)
          .toList();

      final now = DateTime.now();
      final from12 = DateTime(now.year, now.month - 11, 1);
      final to = DateTime(now.year, now.month, 31);

      // Get consumption data
      final consumptions = statsService.getFullToFullConsumptions(
        allVehicleEntries,
        from: from12,
        to: to,
        driverId: _selectedDriverId?.isEmpty == true ? null : _selectedDriverId,
      );

      final avgConsumption = consumptions.isNotEmpty
          ? statsService.getAverageConsumption(consumptions)
          : double.nan;

      // Get monthly fuel costs (12 months)
      final monthlyCosts = statsService.getMonthlyCost(
        allVehicleEntries,
        months: 12,
        driverId: _selectedDriverId?.isEmpty == true ? null : _selectedDriverId,
        from: from12,
        to: to,
      );

      // Get service entries for 12 months
      final serviceEntries = serviceBox.values
          .where((s) => s.vehicleId == _selectedVehicleId)
          .where((s) => !s.date.isBefore(from12) && !s.date.isAfter(to))
          .toList();

      final serviceMonthMap = <String, double>{};
      for (final s in serviceEntries) {
        final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
        serviceMonthMap[key] = (serviceMonthMap[key] ?? 0) + s.totalAmount;
      }

      // Calculate service frequency (average days between services)
      double serviceFreqDays = double.nan;
      if (serviceEntries.length >= 2) {
        final sortedServices = serviceEntries.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        int totalDays = 0;
        for (int i = 1; i < sortedServices.length; i++) {
          totalDays += sortedServices[i].date.difference(sortedServices[i - 1].date).inDays;
        }
        serviceFreqDays = totalDays / (sortedServices.length - 1);
      }

      // Get current month cost (most recent)
      final currentYearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final currentFuel = monthlyCosts.firstWhere(
        (c) => c.yearMonth == currentYearMonth,
        orElse: () => MonthlyCost(yearMonth: currentYearMonth, amount: 0),
      ).amount;
      final currentService = serviceMonthMap[currentYearMonth] ?? 0;
      final costPerMonthCurrent = currentFuel + currentService;

      // Build 12-month data list
      final monthsData = <MonthlyCostData>[];
      for (int i = 0; i < 12; i++) {
        // Υπολογίζουμε από τον παλαιότερο μήνα προς τον τρέχοντα
        final monthsBack = 11 - i; // 11, 10, 9, ..., 1, 0
        final m = DateTime(now.year, now.month - monthsBack, 1);
        final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
        
        // Βρίσκουμε το αντίστοιχο fuel cost από το monthlyCosts
        final fuelCost = monthlyCosts.firstWhere(
          (c) => c.yearMonth == key,
          orElse: () => MonthlyCost(yearMonth: key, amount: 0),
        );
        final fuel = fuelCost.amount;
        final service = serviceMonthMap[key] ?? 0;
        monthsData.add(MonthlyCostData(ym: key, fuel: fuel, service: service));
      }

      final statsData = StatsData(
        vehicleName: selectedVehicle.title,
        avgLPer100: avgConsumption,
        costPerMonthCurrent: costPerMonthCurrent,
        serviceFreqDays: serviceFreqDays,
        months: monthsData,
      );

    // Prepare filename parts BEFORE any await to satisfy lints
    final locale = Localizations.localeOf(context);
    final nowDate = DateTime.now();
    final formattedDate = DateFormat.yMd(locale.toString()).format(nowDate);
      final vehicleName = selectedVehicle.title.trim();
      final vehicleNameSanitized = vehicleName.isEmpty
          ? 'vehicle'
          : vehicleName.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final sanitizedDate = formattedDate.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final langCode = locale.languageCode; // 'el' ή 'en'

      final bytes = await buildStatsPdf(
        context: context,
        data: statsData,
        currencyCode: widget.settings.currencyCode,
      );

  // Build improved filename: stats_report_<vehicle>_<localized_date>_<lang>.pdf
  final filename = 'stats_report_${vehicleNameSanitized}_${sanitizedDate}_$langCode.pdf';

      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed)),
        );
      }
    }
  }

  /// Day 12: Export filtered stats PDF with current filter & metric
  Future<void> _exportFilteredPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      final fuelBox = Hive.box<FuelEntry>('fuel_entries');
      final serviceBox = Hive.box<ServiceEntry>('service_entries');

      final selectedVehicle = vehiclesBox.values.firstWhere(
        (v) => v.id == _selectedVehicleId,
        orElse: () => vehiclesBox.values.first,
      );

      final allFuelEntries = fuelBox.values.where((e) => e.vehicleId == _selectedVehicleId).toList();
      final allServiceEntries = serviceBox.values.where((s) => s.vehicleId == _selectedVehicleId).toList();

      final input = PdfStatsReportInput(
        vehicle: selectedVehicle,
        fuelEntries: allFuelEntries,
        serviceEntries: allServiceEntries,
        filter: widget.statsFilterController.filter,
        metric: widget.statsFilterController.metric,
        noDataText: l10n.stats_noDataInSelectedFilters,
      );

      final locale = Localizations.localeOf(context);
      final nowDate = DateTime.now();
      final formattedDate = DateFormat.yMd(locale.toString()).format(nowDate);
      final vehicleName = selectedVehicle.title.trim();
      final vehicleNameSanitized = vehicleName.isEmpty
          ? 'vehicle'
          : vehicleName.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
      final sanitizedDate = formattedDate.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
      final langCode = locale.languageCode;

      final bytes = await ActiveVehiclePdfReport.build(input);
      final filename = 'filtered_stats_${vehicleNameSanitized}_${sanitizedDate}_$langCode.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed)),
        );
      }
    }
  }

  Future<void> _showCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final filter = widget.statsFilterController.filter;
    final initialFrom = filter.from ?? now.subtract(const Duration(days: 90));
    final initialTo = filter.to ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialFrom, end: initialTo),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      widget.statsFilterController.setFilter(StatsFilter.custom(picked.start, picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statsService = StatsService();
    final statsCache = StatsCacheProvider().cache;

    final vehiclesBox = Hive.box<Vehicle>('vehicles');
    if (vehiclesBox.isEmpty) {
      return Center(child: Text(l10n.noActiveVehicle));
    }
    // Ορισμός default vehicle αν δεν έχει επιλεγεί
    _selectedVehicleId ??= vehiclesBox.values.first.id;

  final fuelBox = Hive.box<FuelEntry>('fuel_entries');
  final serviceBox = Hive.box<ServiceEntry>('service_entries');
    final driversBox = Hive.box<Driver>('drivers');

    // Listen to filter controller changes
    return ListenableBuilder(
      listenable: widget.statsFilterController,
      builder: (context, _) {
        // Use ValueListenableBuilder<int> on cache revision for targeted rebuilds
        return ValueListenableBuilder<int>(
          valueListenable: statsCache.revisionForVehicle(_selectedVehicleId!),
      builder: (context, revision, _) {
            // Συλλογή όλων των fuel entries για το επιλεγμένο όχημα
            final allVehicleEntries = fuelBox.values
                .where((e) => e.vehicleId == _selectedVehicleId)
                .toList();

            // Υπολογισμός χρονικού εύρους (from, to)
            final now = DateTime.now();
            final from = DateTime(now.year, now.month - (_rangeMonths - 1), 1);
            final to = DateTime(now.year, now.month, 31); // υπερ-κάλυψη τέλους μήνα

            final consumptions = statsService.getFullToFullConsumptions(
              allVehicleEntries,
              from: from,
              to: to,
              driverId: _selectedDriverId?.isEmpty == true ? null : _selectedDriverId,
            );

            final monthlyCosts = statsService.getMonthlyCost(
              allVehicleEntries,
              months: _rangeMonths,
              driverId: _selectedDriverId?.isEmpty == true ? null : _selectedDriverId,
              from: from,
              to: to,
            );

            // Υπολογισμός Service ποσών ανά μήνα (YYYY-MM)
            final serviceEntries = serviceBox.values
                .where((s) => s.vehicleId == _selectedVehicleId)
                .where((s) => !s.date.isBefore(from) && !s.date.isAfter(to))
                .toList();
            final serviceMonthMap = <String, double>{};
            for (final s in serviceEntries) {
              final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
              serviceMonthMap[key] = (serviceMonthMap[key] ?? 0) + s.totalAmount;
            }

            final avgConsumption = consumptions.isNotEmpty
                ? statsService.getAverageConsumption(consumptions)
                : double.nan;
            final avgMonthlyCost = monthlyCosts.isNotEmpty
                ? statsService.getAverageMonthlyCost(monthlyCosts)
                : double.nan;

            // Extra KPIs using aggregator helper over current window
            // Day 11: Apply filter to window
            final filter = widget.statsFilterController.filter;
            final windowFuel = allVehicleEntries
                .where((e) => filter.includes(e.date))
                .toList();
            final windowService = serviceBox.values
                .where((s) => s.vehicleId == _selectedVehicleId)
                .where((s) => filter.includes(s.date))
                .toList();
            // Day 10: Use computeDistanceKm with fallback logic
            final distanceKmWindow = computeDistanceKm(
              fuel: windowFuel,
              service: windowService,
            );
            // Debug logging για επαλήθευση (θα αφαιρεθεί σε production)
            // ignore: avoid_print
            debugPrint('[StatsTab][Window] range=${from.toIso8601String()} -> ${to.toIso8601String()}');
            // ignore: avoid_print
            debugPrint('[StatsTab][Window] fuelEntries=${windowFuel.length}, serviceEntries=${windowService.length}');
            final sumFuelLiters = windowFuel.fold<double>(0, (s,e)=> s + e.liters);
            final sumFuelCost = windowFuel.fold<double>(0, (s,e)=> s + e.amount);
            final sumServiceCost = windowService.fold<double>(0, (s,e)=> s + e.totalAmount);
            // ignore: avoid_print
            debugPrint('[StatsTab][Window] liters=${sumFuelLiters.toStringAsFixed(2)}, fuelCost=${sumFuelCost.toStringAsFixed(2)}, serviceCost=${sumServiceCost.toStringAsFixed(2)}, distance=${distanceKmWindow.toStringAsFixed(2)}');
            final extraKpi = computeExtraKpi(
              fuelEntries: windowFuel,
              serviceEntries: windowService,
              from: from,
              to: to,
              distanceKmInWindow: distanceKmWindow,
            );
            // ignore: avoid_print
            debugPrint('[StatsTab][Window] costPerKm=${extraKpi.costPerKm.toStringAsFixed(3)}, L/100km=${extraKpi.litersPer100km.toStringAsFixed(2)}');

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Export PDF buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _exportPdf(context),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: Text(l10n.exportPdf),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _exportFilteredPdf(context),
                      icon: const Icon(Icons.filter_alt, size: 18),
                      label: const Text('Export Filtered'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFilters(
                  l10n: l10n,
                  vehiclesBox: vehiclesBox,
                  driversBox: driversBox,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _KpiBox(
                        title: l10n.kpiAvgConsumption,
                        value: avgConsumption.isNaN || avgConsumption <= 0
                            ? '—'
                            : avgConsumption.toStringAsFixed(2),
                        icon: Icons.speed,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _KpiBox(
                        title: l10n.kpiMonthlyCost,
                        value: avgMonthlyCost.isNaN || avgMonthlyCost <= 0
                            ? '—'
                            : formatCurrency(
                                avgMonthlyCost,
                                currencyCode: widget.settings.currencyCode,
                                context: context,
                              ),
                        icon: Icons.euro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiBox(
                        title: l10n.kpiCostPerKm,
                        value: distanceKmWindow <= 0 || extraKpi.costPerKm <= 0 || extraKpi.costPerKm.isNaN
                            ? '—'
                            : formatCurrency(
                                extraKpi.costPerKm,
                                currencyCode: widget.settings.currencyCode,
                                context: context,
                              ),
                        icon: Icons.route,
                        tooltip: distanceKmWindow <= 0 ? 'Ανεπαρκή δεδομένα για υπολογισμό απόστασης' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _KpiBox(
                        title: l10n.kpiLitersPer100km,
                        value: distanceKmWindow <= 0 || extraKpi.litersPer100km <= 0 || extraKpi.litersPer100km.isNaN
                            ? '—'
                            : extraKpi.litersPer100km.toStringAsFixed(2),
                        icon: Icons.local_gas_station,
                        tooltip: distanceKmWindow <= 0 ? 'Ανεπαρκή δεδομένα για υπολογισμό απόστασης' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.statsTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (consumptions.length < 2)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.chartNoData,
                            textAlign: TextAlign.center,
                             style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                   color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.70),
                                 ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.statsHintFullToFull,
                            textAlign: TextAlign.center,
                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                   color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
                                 ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 320),
                    child: SizedBox(
                      height: 320,
                      child: Padding(
                        // Add extra top/bottom padding to ensure axis labels (Date row) remain fully visible
                        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                        child: _ConsumptionChart(consumptions: consumptions),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                // Bar chart: Στοιβαγμένο κόστος/μήνα (Fuel + Service)
                (monthlyCosts.isEmpty && serviceMonthMap.isEmpty)
                    ? SizedBox(
                        height: 280,
                        child: Center(
                          child: Text(
                            l10n.chartNoData,
                             style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85)), 
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 280,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _MonthlyCostBarChart(
                              windowFuel: windowFuel,
                              windowService: windowService,
                              metric: widget.statsFilterController.metric,
                              currencyCode: widget.settings.currencyCode,
                            ),
                          ),
                        ),
                      ),
              ],
            );
      },
        );
      },
    );
  }

  Widget _buildFilters({
    required AppLocalizations l10n,
    required Box<Vehicle> vehiclesBox,
    required Box<Driver> driversBox,
  }) {
    final vehicles = vehiclesBox.values.toList();
    final drivers = driversBox.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.statsFilters, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Vehicle Dropdown
            DropdownButton<String>(
              value: _selectedVehicleId,
              items: [
                for (final v in vehicles)
                  DropdownMenuItem(
                    value: v.id,
                    child: Text(v.title),
                  ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedVehicleId = val);
                }
              },
              hint: Text(l10n.filterVehicle),
            ),
            // Driver Dropdown (All + drivers)
            DropdownButton<String>(
              value: _selectedDriverId ?? '',
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.allDrivers)),
                for (final d in drivers)
                  DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name),
                  ),
              ],
              onChanged: (val) {
                setState(() => _selectedDriverId = val);
              },
              hint: Text(l10n.filterDriver),
            ),
            // Day 11: Date range filter preset dropdown
            DropdownButton<StatsPreset>(
              value: widget.statsFilterController.filter.preset,
              items: const [
                DropdownMenuItem(value: StatsPreset.last30, child: Text('Last 30 days')),
                DropdownMenuItem(value: StatsPreset.last90, child: Text('Last 90 days')),
                DropdownMenuItem(value: StatsPreset.last180, child: Text('Last 180 days')),
                DropdownMenuItem(value: StatsPreset.ytd, child: Text('YTD')),
                DropdownMenuItem(value: StatsPreset.all, child: Text('All')),
                DropdownMenuItem(value: StatsPreset.custom, child: Text('Custom...')),
              ],
              onChanged: (val) {
                if (val == null) return;
                StatsFilter newFilter;
                switch (val) {
                  case StatsPreset.last30:
                    newFilter = StatsFilter.last30();
                  case StatsPreset.last90:
                    newFilter = StatsFilter.last90();
                  case StatsPreset.last180:
                    newFilter = StatsFilter.last180();
                  case StatsPreset.ytd:
                    newFilter = StatsFilter.ytd();
                  case StatsPreset.all:
                    newFilter = const StatsFilter.all();
                  case StatsPreset.custom:
                    // Will show dialog below
                    _showCustomDateRange(context);
                    return;
                }
                widget.statsFilterController.setFilter(newFilter);
              },
            ),
            // Day 11: Metric toggle (Cost / Liters / Distance)
            SegmentedButton<StatsMetric>(
              segments: const [
                ButtonSegment(value: StatsMetric.cost, label: Text('€'), icon: Icon(Icons.euro, size: 16)),
                ButtonSegment(value: StatsMetric.liters, label: Text('L'), icon: Icon(Icons.local_gas_station, size: 16)),
                ButtonSegment(value: StatsMetric.distance, label: Text('km'), icon: Icon(Icons.route, size: 16)),
              ],
              selected: {widget.statsFilterController.metric},
              onSelectionChanged: (Set<StatsMetric> newSelection) {
                widget.statsFilterController.setMetric(newSelection.first);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? tooltip;

  const _KpiBox({
    required this.title,
    required this.value,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: card,
      );
    }
    return card;
  }
}

class _MonthlyCostBarChart extends StatelessWidget {
  final List<FuelEntry> windowFuel;
  final List<ServiceEntry> windowService;
  final StatsMetric metric;
  final String currencyCode;

  const _MonthlyCostBarChart({
    required this.windowFuel,
    required this.windowService,
    required this.metric,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final cs = Theme.of(context).colorScheme;

    // Day 11: Use seriesFromTotals to build monthly buckets
    final series = seriesFromTotals(fuel: windowFuel, service: windowService);
    
    if (series.isEmpty) {
      return Center(
        child: Text(
          l10n.chartNoData,
          style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.70)),
        ),
      );
    }

    final labels = <String>[];
    final values = <double>[];
    
    // Build data based on selected metric
    for (final bucket in series) {
      labels.add(DateFormat('MM/yy', locale).format(bucket.month));
      
      switch (metric) {
        case StatsMetric.cost:
          values.add(bucket.fuelAmount + bucket.serviceAmount);
        case StatsMetric.liters:
          values.add(bucket.liters);
        case StatsMetric.distance:
          // Estimate distance for this month using entries from that month
          final monthFuel = windowFuel.where((e) => 
            e.date.year == bucket.month.year && e.date.month == bucket.month.month
          ).toList();
          final monthService = windowService.where((e) => 
            e.date.year == bucket.month.year && e.date.month == bucket.month.month
          ).toList();
          final dist = estimateMonthlyDistanceKm(
            fuelMonth: monthFuel,
            serviceMonth: monthService,
          );
          values.add(dist);
      }
    }

  final hasData = values.any((v) => v > 0);
    if (!hasData) {
      return Center(
        child: Text(
          l10n.chartNoData,
          style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.70)),
        ),
      );
    }

    final barColor = cs.primary.withValues(alpha: 0.90);
    final groups = <BarChartGroupData>[];
    
    for (int i = 0; i < values.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              width: 16,
              borderRadius: BorderRadius.circular(6),
              color: barColor,
            ),
          ],
        ),
      );
    }

  final maxY = values.fold<double>(0, (p, n) => n > p ? n : p);
  // Compute a reasonable tick interval to avoid overlapping labels
  final double tickIntervalRaw = maxY == 0 ? 1.0 : (maxY / 4);
  final double tickInterval = tickIntervalRaw <= 0 ? 1.0 : tickIntervalRaw;
    
    // Determine unit label
    String unitLabel;
    switch (metric) {
      case StatsMetric.cost:
        unitLabel = '€';
      case StatsMetric.liters:
        unitLabel = 'L';
      case StatsMetric.distance:
        unitLabel = 'km';
    }

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.24),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
              ),
              barGroups: groups,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    if (idx < 0 || idx >= labels.length) return null;
                    final monthLabel = labels[idx];
                    final value = values[idx];
                    String formattedValue;
                    if (metric == StatsMetric.cost) {
                      formattedValue = formatCurrency(value, currencyCode: currencyCode, context: context);
                    } else {
                      formattedValue = '${value.toStringAsFixed(metric == StatsMetric.distance ? 0 : 1)} $unitLabel';
                    }
                    return BarTooltipItem(
                      '$monthLabel – $formattedValue',
                      TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // Give left side more room and set interval to avoid overlap
                    reservedSize: 56,
                    interval: tickInterval,
                    getTitlesWidget: (value, meta) {
                      final labelText = metric == StatsMetric.cost
                          ? formatCurrency(value, currencyCode: currencyCode, context: context)
                          : '${value.toStringAsFixed(0)}$unitLabel';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            labelText,
                            softWrap: true,
                            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.85)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                      return Text(
                        labels[idx],
                        softWrap: true,
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.85)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              minY: 0,
              maxY: maxY == 0 ? 1 : maxY * 1.2,
            ),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          ),
        ),
        const SizedBox(height: 12),
        // Legend showing current metric
        Text(
          metric == StatsMetric.cost ? '${l10n.tabFuel} + ${l10n.tabService}' :
          metric == StatsMetric.liters ? 'Fuel (L)' :
          'Distance (km)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _ConsumptionChart extends StatelessWidget {
  final List<ConsumptionPoint> consumptions;

  const _ConsumptionChart({required this.consumptions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final cs = Theme.of(context).colorScheme;
    
    // Guard: πρέπει να έχουμε τουλάχιστον 2 σημεία
    if (consumptions.length < 2) {
      return Center(
        child: Text(
          l10n.chartNoData,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85)),
        ),
      );
    }

    final spots = consumptions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.litersPer100Km))
        .toList();

    // Safe min/max calculations
    final yValues = consumptions.map((c) => c.litersPer100Km).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    
    // Guard: αποφυγή διαίρεσης με 0 ή NaN
    final yRange = maxY - minY;
    final yPadding = yRange > 0 ? yRange * 0.2 : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.onSurfaceVariant.withValues(alpha: 0.24),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(l10n.chartAxisConsumption, style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.85))),
            ),
            axisNameSize: 22,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.85)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(l10n.chartAxisDate, softWrap: true, style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.85))),
            ),
            axisNameSize: 22,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= consumptions.length) {
                  return const SizedBox.shrink();
                }
                final date = consumptions[idx].date;
                return Text(
                  DateFormat('dd/MM', locale).format(date),
                  softWrap: true,
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.85)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
        ),
        minX: 0,
        maxX: (consumptions.length - 1).toDouble(),
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cs.primary.withValues(alpha: 0.95),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withValues(alpha: 0.10),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= consumptions.length) {
                  return null;
                }
                final date = consumptions[idx].date;
                final consumption = spot.y;
                
                // Guard: έλεγχος για NaN
                if (consumption.isNaN) {
                  return null;
                }
                
                return LineTooltipItem(
                  '${DateFormat('dd/MM/yy', locale).format(date)}\n${consumption.toStringAsFixed(2)} L/100km',
                  TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

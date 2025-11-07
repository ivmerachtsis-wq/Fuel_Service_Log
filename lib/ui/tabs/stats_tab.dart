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
import '../../utils/currency_formatter.dart';
import '../../features/stats/pdf/stats_report_pdf.dart';

class StatsTab extends StatefulWidget {
  final SettingsController settings;
  const StatsTab({required this.settings, super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  String? _selectedVehicleId;
  String? _selectedDriverId; // null ή '' => All
  int _rangeMonths = 6; // 3 / 6 / 12

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
      for (int i = 11; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
        final fuel = monthlyCosts.firstWhere(
          (c) => c.yearMonth == key,
          orElse: () => MonthlyCost(yearMonth: key, amount: 0),
        ).amount;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statsService = StatsService();

    final vehiclesBox = Hive.box<Vehicle>('vehicles');
    if (vehiclesBox.isEmpty) {
      return Center(child: Text(l10n.noActiveVehicle));
    }
    // Ορισμός default vehicle αν δεν έχει επιλεγεί
    _selectedVehicleId ??= vehiclesBox.values.first.id;

  final fuelBox = Hive.box<FuelEntry>('fuel_entries');
  final serviceBox = Hive.box<ServiceEntry>('service_entries');
    final driversBox = Hive.box<Driver>('drivers');

    return ValueListenableBuilder(
      // Listen to fuel entries
      valueListenable: fuelBox.listenable(),
      builder: (context, Box<FuelEntry> fb, _) {
        return ValueListenableBuilder(
          // Also listen to service entries for reactive updates
          valueListenable: serviceBox.listenable(),
          builder: (context, Box<ServiceEntry> sb, __) {
            // Συλλογή όλων των fuel entries για το επιλεγμένο όχημα
            final allVehicleEntries = fb.values
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
            final serviceEntries = sb.values
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

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Export PDF button
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPdf(context),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(l10n.exportPdf),
                  ),
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
                const SizedBox(height: 24),
                Text(l10n.statsTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
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
                                   color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.70),
                                 ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.statsHintFullToFull,
                            textAlign: TextAlign.center,
                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                   color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.60),
                                 ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 16),
                      child: _ConsumptionChart(consumptions: consumptions),
                    ),
                  ),

                const SizedBox(height: 24),
                // Bar chart: Στοιβαγμένο κόστος/μήνα (Fuel + Service)
                (monthlyCosts.isEmpty && serviceMonthMap.isEmpty)
                    ? SizedBox(
                        height: 280,
                        child: Center(
                          child: Text(
                            l10n.chartNoData,
                             style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.70)), 
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 280,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _MonthlyCostBarChart(
                              costs: monthlyCosts,
                              serviceMonthMap: serviceMonthMap,
                              months: _rangeMonths,
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
            // Range buttons 6 / 12 months
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _rangeButton(label: l10n.range6m, months: 6),
                const SizedBox(width: 4),
                _rangeButton(label: l10n.range12m, months: 12),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _rangeButton({required String label, required int months}) {
    final active = _rangeMonths == months;
    return OutlinedButton(
      onPressed: () {
        if (!active) setState(() => _rangeMonths = months);
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? Theme.of(context).colorScheme.primary.withOpacity(0.10) : null,
      ),
      child: Text(label, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    );
  }
}

class _MonthlyCostBarChart extends StatelessWidget {
  final List<MonthlyCost> costs; // fuel costs per month from service
  final Map<String, double> serviceMonthMap; // service amounts per YYYY-MM
  final int months; // window size (e.g., 6/12)
  final String currencyCode;

  const _MonthlyCostBarChart({
    required this.costs,
    required this.serviceMonthMap,
    required this.months,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final cs = Theme.of(context).colorScheme;

    // Build the x-axis months based on now and window
    final now = DateTime.now();
    final labels = <String>[];
    final fuels = <double>[];
    final services = <double>[];
    final totals = <double>[];
    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      final fuel = costs.firstWhere(
        (c) => c.yearMonth == key,
        orElse: () => MonthlyCost(yearMonth: key, amount: 0),
      ).amount;
      final service = serviceMonthMap[key] ?? 0;
      labels.add(DateFormat('MM/yy', locale).format(m));
      fuels.add(fuel);
      services.add(service);
      totals.add(fuel + service);
    }

    final hasData = totals.any((v) => v > 0);
    if (!hasData) {
      return Center(
        child: Text(
          l10n.chartNoData,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.70)),
        ),
      );
    }

  final fuelColor = cs.primary.withOpacity(0.90);
  final serviceColor = (cs.tertiary ?? cs.secondary).withOpacity(0.90);

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < totals.length; i++) {
      final fuel = fuels[i];
      final service = services[i];
      final total = totals[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              rodStackItems: [
                // Fuel at the base
                BarChartRodStackItem(0, fuel, fuelColor),
                // Service stacked on top
                BarChartRodStackItem(fuel, fuel + service, serviceColor),
              ],
            ),
          ],
        ),
      );
    }

    final maxY = totals.fold<double>(0, (p, n) => n > p ? n : p);

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: cs.onSurfaceVariant.withOpacity(0.24),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: cs.onSurfaceVariant.withOpacity(0.24),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.10))),
              barGroups: groups,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    final monthLabel = labels[idx];
                    final fuel = fuels[idx];
                    final service = services[idx];
                    final total = fuel + service;
                    final fuelStr = formatCurrency(fuel, currencyCode: currencyCode, context: context);
                    final serviceStr = formatCurrency(service, currencyCode: currencyCode, context: context);
                    final totalStr = formatCurrency(total, currencyCode: currencyCode, context: context);
                    return BarTooltipItem(
                      '$monthLabel\n${l10n.tabFuel}: $fuelStr\n${l10n.tabService}: $serviceStr\n${l10n.pdfTotalAmount}: $totalStr',
                      TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                // Δείξε σε βήματα για να μην γεμίζει
                return Text(
                  formatCurrency(value, currencyCode: currencyCode, context: context),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withOpacity(0.78)),
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
                return Text(labels[idx], style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withOpacity(0.78)));
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
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: fuelColor, label: l10n.tabFuel),
            const SizedBox(width: 16),
            _LegendItem(color: serviceColor, label: l10n.tabService),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
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
          style: TextStyle(color: Colors.grey[600]),
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
            color: cs.onSurfaceVariant.withOpacity(0.24),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(l10n.chartAxisConsumption, style: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.78))),
            ),
            axisNameSize: 22,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withOpacity(0.78)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(l10n.chartAxisDate, style: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.78))),
            ),
            axisNameSize: 22,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= consumptions.length) {
                  return const SizedBox.shrink();
                }
                final date = consumptions[idx].date;
                return Text(
                  DateFormat('dd/MM', locale).format(date),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withOpacity(0.78)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: cs.onSurface.withOpacity(0.10)),
        ),
        minX: 0,
        maxX: (consumptions.length - 1).toDouble(),
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cs.primary.withOpacity(0.95),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withOpacity(0.10),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
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

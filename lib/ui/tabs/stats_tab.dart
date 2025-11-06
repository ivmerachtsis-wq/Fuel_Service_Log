import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/vehicle.dart';
import '../../data/models/driver.dart';
import '../../domain/stats_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/kpi_card.dart';
import '../../state/settings_controller.dart';
import '../../utils/currency_formatter.dart';

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
    final driversBox = Hive.box<Driver>('drivers');

    return ValueListenableBuilder(
      valueListenable: fuelBox.listenable(),
      builder: (context, Box<FuelEntry> fb, _) {
        // Συλλογή όλων των entries για το επιλεγμένο όχημα
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

        final avgConsumption = consumptions.isNotEmpty
            ? statsService.getAverageConsumption(consumptions)
            : double.nan;
        final avgMonthlyCost = monthlyCosts.isNotEmpty
            ? statsService.getAverageMonthlyCost(monthlyCosts)
            : double.nan;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilters(
              l10n: l10n,
              vehiclesBox: vehiclesBox,
              driversBox: driversBox,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: l10n.kpiAvgConsumption,
                    value: avgConsumption.isNaN || avgConsumption <= 0
                        ? '—'
                        : avgConsumption.toStringAsFixed(2),
                    icon: Icons.speed,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
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
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.statsHintFullToFull,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
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
          ],
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
            // Range buttons 3 / 6 / 12 months
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _rangeButton(label: l10n.range3m, months: 3),
                const SizedBox(width: 4),
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
        backgroundColor: active ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
      ),
      child: Text(label, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal)),
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
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(l10n.chartAxisConsumption),
            ),
            axisNameSize: 22,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(l10n.chartAxisDate),
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
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: (consumptions.length - 1).toDouble(),
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

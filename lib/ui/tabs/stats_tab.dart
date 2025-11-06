import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/vehicle.dart';
import '../../domain/stats_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/kpi_card.dart';
import '../../state/settings_controller.dart';
import '../../utils/currency_formatter.dart';

class StatsTab extends StatelessWidget {
  final SettingsController settings;
  const StatsTab({required this.settings, super.key});

  @override
  Widget build(BuildContext context) {
    final statsService = StatsService();
    final l10n = AppLocalizations.of(context)!;
    
    // Συγχρονιστική λήψη του ενεργού οχήματος
    final vehiclesBox = Hive.box<Vehicle>('vehicles');
    if (vehiclesBox.isEmpty) {
      return Center(child: Text(l10n.noActiveVehicle));
    }
    final vehicleId = vehiclesBox.values.first.id;

    final box = Hive.box<FuelEntry>('fuel_entries');
    
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<FuelEntry> fuelBox, _) {
        // Φιλτράρισμα entries του ενεργού οχήματος (συγχρονιστικά)
        final vehicleEntries = fuelBox.values
            .where((e) => e.vehicleId == vehicleId)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        // Υπολογισμός στατιστικών (συγχρονιστικά, χωρίς await)
        final consumptions = statsService.getFullToFullConsumptions(vehicleEntries);
        final monthlyCosts = statsService.getMonthlyCost(vehicleEntries, months: 6);
        
        // Safe calculations με guards για NaN/null
        final avgConsumption = consumptions.isNotEmpty 
            ? statsService.getAverageConsumption(consumptions)
            : double.nan;
        final avgMonthlyCost = monthlyCosts.isNotEmpty
            ? statsService.getAverageMonthlyCost(monthlyCosts)
            : double.nan;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KPIs
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
                                currencyCode: settings.currencyCode,
                                context: context,
                              ),
                        icon: Icons.euro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Γράφημα κατανάλωσης
                Text(l10n.statsTitle,
                    style: Theme.of(context).textTheme.titleLarge),
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

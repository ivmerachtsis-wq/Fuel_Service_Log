import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/repo/fuel_repo.dart';
import '../../state/active_vehicle_controller.dart';
import '../../domain/stats_service.dart';
import '../widgets/kpi_card.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final fuelRepo = FuelRepo();
    final activeController = ActiveVehicleController();
    final statsService = StatsService();

    return FutureBuilder<String>(
      future: activeController.getActiveVehicleId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final vehicleId = snapshot.data!;

        return StreamBuilder(
          stream: fuelRepo.watchAll(),
          builder: (context, streamSnapshot) {
            if (!streamSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Φιλτράρισμα entries του ενεργού οχήματος
            final allEntries = streamSnapshot.data!;
            final vehicleEntries = allEntries
                .where((e) => e.vehicleId == vehicleId)
                .toList();

            // Υπολογισμός στατιστικών
            final consumptions = statsService.getFullToFullConsumptions(vehicleEntries);
            final monthlyCosts = statsService.getMonthlyCost(vehicleEntries, months: 6);
            final avgConsumption = statsService.getAverageConsumption(consumptions);
            final avgMonthlyCost = statsService.getAverageMonthlyCost(monthlyCosts);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KPIs
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        title: 'Μέση Κατανάλωση (L/100km)',
                        value: consumptions.isEmpty 
                            ? '—' 
                            : avgConsumption.toStringAsFixed(2),
                        icon: Icons.speed,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        title: 'Κόστος/Μήνα (τελ. 6μ)',
                        value: monthlyCosts.isEmpty
                            ? '—'
                            : '€${avgMonthlyCost.toStringAsFixed(2)}',
                        icon: Icons.euro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Γράφημα κατανάλωσης
                Text(
                  'Ιστορικό Κατανάλωσης (L/100km)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                if (consumptions.isEmpty)
                  const SizedBox(
                    height: 300,
                    child: Center(
                      child: Text(
                        'Δεν υπάρχουν επαρκή δεδομένα για στατιστικά.\n\nΧρειάζονται τουλάχιστον 2 πλήρεις ανεφοδιασμοί (Full Tank).',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
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
      },
    );
  }
}

class _ConsumptionChart extends StatelessWidget {
  final List<ConsumptionPoint> consumptions;

  const _ConsumptionChart({required this.consumptions});

  @override
  Widget build(BuildContext context) {
    final spots = consumptions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.litersPer100Km))
        .toList();

    final minY = consumptions.map((c) => c.litersPer100Km).reduce((a, b) => a < b ? a : b);
    final maxY = consumptions.map((c) => c.litersPer100Km).reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.2;

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
                  DateFormat('dd/MM').format(date),
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
                final date = consumptions[idx].date;
                return LineTooltipItem(
                  '${DateFormat('dd/MM/yy').format(date)}\n${spot.y.toStringAsFixed(2)} L/100km',
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

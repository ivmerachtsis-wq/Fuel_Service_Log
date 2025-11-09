import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

import '../data/models/fuel_entry.dart';
import '../data/models/service_entry.dart';
import '../data/models/vehicle.dart';
import '../domain/stats_aggregator.dart';
import '../state/stats_filter.dart';
import '../state/stats_metric.dart';

/// Input data for generating PDF stats report
class PdfStatsReportInput {
  final Vehicle vehicle;
  final List<FuelEntry> fuelEntries;
  final List<ServiceEntry> serviceEntries;
  final StatsFilter filter;
  final StatsMetric metric;

  const PdfStatsReportInput({
    required this.vehicle,
    required this.fuelEntries,
    required this.serviceEntries,
    required this.filter,
    required this.metric,
  });
}

/// Monthly row data for PDF table
class PdfMonthlyRow {
  final String month;
  final double fuelCost;
  final double serviceCost;
  final double liters;
  final double distanceKm;
  final double totalCost;

  const PdfMonthlyRow({
    required this.month,
    required this.fuelCost,
    required this.serviceCost,
    required this.liters,
    required this.distanceKm,
    required this.totalCost,
  });
}

/// Generate PDF report for active vehicle filtered stats
class ActiveVehiclePdfReport {
  static Future<Uint8List> build(PdfStatsReportInput input) async {
  final pdf = pw.Document();
    // Load fonts defensively
    final (regular, bold, theme) = await _loadPdfFonts();

    // Filter entries by date range
    final filteredFuel = input.fuelEntries.where((e) => input.filter.includes(e.date)).toList();
    final filteredService = input.serviceEntries.where((e) => input.filter.includes(e.date)).toList();

    // Totals & KPIs
    final totalFuelCost = filteredFuel.fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalServiceCost = filteredService.fold<double>(0.0, (sum, e) => sum + e.totalAmount);
    final totalCost = totalFuelCost + totalServiceCost;
    final totalLiters = filteredFuel.fold<double>(0.0, (sum, e) => sum + e.liters);
    final totalDistanceKm = computeDistanceKm(fuel: filteredFuel, service: filteredService);
    final costPerKm = totalDistanceKm > 0 ? totalCost / totalDistanceKm : 0.0;
    final litersPer100Km = totalDistanceKm > 0 ? (totalLiters / totalDistanceKm) * 100 : 0.0;

    // Monthly buckets
    final buckets = <String, _PdfMonthlyBucket>{};
    for (final f in filteredFuel) {
      final key = '${f.date.year}-${f.date.month.toString().padLeft(2, '0')}';
      buckets.putIfAbsent(key, () => _PdfMonthlyBucket(key));
      buckets[key]!.fuelCost += f.amount;
      buckets[key]!.liters += f.liters;
    }
    for (final s in filteredService) {
      final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
      buckets.putIfAbsent(key, () => _PdfMonthlyBucket(key));
      buckets[key]!.serviceCost += s.totalAmount;
    }
    // Distance estimation per month
    for (final key in buckets.keys) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
      final fuelMonth = filteredFuel.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end)).toList();
      final serviceMonth = filteredService.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end)).toList();
      buckets[key]!.distanceKm = estimateMonthlyDistanceKm(fuelMonth: fuelMonth, serviceMonth: serviceMonth);
    }
    final monthlyRows = buckets.keys.toList()..sort();
    final rows = monthlyRows
        .map((k) => buckets[k]!)
        .map((b) => PdfMonthlyRow(
              month: b.key,
              fuelCost: b.fuelCost,
              serviceCost: b.serviceCost,
              liters: b.liters,
              distanceKm: b.distanceKm,
              totalCost: b.fuelCost + b.serviceCost,
            ))
        .toList();

    // Build PDF page(s) using MultiPage with theme
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          textDirection: pw.TextDirection.ltr,
          orientation: pw.PageOrientation.portrait,
          theme: theme,
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 16),
              _buildMeta(input.vehicle, input.filter),
              pw.SizedBox(height: 16),
              _buildKpisBox(costPerKm, litersPer100Km, totalCost),
              pw.SizedBox(height: 24),
              _buildBarChart(rows, input.metric),
              pw.SizedBox(height: 24),
              _buildMonthlyTable(rows),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Text(
      'Fuel Service Log - Stats Report',
      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _buildMeta(Vehicle vehicle, StatsFilter filter) {
    String label;
    switch (filter.preset) {
      case StatsPreset.all:
        label = 'All Time';
        break;
      case StatsPreset.last30:
        label = 'Last 30 Days';
        break;
      case StatsPreset.last90:
        label = 'Last 90 Days';
        break;
      case StatsPreset.last180:
        label = 'Last 180 Days';
        break;
      case StatsPreset.ytd:
        label = 'Year to Date';
        break;
      case StatsPreset.custom:
        final s = filter.from;
        final e = filter.to;
        if (s != null && e != null) {
          final fmt = DateFormat('yyyy-MM-dd');
          label = '${fmt.format(s)} to ${fmt.format(e)}';
        } else {
          label = 'Custom';
        }
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Vehicle: ${vehicle.title}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Date Range: $label',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildKpisBox(
    double costPerKm,
    double litersPer100Km,
    double totalCost,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildKpiItem('Cost/km', '€${costPerKm.toStringAsFixed(2)}'),
          _buildKpiItem('L/100km', litersPer100Km.toStringAsFixed(2)),
          _buildKpiItem('Total Cost', '€${totalCost.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  static pw.Widget _buildKpiItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildBarChart(List<PdfMonthlyRow> rows, StatsMetric metric) {
    if (rows.isEmpty) {
      return pw.Container(height: 150, alignment: pw.Alignment.center, child: pw.Text('No data to display'));
    }

    // Extract values based on metric
    final values = rows.map((r) {
      switch (metric) {
        case StatsMetric.cost:
          return r.totalCost;
        case StatsMetric.liters:
          return r.liters;
        case StatsMetric.distance:
          return r.distanceKm;
      }
    }).toList();

  final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) {
      return pw.Container(
        height: 150,
        alignment: pw.Alignment.center,
        child: pw.Text('No data to display'),
      );
    }

    final chartHeight = 150.0;
    final chartWidth = 500.0;
    final barWidth = chartWidth / rows.length;
    const barPadding = 4.0;

    String metricLabel;
    switch (metric) {
      case StatsMetric.cost:
        metricLabel = 'Total Cost (€)';
        break;
      case StatsMetric.liters:
        metricLabel = 'Liters';
        break;
      case StatsMetric.distance:
        metricLabel = 'Distance (km)';
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monthly Chart: $metricLabel',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.CustomPaint(
          size: PdfPoint(chartWidth, chartHeight),
          painter: (canvas, size) {
            for (int i = 0; i < rows.length; i++) {
              final v = values[i];
              final h = (v / maxValue) * chartHeight;
              final x = i * barWidth + barPadding;
              final y = chartHeight - h;
              canvas
                ..setFillColor(PdfColor.fromHex('#2196F3'))
                ..drawRRect(x, y, barWidth - barPadding * 2, h, 6, 6)
                ..fillPath();
            }
          },
        ),
      ],
    );
  }

  static pw.Widget _buildMonthlyTable(List<PdfMonthlyRow> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Monthly Breakdown', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerRight,
          headerAlignment: pw.Alignment.centerRight,
          headers: const ['Month', 'Fuel', 'Service', 'Liters', 'Distance', 'Total'],
          data: rows
              .map((r) => [
                    r.month,
                    '€${r.fuelCost.toStringAsFixed(2)}',
                    '€${r.serviceCost.toStringAsFixed(2)}',
                    r.liters.toStringAsFixed(2),
                    '${r.distanceKm.toStringAsFixed(0)} km',
                    '€${r.totalCost.toStringAsFixed(2)}',
                  ])
              .toList(),
        ),
      ],
    );
  }
}

class _PdfMonthlyBucket {
  final String key;
  double fuelCost = 0;
  double serviceCost = 0;
  double liters = 0;
  double distanceKm = 0;
  _PdfMonthlyBucket(this.key);
}

// Defensive font loader for PDF with fallback and global fontFallback.
Future<(pw.Font, pw.Font, pw.ThemeData)> _loadPdfFonts() async {
  try {
    final base = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    var theme = pw.ThemeData.withFont(base: base, bold: bold);
    theme = theme.copyWith(defaultTextStyle: pw.TextStyle(fontFallback: [base]));
    return (base, bold, theme);
  } catch (_) {
    final base = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();
    var theme = pw.ThemeData.withFont(base: base, bold: bold);
    theme = theme.copyWith(defaultTextStyle: pw.TextStyle(fontFallback: [base]));
    return (base, bold, theme);
  }
}

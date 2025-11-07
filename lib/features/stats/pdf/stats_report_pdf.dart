import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../l10n/app_localizations.dart';

/// Data Transfer Object for PDF statistics
class StatsData {
  final String vehicleName;
  final double avgLPer100;
  final double costPerMonthCurrent;
  final double serviceFreqDays;
  final List<MonthlyCostData> months;

  StatsData({
    required this.vehicleName,
    required this.avgLPer100,
    required this.costPerMonthCurrent,
    required this.serviceFreqDays,
    required this.months,
  });
}

/// Monthly cost data for PDF table
class MonthlyCostData {
  final String ym; // "YYYY-MM"
  final double fuel;
  final double service;

  MonthlyCostData({
    required this.ym,
    required this.fuel,
    required this.service,
  });

  double get total => fuel + service;
}

/// Builds a statistics report PDF with real stats data.
Future<Uint8List> buildStatsPdf({
  required BuildContext context,
  required StatsData data,
  required String currencyCode,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final pdf = pw.Document();

  // ISO 8601 formatted date
  final now = DateTime.now();
  final isoDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // Currency formatter
  final currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits: 2,
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Text(
              l10n.statsReportTitle,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Date: $isoDate', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${l10n.pdfMetaVehicle}: ${data.vehicleName.isEmpty ? "—" : data.vehicleName}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            
            // KPIs Section
            pw.Text(
              'Key Performance Indicators',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiBox(
                  l10n.kpiAvgConsumption,
                  data.avgLPer100.isNaN || data.avgLPer100 <= 0
                      ? '—'
                      : '${data.avgLPer100.toStringAsFixed(2)} L/100km',
                ),
                _buildKpiBox(
                  l10n.kpiMonthlyCost,
                  data.costPerMonthCurrent.isNaN || data.costPerMonthCurrent <= 0
                      ? '—'
                      : '${currencyFormat.format(data.costPerMonthCurrent)} $currencyCode',
                ),
                _buildKpiBox(
                  'Service Frequency',
                  data.serviceFreqDays.isNaN || data.serviceFreqDays <= 0
                      ? '—'
                      : '${data.serviceFreqDays.toStringAsFixed(0)} days',
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            
            // Monthly Totals Table
            pw.Text(
              'Monthly Cost Overview (Last 12 Months)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            _buildMonthlyTable(data.months, currencyFormat, currencyCode, l10n),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _buildKpiBox(String title, String value) {
  return pw.Container(
    width: 160,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

pw.Widget _buildMonthlyTable(
  List<MonthlyCostData> months,
  NumberFormat currencyFormat,
  String currencyCode,
  AppLocalizations l10n,
) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: {
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(3),
      2: const pw.FlexColumnWidth(3),
      3: const pw.FlexColumnWidth(3),
    },
    children: [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _tableCell('Month', isHeader: true),
          _tableCell('${l10n.tabFuel} ($currencyCode)', isHeader: true),
          _tableCell('${l10n.tabService} ($currencyCode)', isHeader: true),
          _tableCell('${l10n.pdfTotalAmount} ($currencyCode)', isHeader: true),
        ],
      ),
      // Data rows
      ...months.map((m) => pw.TableRow(
        children: [
          _tableCell(m.ym),
          _tableCell(currencyFormat.format(m.fuel)),
          _tableCell(currencyFormat.format(m.service)),
          _tableCell(currencyFormat.format(m.total)),
        ],
      )),
    ],
  );
}

pw.Widget _tableCell(String text, {bool isHeader = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: isHeader ? 10 : 9,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

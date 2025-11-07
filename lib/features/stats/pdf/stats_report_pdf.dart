import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  // Load Unicode-safe fonts
  final fontRegular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final fontBold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );

  // Create theme with custom fonts
  final theme = pw.ThemeData.withFont(
    base: fontRegular,
    bold: fontBold,
  );

  // ISO 8601 formatted date
  final now = DateTime.now();
  final isoDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // Currency formatter
  final currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits: 2,
  );

  // Precompute sums for footer totals
  final sumFuel = data.months.fold<double>(0.0, (p, m) => p + (m.fuel.isNaN ? 0 : m.fuel));
  final sumService = data.months.fold<double>(0.0, (p, m) => p + (m.service.isNaN ? 0 : m.service));
  final sumTotal = sumFuel + sumService;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: theme,
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Date: $isoDate', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
      build: (pw.Context context) => [
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
        pw.Divider(height: 32, thickness: 1.5, color: PdfColors.grey400),

        // KPIs Section
        pw.Text(
          'Key Performance Indicators',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
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
        pw.SizedBox(height: 28),

        // Monthly Totals Table
        pw.Text(
          'Monthly Cost Overview (Last 12 Months)',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        _buildMonthlyTable(data.months, currencyFormat, currencyCode, l10n),

        pw.SizedBox(height: 20),
        _buildFooterTotals(
          sumFuel: sumFuel,
          sumService: sumService,
          sumTotal: sumTotal,
          currencyFormat: currencyFormat,
          currencyCode: currencyCode,
          l10n: l10n,
        ),
      ],
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
      0: const pw.FixedColumnWidth(80),
      1: const pw.FixedColumnWidth(120),
      2: const pw.FixedColumnWidth(120),
      3: const pw.FixedColumnWidth(120),
    },
    children: [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _tableCell('Month', isHeader: true, align: pw.TextAlign.left),
          _tableCell('${l10n.tabFuel} ($currencyCode)', isHeader: true, align: pw.TextAlign.right),
          _tableCell('${l10n.tabService} ($currencyCode)', isHeader: true, align: pw.TextAlign.right),
          _tableCell('${l10n.pdfTotalAmount} ($currencyCode)', isHeader: true, align: pw.TextAlign.right),
        ],
      ),
      // Data rows
      ...months.map((m) => pw.TableRow(
        children: [
          _tableCell(m.ym, align: pw.TextAlign.left),
          _tableCell(currencyFormat.format(m.fuel), align: pw.TextAlign.right),
          _tableCell(currencyFormat.format(m.service), align: pw.TextAlign.right),
          _tableCell(currencyFormat.format(m.total), align: pw.TextAlign.right),
        ],
      )),
    ],
  );
}

pw.Widget _tableCell(String text, {bool isHeader = false, pw.TextAlign? align}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: pw.Text(
      text,
      textAlign: align ?? pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: isHeader ? 11 : 10,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _buildFooterTotals({
  required double sumFuel,
  required double sumService,
  required double sumTotal,
  required NumberFormat currencyFormat,
  required String currencyCode,
  required AppLocalizations l10n,
}) {
  final labelStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey800);
  final valueStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

  pw.Widget valueCell(double v) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('${currencyFormat.format(v)} $currencyCode', style: valueStyle),
      );

  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Container(
      width: 360,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColors.grey300),
          verticalInside: pw.BorderSide(color: PdfColors.grey300),
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(180),
          1: const pw.FixedColumnWidth(160),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: pw.Text(l10n.tabFuel, style: labelStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: valueCell(sumFuel),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: pw.Text(l10n.tabService, style: labelStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: valueCell(sumService),
              ),
            ],
          ),
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: pw.Text(l10n.pdfTotalAmount, style: labelStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: valueCell(sumTotal),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

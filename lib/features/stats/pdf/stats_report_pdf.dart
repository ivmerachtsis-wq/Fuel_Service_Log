import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../l10n/app_localizations.dart';

/// Builds a statistics report PDF with placeholder data.
/// This is a skeleton implementation for M5a - actual data integration comes in M5b.
Future<Uint8List> buildStatsPdf({required BuildContext context}) async {
  final l10n = AppLocalizations.of(context)!;
  final pdf = pw.Document();

  // ISO 8601 formatted date
  final now = DateTime.now();
  final isoDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Title
            pw.Text(
              l10n.statsReportTitle,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Date: $isoDate', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            
            // Active Vehicle (placeholder)
            pw.Text(
              'Active Vehicle: [Placeholder - No data wired yet]',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            
            // KPIs Section
            pw.Text(
              'Key Performance Indicators',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('• Average Consumption: [Placeholder]'),
            pw.Text('• Monthly Cost: [Placeholder]'),
            pw.SizedBox(height: 16),
            
            // Chart Section
            pw.Text(
              'Monthly Cost Chart',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('[Placeholder for chart visualization - will be added in M5b]'),
            pw.SizedBox(height: 8),
            pw.Container(
              height: 200,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Chart area\n(Fuel + Service stacked bars)',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// lib/reports/pdf_table_report.dart
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class PdfTableReport {
  final String title;
  final DateTimeRange dateRange;
  final String locale;
  final String currencyCode;
  final List<Map<String, dynamic>> fuelRows;    // date, type, odo, qty, unit, amount, note
  final List<Map<String, dynamic>> serviceRows; // date, type, odo, qty, unit, amount, note

  PdfTableReport({
    required this.title,
    required this.dateRange,
    required this.locale,
    required this.currencyCode,
    required this.fuelRows,
    required this.serviceRows,
  });

  Future<Uint8List> build() async {
    final doc = pw.Document();

    // Φόρτωση γραμματοσειρών (NotoSans που έχεις ήδη στο assets/fonts/)
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));

    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    final numFmt = NumberFormat.decimalPattern(locale);
    final curFmt = NumberFormat.currency(locale: locale, name: currencyCode);

    pw.Widget buildHeader(String label) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          "${_d(dateRange.start)} → ${_d(dateRange.end)}",
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 10),
      ],
    );

    pw.Widget buildFooter(pw.Context ctx) => pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text("Σελίδα ${ctx.pageNumber} από ${ctx.pagesCount}",
          style: const pw.TextStyle(fontSize: 9)),
    );

    pw.Table buildTable({
      required List<Map<String, dynamic>> rows,
      required String section,
    }) {
      final headers = const ["Date", "Type", "Odometer", "Qty/Labor", "Unit/–", "Amount"];
      final children = <pw.TableRow>[];

      // Header row
      children.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
      );

      num total = 0;

      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final zebra = i.isEven
            ? const pw.BoxDecoration(color: PdfColors.grey200)
            : const pw.BoxDecoration();

        final amount = (r["amount"] ?? 0) as num;
        total += amount;

        children.add(
          pw.TableRow(
            decoration: zebra,
            children: [
              _cell(_s(r["date"])),
              _cell(_s(r["type"] ?? section)),
              _cell(_n(r["odo"], numFmt), align: pw.TextAlign.right),
              _cell(_n(r["qty"], numFmt), align: pw.TextAlign.right),
              _cell(_s(r["unit"] ?? "-"), align: pw.TextAlign.center),
              _cell(curFmt.format(amount), align: pw.TextAlign.right),
            ],
          ),
        );
      }

      // Totals row
      children.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cell("Total", bold: true),
            _cell(""),
            _cell(""),
            _cell(""),
            _cell(""),
            _cell(curFmt.format(total), align: pw.TextAlign.right, bold: true),
          ],
        ),
      );

      return pw.Table(
        border: pw.TableBorder.all(width: 0.2),
        columnWidths: const {
          0: pw.FixedColumnWidth(62),   // Date
          1: pw.FlexColumnWidth(1),     // Type/Note
          2: pw.FixedColumnWidth(60),   // Odometer
          3: pw.FixedColumnWidth(58),   // Qty/Labor
          4: pw.FixedColumnWidth(48),   // Unit
          5: pw.FixedColumnWidth(68),   // Amount
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: children,
      );
    }

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.all(24),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => buildHeader(title),
        footer: (ctx) => buildFooter(ctx),
        build: (ctx) => [
          pw.Text("Fuel", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          buildTable(rows: fuelRows, section: "Fuel"),
          pw.SizedBox(height: 16),
          pw.Text("Service", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          buildTable(rows: serviceRows, section: "Service"),
        ],
      ),
    );

    return doc.save();
  }

  // Helpers
  static String _d(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static String _s(dynamic v) => (v == null) ? "" : v.toString();
  static String _n(dynamic v, NumberFormat fmt) {
    if (v == null) return "";
    try { return fmt.format(v); } catch (_) { return v.toString(); }
  }

  static pw.Widget _cell(String txt, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(txt, textAlign: align, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange({required this.start, required this.end});
}

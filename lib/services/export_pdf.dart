import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/fuel_entry.dart';
import '../data/models/service_entry.dart';
import '../data/models/vehicle.dart';
import '../data/models/driver.dart';

class ExportPdfService {
  static Future<Directory> _ensureExportsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exports = Directory(
      p.join(dir.path, 'FuelServiceLog', 'exports'),
    );
    if (!exports.existsSync()) exports.createSync(recursive: true);
    return exports;
  }

  static String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  static String fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static String fmtNum(num? v, int dp) => v == null ? '' : v.toStringAsFixed(dp);

  static Future<File> exportFuelToPdf({
    required String vehicleId,
    required List<FuelEntry> entries,
    required Vehicle? vehicle,
    required Driver? driver,
  }) async {
    // Sort ascending by date to match requirement
    entries.sort((a, b) => a.date.compareTo(b.date));

    final doc = pw.Document();

    final totalLiters = entries.fold<num>(0, (sum, e) => sum + (e.liters));
    final totalAmount = entries.fold<num>(0, (sum, e) => sum + (e.amount));
    // Choose currency code from first non-null
    final currencyCode = entries.firstWhere(
      (e) => (e.currencyCode ?? '').isNotEmpty,
      orElse: () => entries.isNotEmpty ? entries.first : FuelEntry(
        id: 'tmp', vehicleId: vehicleId, date: DateTime.now(), odometerKm: 0, liters: 0, pricePerLiter: 0, amount: 0,
      ),
    ).currencyCode ?? '';

    final title = 'Fuel Export';
    final createdAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber}/${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
        ),
        build: (context) {
          return [
            _buildHeader(title: title, createdAt: createdAt),
            _buildMetadata(vehicle: vehicle, driver: driver),
            _buildSummary(count: entries.length, totalLiters: totalLiters, totalAmount: totalAmount, currencyCode: currencyCode, isFuel: true),
            pw.SizedBox(height: 8),
            _buildFuelTable(entries),
          ];
        },
      ),
    );

    final dir = await _ensureExportsDir();
    final filePath = p.join(dir.path, 'fuel_${_timestamp()}.pdf');
    final file = File(filePath);
  final bytes = await doc.save();
  await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<File> exportServiceToPdf({
    required String vehicleId,
    required List<ServiceEntry> entries,
    required Vehicle? vehicle,
    required Driver? driver,
  }) async {
    // Sort ascending by date
    entries.sort((a, b) => a.date.compareTo(b.date));

    final doc = pw.Document();

    final totalAmount = entries.fold<num>(0, (sum, e) => sum + (e.totalAmount));
    final currencyCode = entries.firstWhere(
      (e) => (e.currencyCode ?? '').isNotEmpty,
      orElse: () => entries.isNotEmpty ? entries.first : ServiceEntry(
        id: 'tmp', vehicleId: vehicleId, date: DateTime.now(), odometerKm: 0, description: '', totalAmount: 0,
      ),
    ).currencyCode ?? '';

    final title = 'Service Export';
    final createdAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber}/${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
        ),
        build: (context) {
          return [
            _buildHeader(title: title, createdAt: createdAt),
            _buildMetadata(vehicle: vehicle, driver: driver),
            _buildSummary(count: entries.length, totalLiters: null, totalAmount: totalAmount, currencyCode: currencyCode, isFuel: false),
            pw.SizedBox(height: 8),
            _buildServiceTable(entries),
          ];
        },
      ),
    );

    final dir = await _ensureExportsDir();
    final filePath = p.join(dir.path, 'service_${_timestamp()}.pdf');
    final file = File(filePath);
  final bytes = await doc.save();
  await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static pw.Widget _buildHeader({required String title, required DateTime createdAt}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Created at: ${fmtDate(createdAt)}', style: const pw.TextStyle(fontSize: 11)),
        pw.Text('Fuel & Service Log', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildMetadata({required Vehicle? vehicle, required Driver? driver}) {
    final vehicleStr = vehicle == null ? '-' : [vehicle.title, if ((vehicle.plate ?? '').isNotEmpty) '(${vehicle.plate})'].join(' ');
    final driverStr = driver?.name ?? '-';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Vehicle: $vehicleStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Driver: $driverStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary({
    required int count,
    required num? totalLiters,
    required num totalAmount,
    required String currencyCode,
    required bool isFuel,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Wrap(spacing: 16, runSpacing: 4, children: [
          pw.Text('Count: $count'),
          if (isFuel) pw.Text('Total liters: ${fmtNum(totalLiters ?? 0, 2)}'),
          pw.Text('Total amount: ${fmtNum(totalAmount, 2)} ${currencyCode.toUpperCase()}'),
        ]),
      ],
    );
  }

  static pw.Widget _buildFuelTable(List<FuelEntry> entries) {
    final headers = ['Date', 'Odometer', 'Liters', 'Price/L', 'Amount', 'Currency', 'Notes'];
    final data = entries.map((e) {
      final notes = (e.notes ?? '').trim();
  final notesDisplay = notes.length > 50 ? '${notes.substring(0, 50)}…' : notes;
      return [
        fmtDate(e.date),
        fmtNum(e.odometerKm, 1),
        fmtNum(e.liters, 2),
        fmtNum(e.pricePerLiter, 3),
        fmtNum(e.amount, 2),
        (e.currencyCode ?? '').toUpperCase(),
        notesDisplay,
      ];
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            for (final h in headers)
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
          ],
        ),
        ...data.map((row) => pw.TableRow(
              children: [
                for (final cell in row)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(cell.toString()),
                  ),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildServiceTable(List<ServiceEntry> entries) {
    final headers = ['Date', 'Odometer', 'Description', 'Amount', 'Currency', 'Notes'];
    final data = entries.map((e) {
      final notes = (e.notes ?? '').trim();
  final notesDisplay = notes.length > 50 ? '${notes.substring(0, 50)}…' : notes;
      final desc = e.description.trim();
  final descDisplay = desc.length > 50 ? '${desc.substring(0, 50)}…' : desc;
      return [
        fmtDate(e.date),
        fmtNum(e.odometerKm, 1),
        descDisplay,
        fmtNum(e.totalAmount, 2),
        (e.currencyCode ?? '').toUpperCase(),
        notesDisplay,
      ];
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(0.8),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            for (final h in headers)
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
          ],
        ),
        ...data.map((row) => pw.TableRow(
              children: [
                for (final cell in row)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(cell.toString()),
                  ),
              ],
            )),
      ],
    );
  }
}

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/models/vehicle.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/models/service_entry.dart';
import '../../../l10n/app_localizations.dart';

class StatsKpis {
  final double avgConsumption; // L/100km
  final double costPerKm; // EUR/km
  final double monthlyCost; // EUR/month

  const StatsKpis({required this.avgConsumption, required this.costPerKm, required this.monthlyCost});
}

Future<Uint8List> buildActiveVehicleReport({
  required Vehicle v,
  required List<FuelEntry> fuel,
  required List<ServiceEntry> service,
  required StatsKpis kpis,
  required AppLocalizations l10n,
}) async {
  final doc = pw.Document();
  final nowIso = DateFormat("yyyy-MM-ddTHH:mm:ss").format(DateTime.now());

  List<List<String>> fuelRows() {
    final last10 = fuel.take(10).toList();
    return last10
        .map((e) => [
              e.date.toIso8601String(),
              e.liters.toStringAsFixed(2),
              e.pricePerLiter.toStringAsFixed(2),
              e.amount.toStringAsFixed(2),
              e.odometerKm.toStringAsFixed(0),
            ])
        .toList();
  }

  List<List<String>> serviceRows() {
    final last10 = service.take(10).toList();
    return last10
        .map((e) => [
              e.date.toIso8601String(),
              e.description,
              e.totalAmount.toStringAsFixed(2),
              e.odometerKm.toStringAsFixed(0),
            ])
        .toList();
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(l10n.appTitle, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(nowIso, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 10),

            // Vehicle block
            pw.Text(l10n.activeVehicleReport, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('${l10n.pdfMetaVehicle}: ${v.title}${v.plate != null ? ' / ${v.plate}' : ''}'),
            pw.SizedBox(height: 12),

            // KPIs
            pw.Text(l10n.pdfKpiHeader, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${l10n.avgConsumptionHeader}: ${kpis.avgConsumption.toStringAsFixed(2)}'),
                pw.Text('${l10n.costPerKmHeader}: ${kpis.costPerKm.toStringAsFixed(3)}'),
                pw.Text('${l10n.monthlyCostHeader}: ${kpis.monthlyCost.toStringAsFixed(2)}'),
              ],
            ),
            pw.SizedBox(height: 12),

            // Fuel table
            pw.Text(l10n.tabFuel, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.serviceDate,
                l10n.litersHeader,
                l10n.pricePerLiterHeader,
                l10n.amountHeader,
                l10n.odometerKm,
              ],
              data: fuelRows(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),

            // Service table
            pw.Text(l10n.tabService, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.serviceDate,
                l10n.serviceDescription,
                l10n.amountHeader,
                l10n.odometerKm,
              ],
              data: serviceRows(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),

            pw.Spacer(),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(l10n.pdfGeneratedFooter, style: const pw.TextStyle(fontSize: 9)),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

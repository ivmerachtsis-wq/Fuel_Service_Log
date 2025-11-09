// test/pdf/pdf_table_report_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/reports/pdf_table_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfTableReport generates multipage PDF with tables & totals', () async {
    final now = DateTime.now();
    final range = DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);

    final fuel = List.generate(35, (i) => {
      "date": range.start.add(Duration(days: i)).toIso8601String().substring(0,10),
      "type": "Refuel ${i+1}",
      "odo": 10000 + i * 120,
      "qty": 35 + (i % 7),
      "unit": "L",
      "amount": 60 + (i % 9) * 3,
    });

    final service = List.generate(15, (i) => {
      "date": range.start.add(Duration(days: i*2)).toIso8601String().substring(0,10),
      "type": "Service ${i+1}",
      "odo": 10000 + i * 500,
      "qty": 1,
      "unit": "-",
      "amount": 40 + (i % 5) * 12,
    });

    final rep = PdfTableReport(
      title: "Active Vehicle Report",
      dateRange: range,
      locale: "el_GR",
      currencyCode: "EUR",
      fuelRows: fuel,
      serviceRows: service,
    );

    Uint8List bytes = await rep.build();
    expect(bytes.lengthInBytes > 10 * 1024, true, reason: "PDF should be >10KB for multipage tables");
  });
}

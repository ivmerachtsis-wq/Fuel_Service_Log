import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

Future<pw.ThemeData> loadPdfTheme() async {
  pw.Font base, bold;
  try {
    final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final b = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    base = pw.Font.ttf(regular);
    bold = pw.Font.ttf(b);
  } catch (_) {
    base = pw.Font.helvetica();
    bold = pw.Font.helveticaBold();
  }
  return pw.ThemeData.withFont(
    base: base,
    bold: bold,
    defaultTextStyle: pw.TextStyle(fontFallback: [base]),
  );
}

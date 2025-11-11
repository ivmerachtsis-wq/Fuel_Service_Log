import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loaded PDF fonts with Greek glyph support (NotoSans)
class PdfFonts {
  final pw.Font base;
  final pw.Font bold;
  final pw.ThemeData theme;

  PdfFonts._({
    required this.base,
    required this.bold,
    required this.theme,
  });

  /// Load NotoSans fonts (Regular + Bold) for Greek text support (issue #24).
  /// Falls back to Helvetica if assets are unavailable.
  static Future<PdfFonts> load() async {
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
    final theme = pw.ThemeData.withFont(
      base: base,
      bold: bold,
    );
    return PdfFonts._(base: base, bold: bold, theme: theme);
  }
}

/// Legacy helper - loads PDF theme with Greek support via NotoSans fonts
Future<pw.ThemeData> loadPdfTheme() async {
  final fonts = await PdfFonts.load();
  return fonts.theme;
}

// lib/utils/save_pdf.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class PdfSaver {
  static Future<String> saveTemp(Uint8List bytes, {String filename = "report.pdf"}) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}${Platform.pathSeparator}$filename");
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

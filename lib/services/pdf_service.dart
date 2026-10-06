import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;

import '../models/document_model.dart';

class PdfService {
  const PdfService._();

  static Future<String> createPdf(
    ScanDocument document,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    final pdf = pw.Document();

    for (final page in document.pages) {
      final bytes = await File(page.path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    final safeTitle = document.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${safeTitle.isEmpty ? 'documento' : safeTitle}_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final output = File(p.join(destination.path, fileName));
    await output.writeAsBytes(await pdf.save(), flush: true);
    return output.path;
  }
}

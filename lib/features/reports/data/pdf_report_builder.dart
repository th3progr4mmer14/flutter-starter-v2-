import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/report_table.dart';

class PdfReportBuilder {
  PdfReportBuilder._();

  /// Genera un PDF A4 horizontal con encabezado, tabla paginada y número de página.
  static Future<Uint8List> build({
    required ReportTable table,
    required String appName,
    required String generatedLabel,
    required String Function(int page, int pages) pageLabel,
  }) async {
    final doc = pw.Document(title: table.title, author: appName);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              table.title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '$appName - $generatedLabel',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            pageLabel(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: table.headers,
            data: table.rows,
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }
}

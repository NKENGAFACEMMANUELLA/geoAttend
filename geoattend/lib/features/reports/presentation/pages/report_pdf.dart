import 'dart:typed_data';

import 'package:geoattend/core/core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../hod/domain/team.dart';

/// Builds a printable A4 PDF of [r]. Text is kept ASCII-friendly for the
/// built-in PDF fonts.
Future<Uint8List> buildReportPdf(AttendanceReport r) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text('GeoAttend', style: pw.TextStyle(fontSize: 12, color: PdfColors.indigo900, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(r.title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('${r.period}  |  ${r.scope}', style: const pw.TextStyle(fontSize: 12)),
        pw.Text('Generated ${Fmt.dateTime(r.generatedAt)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Row(children: [
          for (final h in r.highlights)
            pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.only(right: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(h.value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(h.label, style: const pw.TextStyle(fontSize: 9)),
                ]),
              ),
            ),
        ]),
        pw.SizedBox(height: 18),
        pw.TableHelper.fromTextArray(
          headers: r.columns,
          data: r.rows,
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        ),
      ],
    ),
  );
  return doc.save();
}

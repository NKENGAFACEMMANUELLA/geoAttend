import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../../hod/domain/team.dart';
import 'report_pdf.dart';

/// Shows a generated report on screen and lets HOD/Admin export it.
class ReportResultPage extends StatefulWidget {
  const ReportResultPage({super.key, required this.report});
  final AttendanceReport report;

  @override
  State<ReportResultPage> createState() => _ReportResultPageState();
}

class _ReportResultPageState extends State<ReportResultPage> {
  bool _exporting = false;

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final bytes = await buildReportPdf(widget.report);
      final name = widget.report.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      await Printing.sharePdf(bytes: bytes, filename: 'geoattend-$name.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create the PDF. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyCsv() async {
    await Clipboard.setData(ClipboardData(text: widget.report.toCsv()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied as CSV')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return AppPage(
      title: 'Report',
      bottom: Row(children: [
        Expanded(child: PrimaryButton(label: 'Export PDF', icon: Icons.picture_as_pdf_outlined, onPressed: _exportPdf, loading: _exporting)),
        const SizedBox(width: 12),
        Expanded(child: SecondaryButton(label: 'Copy CSV', icon: Icons.copy_all_outlined, onPressed: _copyCsv)),
      ]),
      child: ListView(children: [
        Text(r.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${r.period}  |  ${r.scope}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text('Generated ${Fmt.dateTime(r.generatedAt)}', style: const TextStyle(fontSize: 11, color: AppColors.hint)),
        const SizedBox(height: 16),
        Row(children: [
          for (var i = 0; i < r.highlights.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == r.highlights.length - 1 ? 0 : 10),
                child: SoftCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.highlights[i].value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(r.highlights[i].label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        SoftCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.lavender),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy, fontSize: 13),
                dataTextStyle: const TextStyle(fontSize: 13, color: Colors.black),
                columnSpacing: 24,
                columns: [for (final c in r.columns) DataColumn(label: Text(c))],
                rows: [
                  for (final row in r.rows)
                    DataRow(cells: [
                      for (var i = 0; i < row.length; i++)
                        DataCell(Text(row[i], style: TextStyle(fontWeight: i == 0 ? FontWeight.w500 : FontWeight.w400))),
                    ]),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}

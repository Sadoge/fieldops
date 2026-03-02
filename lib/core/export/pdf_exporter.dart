import 'dart:io';

import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExporter {
  Future<File> export(List<WorkOrder> orders) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (_) => pw.Text(
          'Field Ops — Work Order Report',
          style: pw.TextStyle(
              fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'Title', 'Status', 'Assigned To', 'Location', 'Updated',
            ],
            data: orders
                .map((o) => [
                      o.title,
                      o.status.name,
                      o.assignedTo,
                      o.locationLabel ?? '-',
                      DateFormatter.formatDate(o.updatedAt),
                    ])
                .toList(),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.5),
            },
            border: pw.TableBorder.all(width: 0.5),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/fieldops_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }
}

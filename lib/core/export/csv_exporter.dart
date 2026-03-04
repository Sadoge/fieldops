import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:path_provider/path_provider.dart';

class CsvExporter {
  static const _headers = [
    'ID',
    'Title',
    'Description',
    'Status',
    'Priority',
    'Assigned To',
    'Created By',
    'Location',
    'Due At',
    'Created At',
    'Updated At',
  ];

  Future<File> export(List<WorkOrder> orders) async {
    final rows = <List<dynamic>>[_headers];
    for (final o in orders) {
      rows.add([
        o.id,
        o.title,
        o.description,
        o.status.name,
        o.priority.name,
        o.assignedTo,
        o.createdBy,
        o.locationLabel ?? '',
        o.dueAt?.toIso8601String() ?? '',
        o.createdAt.toIso8601String(),
        o.updatedAt.toIso8601String(),
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/fieldops_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    return file.writeAsString(csv);
  }
}

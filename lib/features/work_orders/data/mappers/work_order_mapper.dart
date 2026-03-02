import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/work_orders_table.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';

abstract final class WorkOrderMapper {
  static WorkOrder fromData(WorkOrderRow d) => WorkOrder(
        id: d.id,
        title: d.title,
        description: d.description,
        status: d.status,
        assignedTo: d.assignedTo,
        createdBy: d.createdBy,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        completedAt: d.completedAt,
        locationLabel: d.locationLabel,
        remoteId: d.remoteId,
        isDirty: d.isDirty,
        localVersion: d.localVersion,
        serverVersion: d.serverVersion,
      );

  static WorkOrdersCompanion toCompanion(WorkOrder e) => WorkOrdersCompanion(
        id: Value(e.id),
        title: Value(e.title),
        description: Value(e.description),
        status: Value(e.status),
        assignedTo: Value(e.assignedTo),
        createdBy: Value(e.createdBy),
        createdAt: Value(e.createdAt),
        updatedAt: Value(e.updatedAt),
        completedAt: Value(e.completedAt),
        locationLabel: Value(e.locationLabel),
        remoteId: Value(e.remoteId),
        isDirty: Value(e.isDirty),
        localVersion: Value(e.localVersion),
        serverVersion: Value(e.serverVersion),
      );

  static Map<String, dynamic> toJson(WorkOrder e) => {
        'id': e.id,
        'title': e.title,
        'description': e.description,
        'status': e.status.name,
        'assignedTo': e.assignedTo,
        'createdBy': e.createdBy,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
        'completedAt': e.completedAt?.toIso8601String(),
        'locationLabel': e.locationLabel,
        'remoteId': e.remoteId,
        'isDirty': e.isDirty,
        'localVersion': e.localVersion,
        'serverVersion': e.serverVersion,
      };

  static WorkOrder fromJson(Map<String, dynamic> j) => WorkOrder(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        status: WorkOrderStatus.values.byName(j['status'] as String),
        assignedTo: j['assignedTo'] as String? ?? '',
        createdBy: j['createdBy'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
        locationLabel: j['locationLabel'] as String?,
        remoteId: j['remoteId'] as String?,
        isDirty: j['isDirty'] as bool? ?? false,
        localVersion: j['localVersion'] as int? ?? 1,
        serverVersion: j['serverVersion'] as int?,
      );
}

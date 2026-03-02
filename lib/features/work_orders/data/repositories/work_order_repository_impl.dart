import 'dart:convert';

import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/audit_log_table.dart';
import 'package:fieldops/core/database/tables/sync_queue_table.dart';
import 'package:fieldops/core/sync/sync_queue_dao.dart';
import 'package:fieldops/features/audit_log/data/repositories/audit_log_repository_impl.dart';
import 'package:fieldops/features/work_orders/data/daos/work_orders_dao.dart';
import 'package:fieldops/features/work_orders/data/mappers/work_order_mapper.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_filter.dart';
import 'package:fieldops/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:drift/drift.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  WorkOrderRepositoryImpl({
    required this.dao,
    required this.syncQueueDao,
    required this.auditLogRepo,
  });

  final WorkOrdersDao dao;
  final SyncQueueDao syncQueueDao;
  final AuditLogRepositoryImpl auditLogRepo;

  @override
  Stream<List<WorkOrder>> watchAll({WorkOrderFilter? filter}) {
    if (filter == null || filter.isEmpty) {
      return dao.watchAll().map((rows) => rows.map(WorkOrderMapper.fromData).toList());
    }
    return dao
        .watchFiltered(
          searchQuery: filter.searchQuery,
          status: filter.status,
        )
        .map((rows) => rows.map(WorkOrderMapper.fromData).toList());
  }

  @override
  Future<WorkOrder?> findById(String id) async {
    final data = await dao.findById(id);
    return data != null ? WorkOrderMapper.fromData(data) : null;
  }

  @override
  Future<void> save(WorkOrder order) async {
    final existing = await dao.findById(order.id);
    final isNew = existing == null;
    final now = DateTime.now().toUtc();
    final dirty = order.copyWith(
      isDirty: true,
      updatedAt: now,
      localVersion: order.localVersion + (isNew ? 0 : 1),
    );
    await dao.upsert(WorkOrderMapper.toCompanion(dirty));
    await syncQueueDao.enqueue(SyncQueueCompanion(
      entityType: const Value('work_order'),
      entityId: Value(order.id),
      operation: Value(isNew ? SyncOperation.create : SyncOperation.update),
      status: const Value(SyncItemStatus.pending),
      payload: Value(jsonEncode(WorkOrderMapper.toJson(dirty))),
      createdAt: Value(now),
    ));
    await auditLogRepo.record(
      workOrderId: order.id,
      action: isNew ? AuditAction.created : AuditAction.edited,
      performedBy: order.createdBy,
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = await dao.findById(id);
    if (existing == null) return;
    await dao.deleteById(id);
    final now = DateTime.now().toUtc();
    await syncQueueDao.enqueue(SyncQueueCompanion(
      entityType: const Value('work_order'),
      entityId: Value(id),
      operation: const Value(SyncOperation.delete),
      status: const Value(SyncItemStatus.pending),
      payload: Value(jsonEncode({'id': id})),
      createdAt: Value(now),
    ));
  }
}

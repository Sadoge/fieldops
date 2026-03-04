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
import 'package:fieldops/features/work_orders/domain/entities/work_order_priority.dart';
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
      return dao.watchAll().map(
            (rows) => _sortForTriage(
              rows.map(WorkOrderMapper.fromData).toList(),
            ),
          );
    }
    return dao
        .watchFiltered(
          searchQuery: filter.searchQuery,
          status: filter.status,
        )
        .map(
          (rows) => _sortForTriage(
            rows.map(WorkOrderMapper.fromData).toList(),
          ),
        );
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
  Future<void> updateLocalOnly(WorkOrder order) =>
      dao.upsert(WorkOrderMapper.toCompanion(order));

  @override
  Future<void> delete(String id) async {
    final existing = await dao.findById(id);
    if (existing == null) return;

    final existsOnServer = existing.remoteId != null;

    // Cancel all pending queue items for this entity regardless.
    await syncQueueDao.cancelPendingForEntity(id);
    await dao.deleteById(id);

    if (existsOnServer) {
      // Record reached the server — enqueue a delete so it's removed remotely too.
      await syncQueueDao.enqueue(SyncQueueCompanion(
        entityType: const Value('work_order'),
        entityId: Value(id),
        operation: const Value(SyncOperation.delete),
        status: const Value(SyncItemStatus.pending),
        payload: Value(jsonEncode({'id': id})),
        createdAt: Value(DateTime.now().toUtc()),
      ));
    }
    // If remoteId is null the record never reached the server — nothing to do remotely.
  }

  List<WorkOrder> _sortForTriage(List<WorkOrder> orders) {
    orders.sort((a, b) {
      final activeCompare =
          a.isClosed == b.isClosed ? 0 : (a.isClosed ? 1 : -1);
      if (activeCompare != 0) return activeCompare;

      final overdueCompare =
          a.isOverdue == b.isOverdue ? 0 : (a.isOverdue ? -1 : 1);
      if (overdueCompare != 0) return overdueCompare;

      final priorityCompare =
          _priorityRank(b.priority).compareTo(_priorityRank(a.priority));
      if (priorityCompare != 0) return priorityCompare;

      final aDue = a.dueAt;
      final bDue = b.dueAt;
      if (aDue != null && bDue != null) {
        final dueCompare = aDue.compareTo(bDue);
        if (dueCompare != 0) return dueCompare;
      } else if (aDue != null || bDue != null) {
        return aDue == null ? 1 : -1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });
    return orders;
  }

  int _priorityRank(WorkOrderPriority priority) => switch (priority) {
        WorkOrderPriority.low => 0,
        WorkOrderPriority.medium => 1,
        WorkOrderPriority.high => 2,
        WorkOrderPriority.urgent => 3,
      };
}

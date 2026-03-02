import 'dart:convert';

import 'package:fieldops/core/database/tables/audit_log_table.dart';
import 'package:fieldops/features/audit_log/domain/repositories/audit_log_repository.dart';
import 'package:fieldops/features/work_orders/data/mappers/work_order_mapper.dart';
import 'package:fieldops/features/work_orders/domain/repositories/work_order_repository.dart';

enum _Resolution { serverWins, localWins, merge }

class ConflictResolver {
  ConflictResolver({
    required this.workOrderRepo,
    required this.auditLogRepo,
  });

  final WorkOrderRepository workOrderRepo;
  final AuditLogRepository auditLogRepo;

  Future<void> resolveIncoming(Map<String, dynamic> remoteData) async {
    final entityType = remoteData['entityType'] as String?;
    if (entityType != 'work_order') return;

    final remoteOrder = WorkOrderMapper.fromJson(remoteData);
    final local = await workOrderRepo.findById(remoteOrder.id);

    if (local == null) {
      // No local copy — insert directly, mark clean
      await workOrderRepo.save(remoteOrder.copyWith(isDirty: false));
      return;
    }

    final resolution = _determineResolution(
      localDirty: local.isDirty,
      localServerVersion: local.serverVersion,
      remoteServerVersion: remoteOrder.serverVersion,
    );

    switch (resolution) {
      case _Resolution.localWins:
        // Local dirty write will be pushed in the next sync cycle — do nothing.
        break;

      case _Resolution.serverWins:
      case _Resolution.merge:
        // For MVP merge falls back to server wins; log it either way.
        final needsAudit = local.isDirty || resolution == _Resolution.merge;
        await workOrderRepo.save(remoteOrder.copyWith(isDirty: false));
        if (needsAudit) {
          await auditLogRepo.record(
            workOrderId: local.id,
            action: AuditAction.conflictResolved,
            performedBy: 'system',
            oldValue: jsonEncode(WorkOrderMapper.toJson(local)),
            newValue: jsonEncode(WorkOrderMapper.toJson(remoteOrder)),
            note: resolution == _Resolution.merge
                ? 'Merge conflict — server version applied.'
                : 'Server version (${remoteOrder.serverVersion}) '
                    'superseded local version (${local.localVersion}).',
          );
        }
    }
  }

  _Resolution _determineResolution({
    required bool localDirty,
    required int? localServerVersion,
    required int? remoteServerVersion,
  }) {
    if (!localDirty) return _Resolution.serverWins;

    final lv = localServerVersion ?? 0;
    final rv = remoteServerVersion ?? 0;

    if (rv > lv) return _Resolution.serverWins;
    if (rv == lv && localDirty) return _Resolution.localWins;
    return _Resolution.merge;
  }
}

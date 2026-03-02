import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/features/audit_log/data/daos/audit_log_dao.dart';
import 'package:fieldops/features/audit_log/domain/entities/audit_log_entry.dart';
import 'package:fieldops/features/audit_log/domain/repositories/audit_log_repository.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  AuditLogRepositoryImpl(this._dao);

  final AuditLogDao _dao;

  @override
  Stream<List<AuditLogEntry>> watchByWorkOrder(String workOrderId) =>
      _dao.watchByWorkOrder(workOrderId).map(
            (rows) => rows
                .map((d) => AuditLogEntry(
                      id: d.id,
                      workOrderId: d.workOrderId,
                      action: d.action,
                      performedBy: d.performedBy,
                      performedAt: d.performedAt,
                      oldValue: d.oldValue,
                      newValue: d.newValue,
                      note: d.note,
                    ))
                .toList(),
          );

  @override
  Stream<List<AuditLogEntry>> watchAll() =>
      _dao.watchAll().map(
            (rows) => rows
                .map((d) => AuditLogEntry(
                      id: d.id,
                      workOrderId: d.workOrderId,
                      action: d.action,
                      performedBy: d.performedBy,
                      performedAt: d.performedAt,
                      oldValue: d.oldValue,
                      newValue: d.newValue,
                      note: d.note,
                    ))
                .toList(),
          );

  @override
  Future<void> record({
    required String workOrderId,
    required AuditAction action,
    required String performedBy,
    String? oldValue,
    String? newValue,
    String? note,
  }) =>
      _dao.insert(AuditLogCompanion.insert(
        workOrderId: workOrderId,
        action: action,
        performedBy: performedBy,
        performedAt: DateTime.now().toUtc(),
        oldValue: Value(oldValue),
        newValue: Value(newValue),
        note: Value(note),
      ));
}

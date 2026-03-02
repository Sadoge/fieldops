import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/audit_log_table.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLog])
class AuditLogDao extends DatabaseAccessor<AppDatabase>
    with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Stream<List<AuditLogData>> watchByWorkOrder(String workOrderId) =>
      (select(auditLog)
            ..where((t) => t.workOrderId.equals(workOrderId))
            ..orderBy([(t) => OrderingTerm.desc(t.performedAt)]))
          .watch();

  Stream<List<AuditLogData>> watchAll() =>
      (select(auditLog)
            ..orderBy([(t) => OrderingTerm.desc(t.performedAt)]))
          .watch();

  Future<void> insert(AuditLogCompanion entry) =>
      into(auditLog).insert(entry);
}

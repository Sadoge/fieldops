import 'package:fieldops/features/audit_log/domain/entities/audit_log_entry.dart';

abstract class AuditLogRepository {
  Stream<List<AuditLogEntry>> watchByWorkOrder(String workOrderId);
  Stream<List<AuditLogEntry>> watchAll();
  Future<void> record({
    required String workOrderId,
    required AuditAction action,
    required String performedBy,
    String? oldValue,
    String? newValue,
    String? note,
  });
}

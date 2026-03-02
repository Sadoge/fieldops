import 'package:fieldops/core/providers.dart';
import 'package:fieldops/features/audit_log/domain/entities/audit_log_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditLogProvider =
    StreamProvider.family<List<AuditLogEntry>, String>((ref, workOrderId) {
  return ref.watch(auditLogRepositoryProvider).watchByWorkOrder(workOrderId);
});

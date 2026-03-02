import 'package:fieldops/core/providers.dart';
import 'package:fieldops/features/audit_log/domain/entities/audit_log_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watches audit log entries for a specific work order.
final auditLogProvider =
    StreamProvider.family<List<AuditLogEntry>, String>((ref, workOrderId) {
  return ref.watch(auditLogRepositoryProvider).watchByWorkOrder(workOrderId);
});

/// Watches all audit log entries across every work order.
final auditLogAllProvider = StreamProvider<List<AuditLogEntry>>((ref) {
  return ref.watch(auditLogRepositoryProvider).watchAll();
});

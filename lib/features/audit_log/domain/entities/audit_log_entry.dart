import 'package:equatable/equatable.dart';

// Re-export action enum from table definition
export 'package:fieldops/core/database/tables/audit_log_table.dart'
    show AuditAction;

import 'package:fieldops/core/database/tables/audit_log_table.dart';

class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.workOrderId,
    required this.action,
    required this.performedBy,
    required this.performedAt,
    this.oldValue,
    this.newValue,
    this.note,
  });

  final int id;
  final String workOrderId;
  final AuditAction action;
  final String performedBy;
  final DateTime performedAt;
  final String? oldValue;
  final String? newValue;
  final String? note;

  @override
  List<Object?> get props => [
        id, workOrderId, action, performedBy, performedAt,
        oldValue, newValue, note,
      ];
}

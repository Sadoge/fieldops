import 'package:equatable/equatable.dart';

import 'work_order_priority.dart';
import 'work_order_status.dart';

class WorkOrder extends Equatable {
  static const _unset = Object();

  const WorkOrder({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.completedAt,
    this.locationLabel,
    this.remoteId,
    this.isDirty = true,
    this.localVersion = 1,
    this.serverVersion,
  });

  final String id;
  final String title;
  final String description;
  final WorkOrderStatus status;
  final WorkOrderPriority priority;
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String? locationLabel;
  final String? remoteId;
  final bool isDirty;
  final int localVersion;
  final int? serverVersion;

  bool get isClosed =>
      status == WorkOrderStatus.completed || status == WorkOrderStatus.verified;

  bool get isOverdue =>
      dueAt != null && !isClosed && dueAt!.isBefore(DateTime.now().toUtc());

  WorkOrder copyWith({
    String? id,
    String? title,
    String? description,
    WorkOrderStatus? status,
    WorkOrderPriority? priority,
    String? assignedTo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? dueAt = _unset,
    Object? completedAt = _unset,
    Object? locationLabel = _unset,
    Object? remoteId = _unset,
    bool? isDirty,
    int? localVersion,
    Object? serverVersion = _unset,
  }) =>
      WorkOrder(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        assignedTo: assignedTo ?? this.assignedTo,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        dueAt: dueAt == _unset ? this.dueAt : dueAt as DateTime?,
        completedAt:
            completedAt == _unset ? this.completedAt : completedAt as DateTime?,
        locationLabel: locationLabel == _unset
            ? this.locationLabel
            : locationLabel as String?,
        remoteId: remoteId == _unset ? this.remoteId : remoteId as String?,
        isDirty: isDirty ?? this.isDirty,
        localVersion: localVersion ?? this.localVersion,
        serverVersion: serverVersion == _unset
            ? this.serverVersion
            : serverVersion as int?,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        assignedTo,
        createdBy,
        createdAt,
        updatedAt,
        dueAt,
        completedAt,
        locationLabel,
        remoteId,
        isDirty,
        localVersion,
        serverVersion,
      ];
}

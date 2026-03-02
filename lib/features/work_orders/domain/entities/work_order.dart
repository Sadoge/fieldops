import 'package:equatable/equatable.dart';
import 'work_order_status.dart';

class WorkOrder extends Equatable {
  const WorkOrder({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
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
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? locationLabel;
  final String? remoteId;
  final bool isDirty;
  final int localVersion;
  final int? serverVersion;

  WorkOrder copyWith({
    String? id,
    String? title,
    String? description,
    WorkOrderStatus? status,
    String? assignedTo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? locationLabel,
    String? remoteId,
    bool? isDirty,
    int? localVersion,
    int? serverVersion,
  }) =>
      WorkOrder(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        assignedTo: assignedTo ?? this.assignedTo,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt ?? this.completedAt,
        locationLabel: locationLabel ?? this.locationLabel,
        remoteId: remoteId ?? this.remoteId,
        isDirty: isDirty ?? this.isDirty,
        localVersion: localVersion ?? this.localVersion,
        serverVersion: serverVersion ?? this.serverVersion,
      );

  @override
  List<Object?> get props => [
        id, title, description, status, assignedTo, createdBy,
        createdAt, updatedAt, completedAt, locationLabel, remoteId,
        isDirty, localVersion, serverVersion,
      ];
}

import 'package:equatable/equatable.dart';

class Note extends Equatable {
  const Note({
    required this.id,
    required this.workOrderId,
    required this.body,
    required this.createdBy,
    required this.createdAt,
    this.isSynced = false,
  });

  final String id;
  final String workOrderId;
  final String body;
  final String createdBy;
  final DateTime createdAt;
  final bool isSynced;

  Note copyWith({
    String? id,
    String? workOrderId,
    String? body,
    String? createdBy,
    DateTime? createdAt,
    bool? isSynced,
  }) =>
      Note(
        id: id ?? this.id,
        workOrderId: workOrderId ?? this.workOrderId,
        body: body ?? this.body,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  List<Object?> get props => [id, workOrderId, body, createdBy, createdAt, isSynced];
}

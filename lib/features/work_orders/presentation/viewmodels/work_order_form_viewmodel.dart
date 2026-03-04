import 'package:equatable/equatable.dart';
import 'package:fieldops/core/permissions/permission.dart';
import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/utils/id_generator.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkOrderFormState extends Equatable {
  static const _unset = Object();

  const WorkOrderFormState({
    this.existingId,
    this.title = '',
    this.description = '',
    this.locationLabel = '',
    this.assignedTo = '',
    this.priority = WorkOrderPriority.medium,
    this.dueAt,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String? existingId;
  final String title;
  final String description;
  final String locationLabel;
  final String assignedTo;
  final WorkOrderPriority priority;
  final DateTime? dueAt;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isNew => existingId == null;
  bool get isValid => title.trim().isNotEmpty;

  WorkOrderFormState copyWith({
    String? existingId,
    String? title,
    String? description,
    String? locationLabel,
    String? assignedTo,
    WorkOrderPriority? priority,
    Object? dueAt = _unset,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) =>
      WorkOrderFormState(
        existingId: existingId ?? this.existingId,
        title: title ?? this.title,
        description: description ?? this.description,
        locationLabel: locationLabel ?? this.locationLabel,
        assignedTo: assignedTo ?? this.assignedTo,
        priority: priority ?? this.priority,
        dueAt: dueAt == _unset ? this.dueAt : dueAt as DateTime?,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        existingId,
        title,
        description,
        locationLabel,
        assignedTo,
        priority,
        dueAt,
        isSubmitting,
        errorMessage,
      ];
}

class WorkOrderFormViewModel extends AutoDisposeNotifier<WorkOrderFormState> {
  @override
  WorkOrderFormState build() => const WorkOrderFormState();

  void init(WorkOrder order) {
    state = WorkOrderFormState(
      existingId: order.id,
      title: order.title,
      description: order.description,
      locationLabel: order.locationLabel ?? '',
      assignedTo: order.assignedTo,
      priority: order.priority,
      dueAt: order.dueAt,
    );
  }

  void setTitle(String v) => state = state.copyWith(title: v, clearError: true);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setLocation(String v) => state = state.copyWith(locationLabel: v);
  void setAssignedTo(String v) => state = state.copyWith(assignedTo: v);
  void setPriority(WorkOrderPriority v) => state = state.copyWith(priority: v);
  void setDueAt(DateTime? v) => state = state.copyWith(dueAt: v);

  Future<bool> submit() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Title is required');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final permService = ref.read(permissionServiceProvider);
      permService.guard(
          state.isNew ? Permission.createWorkOrder : Permission.editWorkOrder);

      final user = ref.read(currentUserProvider).valueOrNull;
      final now = DateTime.now().toUtc();
      final id = state.existingId ?? IdGenerator.newId();

      WorkOrder order;
      if (state.isNew) {
        order = WorkOrder(
          id: id,
          title: state.title.trim(),
          description: state.description.trim(),
          status: WorkOrderStatus.newOrder,
          priority: state.priority,
          assignedTo: state.assignedTo.trim().isEmpty
              ? (user?.id ?? 'unassigned')
              : state.assignedTo.trim(),
          createdBy: user?.id ?? 'unknown',
          createdAt: now,
          updatedAt: now,
          dueAt: state.dueAt,
          locationLabel: state.locationLabel.trim().isEmpty
              ? null
              : state.locationLabel.trim(),
        );
      } else {
        final existing = await ref
            .read(workOrderRepositoryProvider)
            .findById(state.existingId!);
        if (existing == null) throw StateError('Work order not found');
        order = existing.copyWith(
          title: state.title.trim(),
          description: state.description.trim(),
          priority: state.priority,
          dueAt: state.dueAt,
          locationLabel: state.locationLabel.trim().isEmpty
              ? null
              : state.locationLabel.trim(),
          assignedTo: state.assignedTo.trim().isEmpty
              ? existing.assignedTo
              : state.assignedTo.trim(),
          updatedAt: now,
        );
      }

      await ref.read(workOrderRepositoryProvider).save(order);
      // Fire-and-forget sync so the change reaches the server immediately.
      ref.read(syncEngineProvider).sync();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final workOrderFormViewModelProvider =
    AutoDisposeNotifierProvider<WorkOrderFormViewModel, WorkOrderFormState>(
        WorkOrderFormViewModel.new);

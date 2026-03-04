import 'package:collection/collection.dart';
import 'package:fieldops/core/permissions/permission.dart';
import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/router/route_names.dart';
import 'package:fieldops/core/theme/app_theme.dart';
import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/notes/presentation/widgets/add_note_sheet.dart';
import 'package:fieldops/features/notes/presentation/widgets/notes_list.dart';
import 'package:fieldops/features/photos/presentation/widgets/photo_capture_button.dart';
import 'package:fieldops/features/photos/presentation/widgets/photo_grid.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:fieldops/core/realtime/presence_user.dart';
import 'package:fieldops/features/work_orders/presentation/viewmodels/realtime_work_order_notifier.dart';
import 'package:fieldops/features/work_orders/presentation/viewmodels/work_order_detail_viewmodel.dart';
import 'package:fieldops/features/work_orders/presentation/widgets/status_badge.dart';
import 'package:fieldops/shared/widgets/confirm_dialog.dart';
import 'package:fieldops/shared/widgets/error_view.dart';
import 'package:fieldops/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkOrderDetailScreen extends ConsumerWidget {
  const WorkOrderDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate realtime subscription — autoDispose tears it down on pop.
    ref.watch(realtimeWorkOrderProvider(id));
    final presenceAsync = ref.watch(workOrderPresenceProvider(id));
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    final orderAsync = ref.watch(workOrderDetailProvider(id));
    final permService = ref.watch(permissionServiceProvider);

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return const Scaffold(
            body: Center(child: Text('Work order not found')),
          );
        }
        final statusColor = StatusBadge.colorFor(order.status);
        return Scaffold(
          appBar: AppBar(
            title: Text(order.title, overflow: TextOverflow.ellipsis),
            actions: [
              if (permService.can(Permission.editWorkOrder))
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context
                      .push('${RouteNames.workOrderDetailPath(id)}/edit'),
                ),
              if (permService.can(Permission.deleteWorkOrder))
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Presence bar — shows other users currently viewing this order
              presenceAsync.whenData((users) {
                    final others =
                        users.where((u) => u.userId != currentUserId).toList();
                    if (others.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PresenceBar(users: others),
                    );
                  }).valueOrNull ??
                  const SizedBox.shrink(),

              // Status hero band
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Status + SLA context
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(order.status),
                  _PriorityChip(priority: order.priority),
                  if (order.dueAt != null)
                    _SlaChip(
                      label: order.isOverdue
                          ? DateFormatter.relativeDeadline(order.dueAt!)
                          : order.isClosed
                              ? 'Due ${DateFormatter.formatDate(order.dueAt!)}'
                              : DateFormatter.relativeDeadline(order.dueAt!),
                      isOverdue: order.isOverdue,
                    ),
                  if (order.isDirty)
                    const WorkOrderPillChip(
                      label: 'Unsynced',
                      icon: Icons.cloud_upload_outlined,
                      color: AppColors.orange,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Status changer
              if (permService.can(Permission.changeStatus))
                _StatusChanger(orderId: id, current: order.status),

              const SizedBox(height: 16),
              _Section(
                title: 'Description',
                child: Text(order.description.isEmpty
                    ? 'No description'
                    : order.description),
              ),
              if (order.locationLabel != null)
                _Section(
                  title: 'Location',
                  child: Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.statusInProgress),
                    const SizedBox(width: 4),
                    Text(order.locationLabel!),
                  ]),
                ),
              _Section(
                title: 'Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Detail(
                      'Assigned to',
                      ref.watch(assignableUsersProvider).maybeWhen(
                            data: (users) =>
                                users
                                    .firstWhereOrNull(
                                      (u) => u.id == order.assignedTo,
                                    )
                                    ?.displayName ??
                                order.assignedTo,
                            orElse: () => order.assignedTo,
                          ),
                    ),
                    _Detail('Priority', _priorityLabel(order.priority)),
                    _Detail(
                      'Due by',
                      order.dueAt == null
                          ? 'No due date set'
                          : DateFormatter.formatDateTime(order.dueAt!),
                    ),
                    _Detail(
                      'SLA',
                      order.dueAt == null
                          ? 'Not tracked'
                          : order.isOverdue
                              ? DateFormatter.relativeDeadline(order.dueAt!)
                              : order.isClosed
                                  ? 'Closed'
                                  : 'On track',
                    ),
                    _Detail('Created by', order.createdBy),
                    _Detail('Created',
                        DateFormatter.formatDateTime(order.createdAt)),
                    _Detail('Updated',
                        DateFormatter.formatDateTime(order.updatedAt)),
                  ],
                ),
              ),

              // Photos
              _Section(
                title: 'Photos',
                trailing: permService.can(Permission.addPhoto)
                    ? PhotoCaptureButton(workOrderId: id)
                    : null,
                child: PhotoGrid(workOrderId: id),
              ),

              // Notes
              _Section(
                title: 'Notes',
                trailing: permService.can(Permission.addNote)
                    ? IconButton(
                        icon: const Icon(Icons.add_comment_outlined),
                        onPressed: () =>
                            showAddNoteSheet(context, ref, workOrderId: id),
                      )
                    : null,
                child: NotesList(workOrderId: id),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => Scaffold(body: ErrorView(error: e)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Work Order',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      await ref.read(workOrderRepositoryProvider).delete(id);
      ref.read(syncEngineProvider).sync();
      if (context.mounted) context.pop();
    }
  }

  String _priorityLabel(WorkOrderPriority priority) => switch (priority) {
        WorkOrderPriority.low => 'Low',
        WorkOrderPriority.medium => 'Medium',
        WorkOrderPriority.high => 'High',
        WorkOrderPriority.urgent => 'Urgent',
      };
}

class _StatusChanger extends ConsumerWidget {
  const _StatusChanger({required this.orderId, required this.current});

  final String orderId;
  final WorkOrderStatus current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Text('Status:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 12),
            DropdownButton<WorkOrderStatus>(
              value: current,
              underline: const SizedBox.shrink(),
              items: WorkOrderStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_label(s)),
                      ))
                  .toList(),
              onChanged: (s) async {
                if (s == null || s == current) return;
                final order = await ref
                    .read(workOrderRepositoryProvider)
                    .findById(orderId);
                if (order != null) {
                  await ref.read(workOrderRepositoryProvider).save(
                        order.copyWith(
                          status: s,
                          completedAt: s == WorkOrderStatus.completed
                              ? DateTime.now().toUtc()
                              : null,
                        ),
                      );
                  ref.read(syncEngineProvider).sync();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _label(WorkOrderStatus s) => switch (s) {
        WorkOrderStatus.newOrder => 'New',
        WorkOrderStatus.inProgress => 'In Progress',
        WorkOrderStatus.completed => 'Completed',
        WorkOrderStatus.verified => 'Verified',
      };
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final WorkOrderPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      WorkOrderPriority.low => Colors.blueGrey,
      WorkOrderPriority.medium => AppColors.statusNew,
      WorkOrderPriority.high => AppColors.orange,
      WorkOrderPriority.urgent => const Color(0xFFB71C1C),
    };
    final label = switch (priority) {
      WorkOrderPriority.low => 'Low',
      WorkOrderPriority.medium => 'Medium',
      WorkOrderPriority.high => 'High',
      WorkOrderPriority.urgent => 'Urgent',
    };
    return WorkOrderPillChip(
      label: label,
      icon: Icons.flag_outlined,
      color: color,
    );
  }
}

class _SlaChip extends StatelessWidget {
  const _SlaChip({required this.label, required this.isOverdue});

  final String label;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final color =
        isOverdue ? Theme.of(context).colorScheme.error : AppColors.navy;
    return WorkOrderPillChip(
      label: label,
      icon: isOverdue ? Icons.warning_amber_rounded : Icons.schedule_outlined,
      color: color,
      backgroundAlpha: 16,
      borderAlpha: 36,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Left accent border on section title
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceBar extends StatelessWidget {
  const _PresenceBar({required this.users});

  final List<PresenceUser> users;

  @override
  Widget build(BuildContext context) {
    final editing = users.where((u) => u.isEditing).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility_outlined,
                size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            ...users.map((u) => _Avatar(user: u)),
            const SizedBox(width: 4),
            Text(
              '${users.length} viewing',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        if (editing.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.edit, size: 11, color: AppColors.statusInProgress),
              const SizedBox(width: 4),
              Text(
                '${editing.map((u) => u.displayName).join(', ')} '
                '${editing.length == 1 ? 'is' : 'are'} editing…',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.statusInProgress,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final PresenceUser user;

  @override
  Widget build(BuildContext context) {
    final initials =
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';
    return Tooltip(
      message: user.displayName,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: _colorFor(user.userId),
          shape: BoxShape.circle,
          border: user.isEditing
              ? Border.all(color: AppColors.statusInProgress, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Deterministic colour from user ID hash — consistent across rebuilds.
  Color _colorFor(String userId) {
    final hue = (userId.hashCode.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor();
  }
}

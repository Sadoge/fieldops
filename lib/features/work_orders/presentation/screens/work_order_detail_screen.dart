import 'package:fieldops/core/permissions/permission.dart';
import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/router/route_names.dart';
import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/notes/presentation/widgets/add_note_sheet.dart';
import 'package:fieldops/features/notes/presentation/widgets/notes_list.dart';
import 'package:fieldops/features/photos/presentation/widgets/photo_capture_button.dart';
import 'package:fieldops/features/photos/presentation/widgets/photo_grid.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
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
    final orderAsync = ref.watch(workOrderDetailProvider(id));
    final permService = ref.watch(permissionServiceProvider);

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return const Scaffold(
            body: Center(child: Text('Work order not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(order.title, overflow: TextOverflow.ellipsis),
            actions: [
              if (permService.can(Permission.editWorkOrder))
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push('${RouteNames.workOrderDetailPath(id)}/edit'),
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
              // Status + meta
              Row(
                children: [
                  StatusBadge(order.status),
                  const Spacer(),
                  if (order.isDirty)
                    const Chip(
                      label: Text('Unsynced', style: TextStyle(fontSize: 11)),
                      avatar: Icon(Icons.cloud_upload_outlined, size: 14),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
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
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(order.locationLabel!),
                  ]),
                ),
              _Section(
                title: 'Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Detail('Assigned to', order.assignedTo),
                    _Detail('Created by', order.createdBy),
                    _Detail('Created', DateFormatter.formatDateTime(order.createdAt)),
                    _Detail('Updated', DateFormatter.formatDateTime(order.updatedAt)),
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
                        onPressed: () => showAddNoteSheet(context, ref, workOrderId: id),
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
      if (context.mounted) context.pop();
    }
  }
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
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.w500)),
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
                final order =
                    await ref.read(workOrderRepositoryProvider).findById(orderId);
                if (order != null) {
                  await ref.read(workOrderRepositoryProvider).save(
                        order.copyWith(
                          status: s,
                          completedAt: s == WorkOrderStatus.completed
                              ? DateTime.now().toUtc()
                              : null,
                        ),
                      );
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 6),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

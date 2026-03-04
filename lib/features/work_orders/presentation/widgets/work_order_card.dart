import 'package:fieldops/core/theme/app_theme.dart';
import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:fieldops/features/work_orders/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.order, required this.onTap});

  final WorkOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusBadge.colorFor(order.status);
    final initials = _initials(order.assignedTo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status stripe
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 13, 14, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(order.status),
                          ],
                        ),
                        if (order.description.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            order.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _MetaChip(
                              icon: Icons.flag_outlined,
                              label: _priorityLabel(order.priority),
                              foreground: _priorityColor(order.priority),
                              background:
                                  _priorityColor(order.priority).withAlpha(20),
                            ),
                            if (order.dueAt != null)
                              _MetaChip(
                                icon: order.isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.schedule_outlined,
                                label: _slaLabel(order),
                                foreground: order.isOverdue
                                    ? Theme.of(context).colorScheme.error
                                    : AppColors.navy,
                                background: order.isOverdue
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.error.withAlpha(20)
                                    : AppColors.navy.withAlpha(18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (order.locationLabel != null) ...[
                              Icon(Icons.location_on_outlined,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  order.locationLabel!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Spacer(),
                            if (order.isDirty) ...[
                              Tooltip(
                                message: 'Pending sync',
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (initials != null) ...[
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: AppColors.navy,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              DateFormatter.timeAgo(order.updatedAt),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _initials(String? assignedTo) {
    if (assignedTo == null || assignedTo.isEmpty) return null;
    final parts = assignedTo.trim().split(RegExp(r'[\s._@-]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return assignedTo
        .substring(0, assignedTo.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  String _priorityLabel(WorkOrderPriority priority) => switch (priority) {
        WorkOrderPriority.low => 'Low',
        WorkOrderPriority.medium => 'Medium',
        WorkOrderPriority.high => 'High',
        WorkOrderPriority.urgent => 'Urgent',
      };

  Color _priorityColor(WorkOrderPriority priority) => switch (priority) {
        WorkOrderPriority.low => Colors.blueGrey,
        WorkOrderPriority.medium => AppColors.statusNew,
        WorkOrderPriority.high => AppColors.orange,
        WorkOrderPriority.urgent => const Color(0xFFB71C1C),
      };

  String _slaLabel(WorkOrder order) {
    final dueAt = order.dueAt;
    if (dueAt == null) return '';
    if (order.isOverdue) return DateFormatter.relativeDeadline(dueAt);
    if (order.isClosed) return 'Due ${DateFormatter.formatDate(dueAt)}';
    return DateFormatter.relativeDeadline(dueAt);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

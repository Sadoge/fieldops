import 'package:fieldops/core/theme/app_theme.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:flutter/material.dart';

class WorkOrderPillChip extends StatelessWidget {
  const WorkOrderPillChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.backgroundAlpha = 18,
    this.borderAlpha = 40,
    this.iconSize = 14,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int backgroundAlpha;
  final int borderAlpha;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      avatar: Icon(icon, size: iconSize, color: color),
      avatarBoxConstraints: const BoxConstraints(
        minHeight: 18,
        minWidth: 18,
      ),
      labelPadding: const EdgeInsets.only(right: 2),
      backgroundColor: color.withAlpha(backgroundAlpha),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: color.withAlpha(borderAlpha), width: 1),
      shape: const StadiumBorder(),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final WorkOrderStatus status;

  static Color colorFor(WorkOrderStatus status) => switch (status) {
        WorkOrderStatus.newOrder => AppColors.statusNew,
        WorkOrderStatus.inProgress => AppColors.statusInProgress,
        WorkOrderStatus.completed => AppColors.statusCompleted,
        WorkOrderStatus.verified => AppColors.statusVerified,
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      WorkOrderStatus.newOrder => ('New', AppColors.statusNew),
      WorkOrderStatus.inProgress => ('In Progress', AppColors.statusInProgress),
      WorkOrderStatus.completed => ('Completed', AppColors.statusCompleted),
      WorkOrderStatus.verified => ('Verified', AppColors.statusVerified),
    };

    return WorkOrderPillChip(
      label: label,
      icon: Icons.circle,
      iconSize: 10,
      color: color,
    );
  }
}

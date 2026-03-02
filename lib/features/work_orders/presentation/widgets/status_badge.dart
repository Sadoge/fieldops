import 'package:fieldops/core/theme/app_theme.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:flutter/material.dart';

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(180), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

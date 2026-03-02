import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final WorkOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      WorkOrderStatus.newOrder => ('New', Colors.blue),
      WorkOrderStatus.inProgress => ('In Progress', Colors.orange),
      WorkOrderStatus.completed => ('Completed', Colors.green),
      WorkOrderStatus.verified => ('Verified', Colors.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

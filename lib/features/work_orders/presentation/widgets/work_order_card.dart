import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.order, required this.onTap});

  final WorkOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(order.status),
                ],
              ),
              if (order.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (order.locationLabel != null) ...[
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        order.locationLabel!,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  if (order.isDirty)
                    const Tooltip(
                      message: 'Pending sync',
                      child: Icon(Icons.cloud_upload_outlined,
                          size: 13, color: Colors.amber),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.timeAgo(order.updatedAt),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

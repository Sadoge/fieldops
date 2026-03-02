import 'package:fieldops/core/theme/app_theme.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:fieldops/features/work_orders/presentation/viewmodels/work_order_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkOrderFilterBar extends ConsumerStatefulWidget {
  const WorkOrderFilterBar({super.key});

  @override
  ConsumerState<WorkOrderFilterBar> createState() => _WorkOrderFilterBarState();
}

class _WorkOrderFilterBarState extends ConsumerState<WorkOrderFilterBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(activeFilterProvider);
    final vm = ref.read(activeFilterProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.concreteVariant,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search work orders…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: filter.searchQuery?.isNotEmpty == true
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: vm.setSearchQuery,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusChip(
                  label: 'All',
                  selected: filter.status == null,
                  selectedColor: AppColors.orange,
                  onTap: () => vm.setStatus(null),
                ),
                ...WorkOrderStatus.values.map((s) => _StatusChip(
                      label: _statusLabel(s),
                      selected: filter.status == s,
                      selectedColor: _statusColor(s),
                      onTap: () => vm.setStatus(s),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(WorkOrderStatus s) => switch (s) {
        WorkOrderStatus.newOrder => 'New',
        WorkOrderStatus.inProgress => 'In Progress',
        WorkOrderStatus.completed => 'Completed',
        WorkOrderStatus.verified => 'Verified',
      };

  Color _statusColor(WorkOrderStatus s) => switch (s) {
        WorkOrderStatus.newOrder => AppColors.statusNew,
        WorkOrderStatus.inProgress => AppColors.statusInProgress,
        WorkOrderStatus.completed => AppColors.statusCompleted,
        WorkOrderStatus.verified => AppColors.statusVerified,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: selectedColor,
        checkmarkColor: Colors.white,
        visualDensity: VisualDensity.compact,
        showCheckmark: false,
        side: selected
            ? BorderSide(color: selectedColor, width: 1)
            : BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    );
  }
}

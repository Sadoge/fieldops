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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search work orders…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.searchQuery?.isNotEmpty == true
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
            ),
            onChanged: vm.setSearchQuery,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(
                  label: 'All',
                  selected: filter.status == null,
                  onTap: () => vm.setStatus(null),
                ),
                ...WorkOrderStatus.values.map((s) => _Chip(
                      label: _statusLabel(s),
                      selected: filter.status == s,
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
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

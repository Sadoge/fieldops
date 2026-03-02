import 'package:fieldops/core/providers.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_filter.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Filter ViewModel ──────────────────────────────────────────────────────────

class ActiveFilterNotifier extends Notifier<WorkOrderFilter> {
  @override
  WorkOrderFilter build() => const WorkOrderFilter();

  void setStatus(WorkOrderStatus? status) =>
      state = state.copyWith(status: status, clearStatus: status == null);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void clear() => state = const WorkOrderFilter();
}

final activeFilterProvider =
    NotifierProvider<ActiveFilterNotifier, WorkOrderFilter>(
        ActiveFilterNotifier.new);

// ── List ViewModel ────────────────────────────────────────────────────────────

final workOrderListProvider = StreamProvider<List<WorkOrder>>((ref) {
  final repo = ref.watch(workOrderRepositoryProvider);
  final filter = ref.watch(activeFilterProvider);
  return repo.watchAll(filter: filter);
});

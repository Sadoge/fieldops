import 'package:fieldops/core/providers.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_filter.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Realtime list update banner ───────────────────────────────────────────────

/// True when a remote work order change has arrived since the user last
/// acknowledged it. Cleared when the user taps the "Updates available" banner.
class _ListUpdateNotifier extends AutoDisposeNotifier<bool> {
  @override
  bool build() {
    final sub = ref
        .watch(realtimeServiceProvider)
        .watchWorkOrderList()
        .listen((_) => state = true);
    ref.onDispose(sub.cancel);
    return false;
  }

  void dismiss() => state = false;
}

final listUpdateProvider =
    AutoDisposeNotifierProvider<_ListUpdateNotifier, bool>(
  _ListUpdateNotifier.new,
);

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

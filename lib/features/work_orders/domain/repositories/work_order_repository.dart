import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_filter.dart';

abstract class WorkOrderRepository {
  Stream<List<WorkOrder>> watchAll({WorkOrderFilter? filter});
  Future<WorkOrder?> findById(String id);
  Future<void> save(WorkOrder order);
  /// Updates the local record only — does NOT enqueue a sync item.
  /// Used by the sync engine after a successful push to clear dirty state.
  Future<void> updateLocalOnly(WorkOrder order);
  Future<void> delete(String id);
}

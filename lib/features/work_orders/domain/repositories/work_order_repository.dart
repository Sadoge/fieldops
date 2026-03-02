import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_filter.dart';

abstract class WorkOrderRepository {
  Stream<List<WorkOrder>> watchAll({WorkOrderFilter? filter});
  Future<WorkOrder?> findById(String id);
  Future<void> save(WorkOrder order);
  Future<void> delete(String id);
}

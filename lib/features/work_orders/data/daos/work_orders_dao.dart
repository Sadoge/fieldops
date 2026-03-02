import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/work_orders_table.dart';

part 'work_orders_dao.g.dart';

@DriftAccessor(tables: [WorkOrders])
class WorkOrdersDao extends DatabaseAccessor<AppDatabase>
    with _$WorkOrdersDaoMixin {
  WorkOrdersDao(super.db);

  Stream<List<WorkOrderRow>> watchAll() => (select(workOrders)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<WorkOrderRow>> watchFiltered({
    String? searchQuery,
    WorkOrderStatus? status,
  }) {
    return (select(workOrders)
          ..where((t) {
            Expression<bool> filter = const Constant(true);
            if (status != null) {
              filter = filter & t.status.equalsValue(status);
            }
            if (searchQuery != null && searchQuery.isNotEmpty) {
              filter = filter &
                  (t.title.contains(searchQuery) |
                      t.description.contains(searchQuery) |
                      t.locationLabel.contains(searchQuery));
            }
            return filter;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<WorkOrderRow?> findById(String id) =>
      (select(workOrders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(WorkOrdersCompanion entry) =>
      into(workOrders).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(workOrders)..where((t) => t.id.equals(id))).go();

  Future<List<WorkOrderRow>> findDirty() =>
      (select(workOrders)..where((t) => t.isDirty)).get();
}

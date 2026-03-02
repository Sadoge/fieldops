import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/photos_table.dart';

part 'photos_dao.g.dart';

@DriftAccessor(tables: [Photos])
class PhotosDao extends DatabaseAccessor<AppDatabase>
    with _$PhotosDaoMixin {
  PhotosDao(super.db);

  Stream<List<PhotoRow>> watchByWorkOrder(String workOrderId) =>
      (select(photos)
            ..where((t) => t.workOrderId.equals(workOrderId))
            ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
          .watch();

  Future<PhotoRow?> findById(String id) =>
      (select(photos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(PhotosCompanion entry) =>
      into(photos).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(photos)..where((t) => t.id.equals(id))).go();

  Future<List<PhotoRow>> findUnsynced() =>
      (select(photos)..where((t) => t.isSynced.not())).get();
}

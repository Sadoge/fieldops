import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Stream<int> watchPendingCount() {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equalsValue(SyncItemStatus.pending) |
          syncQueue.status.equalsValue(SyncItemStatus.failed));
    return query.map((row) => row.read(syncQueue.id.count()) ?? 0).watchSingle();
  }

  Future<List<SyncQueueData>> pendingItems() =>
      (select(syncQueue)
            ..where((t) =>
                t.status.equalsValue(SyncItemStatus.pending) |
                t.status.equalsValue(SyncItemStatus.failed))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> enqueue(SyncQueueCompanion entry) =>
      into(syncQueue).insert(entry);

  Future<void> updateStatus(int id, SyncItemStatus status,
      {String? error, DateTime? nextRetry}) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        SyncQueueCompanion(
          status: Value(status),
          lastError: Value(error),
          nextRetryAt: Value(nextRetry),
        ),
      );

  Future<void> incrementRetry(int id, String error, DateTime nextRetry) =>
      customUpdate(
        'UPDATE sync_queue SET retry_count = retry_count + 1, status = ?, '
        'last_error = ?, next_retry_at = ? WHERE id = ?',
        variables: [
          Variable.withString(SyncItemStatus.failed.name),
          Variable.withString(error),
          Variable.withDateTime(nextRetry),
          Variable.withInt(id),
        ],
        updates: {syncQueue},
      );
}

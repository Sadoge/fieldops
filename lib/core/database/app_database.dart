import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/work_orders_table.dart';
import 'tables/photos_table.dart';
import 'tables/notes_table.dart';
import 'tables/audit_log_table.dart';
import 'tables/sync_queue_table.dart';
import '../../features/work_orders/data/daos/work_orders_dao.dart';
import '../../features/photos/data/daos/photos_dao.dart';
import '../../features/notes/data/daos/notes_dao.dart';
import '../../features/audit_log/data/daos/audit_log_dao.dart';
import '../sync/sync_queue_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [WorkOrders, Photos, Notes, AuditLog, SyncQueue],
  daos: [WorkOrdersDao, PhotosDao, NotesDao, AuditLogDao, SyncQueueDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Named constructor for unit tests — pass an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {},
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'fieldops',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
    native: DriftNativeOptions(
      databasePath: () async {
        final dir = await getApplicationDocumentsDirectory();
        return p.join(dir.path, 'fieldops.sqlite');
      },
    ),
  );
}

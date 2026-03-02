import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<NoteRow>> watchByWorkOrder(String workOrderId) =>
      (select(notes)
            ..where((t) => t.workOrderId.equals(workOrderId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> upsert(NotesCompanion entry) =>
      into(notes).insertOnConflictUpdate(entry);

  Future<List<NoteRow>> findUnsynced() =>
      (select(notes)..where((t) => t.isSynced.not())).get();
}

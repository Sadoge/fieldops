import 'package:fieldops/features/notes/domain/entities/note.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchByWorkOrder(String workOrderId);
  Future<void> add(Note note);
  Future<List<Note>> findUnsynced();

  /// Upserts a note that arrived from the server via realtime or pull-sync.
  /// Does NOT enqueue a sync item — server-originated writes must never be re-pushed.
  Future<void> addFromRemote(Map<String, dynamic> payload);
}

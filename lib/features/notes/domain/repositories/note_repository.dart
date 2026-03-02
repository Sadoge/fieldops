import 'package:fieldops/features/notes/domain/entities/note.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchByWorkOrder(String workOrderId);
  Future<void> add(Note note);
  Future<List<Note>> findUnsynced();
}

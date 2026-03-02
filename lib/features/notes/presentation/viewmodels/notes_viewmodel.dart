import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/utils/id_generator.dart';
import 'package:fieldops/features/notes/domain/entities/note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notesProvider =
    StreamProvider.family<List<Note>, String>((ref, workOrderId) {
  return ref.watch(noteRepositoryProvider).watchByWorkOrder(workOrderId);
});

class NotesViewModel extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addNote({
    required String workOrderId,
    required String body,
  }) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final note = Note(
      id: IdGenerator.newId(),
      workOrderId: workOrderId,
      body: body.trim(),
      createdBy: user?.id ?? 'unknown',
      createdAt: DateTime.now().toUtc(),
    );
    await ref.read(noteRepositoryProvider).add(note);
    ref.read(syncEngineProvider).sync();
  }
}

final notesViewModelProvider =
    AsyncNotifierProvider.autoDispose<NotesViewModel, void>(NotesViewModel.new);

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/sync_queue_table.dart';
import 'package:fieldops/core/sync/sync_queue_dao.dart';
import 'package:fieldops/features/notes/data/daos/notes_dao.dart';
import 'package:fieldops/features/notes/domain/entities/note.dart';
import 'package:fieldops/features/notes/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this.dao, required this.syncQueueDao});

  final NotesDao dao;
  final SyncQueueDao syncQueueDao;

  @override
  Stream<List<Note>> watchByWorkOrder(String workOrderId) =>
      dao.watchByWorkOrder(workOrderId).map(
            (rows) => rows
                .map((d) => Note(
                      id: d.id,
                      workOrderId: d.workOrderId,
                      body: d.body,
                      createdBy: d.createdBy,
                      createdAt: d.createdAt,
                      isSynced: d.isSynced,
                    ))
                .toList(),
          );

  @override
  Future<void> add(Note note) async {
    await dao.upsert(NotesCompanion(
      id: Value(note.id),
      workOrderId: Value(note.workOrderId),
      body: Value(note.body),
      createdBy: Value(note.createdBy),
      createdAt: Value(note.createdAt),
      isSynced: const Value(false),
    ));
    final now = DateTime.now().toUtc();
    await syncQueueDao.enqueue(SyncQueueCompanion(
      entityType: const Value('note'),
      entityId: Value(note.id),
      operation: const Value(SyncOperation.create),
      status: const Value(SyncItemStatus.pending),
      payload: Value(jsonEncode({
        'id': note.id,
        'workOrderId': note.workOrderId,
        'body': note.body,
        'createdBy': note.createdBy,
        'createdAt': note.createdAt.toIso8601String(),
      })),
      createdAt: Value(now),
    ));
  }

  @override
  Future<void> addFromRemote(Map<String, dynamic> payload) async {
    await dao.upsert(NotesCompanion(
      id: Value(payload['id'] as String),
      workOrderId: Value(payload['workOrderId'] as String),
      body: Value(payload['body'] as String),
      createdBy: Value(payload['createdBy'] as String? ?? ''),
      createdAt: Value(DateTime.parse(payload['createdAt'] as String)),
      isSynced: const Value(true),
    ));
  }

  @override
  Future<List<Note>> findUnsynced() async {
    final rows = await dao.findUnsynced();
    return rows
        .map((d) => Note(
              id: d.id,
              workOrderId: d.workOrderId,
              body: d.body,
              createdBy: d.createdBy,
              createdAt: d.createdAt,
              isSynced: d.isSynced,
            ))
        .toList();
  }
}

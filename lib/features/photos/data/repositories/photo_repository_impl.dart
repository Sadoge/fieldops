import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/sync_queue_table.dart';
import 'package:fieldops/core/sync/sync_queue_dao.dart';
import 'package:fieldops/features/photos/data/daos/photos_dao.dart';
import 'package:fieldops/features/photos/domain/entities/photo.dart';
import 'package:fieldops/features/photos/domain/repositories/photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({required this.dao, required this.syncQueueDao});

  final PhotosDao dao;
  final SyncQueueDao syncQueueDao;

  @override
  Stream<List<Photo>> watchByWorkOrder(String workOrderId) =>
      dao.watchByWorkOrder(workOrderId).map(
            (rows) => rows
                .map((d) => Photo(
                      id: d.id,
                      workOrderId: d.workOrderId,
                      localPath: d.localPath,
                      remoteUrl: d.remoteUrl,
                      capturedAt: d.capturedAt,
                      capturedBy: d.capturedBy,
                      fileSizeBytes: d.fileSizeBytes,
                      isSynced: d.isSynced,
                    ))
                .toList(),
          );

  @override
  Future<Photo?> findById(String id) async {
    final d = await dao.findById(id);
    if (d == null) return null;
    return Photo(
      id: d.id,
      workOrderId: d.workOrderId,
      localPath: d.localPath,
      remoteUrl: d.remoteUrl,
      capturedAt: d.capturedAt,
      capturedBy: d.capturedBy,
      fileSizeBytes: d.fileSizeBytes,
      isSynced: d.isSynced,
    );
  }

  @override
  Future<void> save(Photo photo) async {
    await dao.upsert(PhotosCompanion(
      id: Value(photo.id),
      workOrderId: Value(photo.workOrderId),
      localPath: Value(photo.localPath),
      remoteUrl: Value(photo.remoteUrl),
      capturedAt: Value(photo.capturedAt),
      capturedBy: Value(photo.capturedBy),
      fileSizeBytes: Value(photo.fileSizeBytes),
      isSynced: Value(photo.isSynced),
    ));
    if (!photo.isSynced) {
      final now = DateTime.now().toUtc();
      await syncQueueDao.enqueue(SyncQueueCompanion(
        entityType: const Value('photo'),
        entityId: Value(photo.id),
        operation: const Value(SyncOperation.create),
        status: const Value(SyncItemStatus.pending),
        payload: Value(jsonEncode({
          'id': photo.id,
          'workOrderId': photo.workOrderId,
          'localPath': photo.localPath,
          'capturedAt': photo.capturedAt.toIso8601String(),
          'capturedBy': photo.capturedBy,
        })),
        createdAt: Value(now),
      ));
    }
  }

  @override
  Future<void> delete(String id) => dao.deleteById(id);

  @override
  Future<List<Photo>> findUnsynced() async {
    final rows = await dao.findUnsynced();
    return rows
        .map((d) => Photo(
              id: d.id,
              workOrderId: d.workOrderId,
              localPath: d.localPath,
              remoteUrl: d.remoteUrl,
              capturedAt: d.capturedAt,
              capturedBy: d.capturedBy,
              fileSizeBytes: d.fileSizeBytes,
              isSynced: d.isSynced,
            ))
        .toList();
  }
}

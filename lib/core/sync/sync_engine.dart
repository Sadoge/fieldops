import 'dart:convert';

import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/database/tables/sync_queue_table.dart';
import 'package:fieldops/core/network/remote_client.dart';
import 'package:fieldops/core/sync/conflict_resolver.dart';
import 'package:fieldops/core/sync/retry_policy.dart';
import 'package:fieldops/core/sync/sync_queue_dao.dart';
import 'package:fieldops/core/sync/sync_status_notifier.dart';
import 'package:fieldops/features/photos/domain/repositories/photo_repository.dart';
import 'package:fieldops/features/work_orders/domain/repositories/work_order_repository.dart';

class SyncEngine {
  SyncEngine({
    required this.syncQueueDao,
    required this.workOrderRepo,
    required this.photoRepo,
    required this.remoteClient,
    required this.conflictResolver,
    required this.statusNotifier,
  });

  final SyncQueueDao syncQueueDao;
  final WorkOrderRepository workOrderRepo;
  final PhotoRepository photoRepo;
  final RemoteClient remoteClient;
  final ConflictResolver conflictResolver;
  final SyncStatusNotifier statusNotifier;

  bool _isRunning = false;

  Future<void> sync() async {
    if (_isRunning) return;
    _isRunning = true;
    statusNotifier.setSyncing();

    try {
      await _pullRemoteChanges();
      await _pushPendingItems();
      statusNotifier.setSuccess(DateTime.now().toUtc());
    } catch (e) {
      statusNotifier.setError(e.toString());
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _pullRemoteChanges() async {
    final since = statusNotifier.lastSyncedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final changes = await remoteClient.pullChanges(since);
    for (final change in changes) {
      await conflictResolver.resolveIncoming(change);
    }
  }

  Future<void> _pushPendingItems() async {
    final items = await syncQueueDao.pendingItems();
    final now = DateTime.now().toUtc();
    final due = items.where(
      (i) => i.nextRetryAt == null || i.nextRetryAt!.isBefore(now),
    );

    for (final item in due) {
      await syncQueueDao.updateStatus(item.id, SyncItemStatus.inFlight);
      try {
        await _processItem(item);
        await syncQueueDao.updateStatus(item.id, SyncItemStatus.completed);
      } catch (e) {
        final newCount = item.retryCount + 1;
        if (RetryPolicy.shouldAbandon(newCount)) {
          await syncQueueDao.updateStatus(
            item.id,
            SyncItemStatus.failed,
            error: 'Max retries exceeded after: $e',
          );
        } else {
          await syncQueueDao.incrementRetry(
            item.id,
            e.toString(),
            RetryPolicy.nextRetryAt(newCount),
          );
        }
      }
    }
  }

  Future<void> _processItem(SyncQueueData item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    switch (item.entityType) {
      case 'work_order':
        if (item.operation == SyncOperation.delete) {
          await remoteClient.deleteEntity(
              entityType: 'work_order', entityId: item.entityId);
        } else {
          final remote = await remoteClient.pushWorkOrder(payload);
          final local = await workOrderRepo.findById(item.entityId);
          if (local != null) {
            await workOrderRepo.save(local.copyWith(
              remoteId: remote['remoteId'] as String?,
              serverVersion: remote['serverVersion'] as int?,
              isDirty: false,
            ));
          }
        }

      case 'photo':
        final url = await remoteClient.uploadPhoto(
          localPath: payload['localPath'] as String,
          metadata: payload,
        );
        final photo = await photoRepo.findById(item.entityId);
        if (photo != null) {
          await photoRepo.save(photo.copyWith(remoteUrl: url, isSynced: true));
        }

      case 'note':
        await remoteClient.pushNote(payload);
    }
  }
}

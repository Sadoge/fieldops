import 'dart:async';

import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/realtime/presence_user.dart';
import 'package:fieldops/core/realtime/realtime_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the Supabase Realtime subscription lifecycle for a single work order
/// detail screen.
///
/// - Subscribes to work order row changes → funnels through ConflictResolver
///   → writes to Drift → existing [workOrderDetailProvider] re-emits naturally.
/// - Subscribes to note changes → calls NoteRepository.addFromRemote.
/// - Joins the presence channel so other users see this user is viewing.
/// - AutoDispose ensures the channel is torn down when the screen is popped.
class RealtimeWorkOrderNotifier
    extends AutoDisposeFamilyAsyncNotifier<void, String> {
  StreamSubscription<Map<String, dynamic>>? _orderSub;
  StreamSubscription<Map<String, dynamic>>? _notesSub;

  @override
  Future<void> build(String workOrderId) async {
    // Capture service reference before any await so _cleanup can use it
    // even after the container is disposed (ref becomes invalid post-dispose).
    final realtimeSvc = ref.read(realtimeServiceProvider);
    _subscribe(workOrderId, realtimeSvc);
    await _joinPresence(workOrderId, realtimeSvc);
    ref.onDispose(() => _cleanup(workOrderId, realtimeSvc));
  }

  void _subscribe(String workOrderId, RealtimeService realtimeSvc) {
    final conflictResolver = ref.read(conflictResolverProvider);
    final noteRepo = ref.read(noteRepositoryProvider);

    _orderSub = realtimeSvc.watchWorkOrder(workOrderId).listen(
      (payload) async {
        try {
          await conflictResolver.resolveIncoming(payload);
        } catch (e) {
          // Degrade silently — pull sync will reconcile on next cycle.
          // ignore: avoid_print
          print('[Realtime] work_order update error: $e');
        }
      },
      onError: (Object e) =>
          // ignore: avoid_print
          print('[Realtime] watchWorkOrder stream error (degraded): $e'),
    );

    _notesSub = realtimeSvc.watchNotes(workOrderId).listen(
      (payload) async {
        try {
          await noteRepo.addFromRemote(payload);
        } catch (e) {
          // ignore: avoid_print
          print('[Realtime] note update error: $e');
        }
      },
      onError: (Object e) =>
          // ignore: avoid_print
          print('[Realtime] watchNotes stream error (degraded): $e'),
    );
  }

  Future<void> _joinPresence(
      String workOrderId, RealtimeService realtimeSvc) async {
    // Use the stream's first emitted value to handle async auth providers.
    final user = await ref
        .read(currentUserProvider.future)
        .timeout(const Duration(seconds: 2), onTimeout: () => null);
    if (user == null) return;
    try {
      await realtimeSvc.joinPresence(
        workOrderId: workOrderId,
        userId: user.id,
        displayName: user.displayName,
      );
    } catch (_) {
      // Presence is best-effort — offline or auth errors are silently ignored.
    }
  }

  /// Call this when the user starts or stops editing (e.g. on form focus).
  Future<void> broadcastEditing(bool isEditing) async {
    try {
      await ref.read(realtimeServiceProvider).broadcastEditing(
            workOrderId: arg,
            isEditing: isEditing,
          );
    } catch (_) {}
  }

  Future<void> _cleanup(
      String workOrderId, RealtimeService realtimeSvc) async {
    await _orderSub?.cancel();
    await _notesSub?.cancel();
    try {
      await realtimeSvc.leavePresence(workOrderId);
    } catch (_) {}
  }
}

/// Family provider — one instance per work order ID, auto-disposed on pop.
final realtimeWorkOrderProvider = AsyncNotifierProvider.autoDispose
    .family<RealtimeWorkOrderNotifier, void, String>(
  RealtimeWorkOrderNotifier.new,
);

/// Stream of users currently viewing the given work order.
/// Auto-disposed when no longer watched.
final workOrderPresenceProvider =
    StreamProvider.autoDispose.family<List<PresenceUser>, String>(
  (ref, workOrderId) =>
      ref.watch(realtimeServiceProvider).watchPresence(workOrderId),
);

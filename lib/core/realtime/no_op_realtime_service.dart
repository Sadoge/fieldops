import 'presence_user.dart';
import 'realtime_service.dart';

/// Used when useSupabase = false. All streams are empty; all writes are no-ops.
class NoOpRealtimeService implements RealtimeService {
  @override
  Stream<void> watchWorkOrderList() => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> watchWorkOrder(String workOrderId) =>
      const Stream.empty();

  @override
  Stream<Map<String, dynamic>> watchNotes(String workOrderId) =>
      const Stream.empty();

  @override
  Future<void> joinPresence({
    required String workOrderId,
    required String userId,
    required String displayName,
  }) async {}

  @override
  Future<void> broadcastEditing({
    required String workOrderId,
    required bool isEditing,
  }) async {}

  @override
  Future<void> leavePresence(String workOrderId) async {}

  @override
  Stream<List<PresenceUser>> watchPresence(String workOrderId) =>
      const Stream.empty();

  @override
  void dispose() {}
}

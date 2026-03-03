import 'presence_user.dart';

abstract class RealtimeService {
  /// Stream that emits whenever any work order row changes on the server.
  /// Used by the list screen to show an "updates available" banner.
  Stream<void> watchWorkOrderList();

  /// Stream of normalised work-order payloads (same shape as pullChanges output)
  /// whenever the remote row changes.
  Stream<Map<String, dynamic>> watchWorkOrder(String workOrderId);

  /// Stream of normalised note payloads whenever a note is added/updated for
  /// the given work order.
  Stream<Map<String, dynamic>> watchNotes(String workOrderId);

  /// Join the presence channel for a work order.
  Future<void> joinPresence({
    required String workOrderId,
    required String userId,
    required String displayName,
  });

  /// Broadcast the current user's editing state on the presence channel.
  Future<void> broadcastEditing({
    required String workOrderId,
    required bool isEditing,
  });

  /// Leave the presence channel and clean up the subscription.
  Future<void> leavePresence(String workOrderId);

  /// Stream of active users on the given work order's presence channel.
  Stream<List<PresenceUser>> watchPresence(String workOrderId);

  /// Dispose all channels and resources.
  void dispose();
}

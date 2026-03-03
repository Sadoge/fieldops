import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'presence_user.dart';
import 'realtime_service.dart';

/// Production realtime service backed by Supabase Realtime v2.
///
/// One [RealtimeChannel] per work order ID is created lazily and torn down via
/// [leavePresence]. Each channel handles both Postgres Changes and Presence so
/// that only a single WebSocket subscription is needed per detail screen.
class SupabaseRealtimeService implements RealtimeService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Global list channel ────────────────────────────────────────────────────
  RealtimeChannel? _listChannel;
  StreamController<void>? _listController;

  // ── Per-order detail channels ──────────────────────────────────────────────
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _orderControllers =
      {};
  final Map<String, StreamController<Map<String, dynamic>>> _notesControllers =
      {};
  final Map<String, StreamController<List<PresenceUser>>>
      _presenceControllers = {};

  RealtimeChannel _channelFor(String workOrderId) {
    if (_channels.containsKey(workOrderId)) {
      return _channels[workOrderId]!;
    }

    final orderCtrl =
        StreamController<Map<String, dynamic>>.broadcast();
    final notesCtrl =
        StreamController<Map<String, dynamic>>.broadcast();
    final presenceCtrl =
        StreamController<List<PresenceUser>>.broadcast();

    _orderControllers[workOrderId] = orderCtrl;
    _notesControllers[workOrderId] = notesCtrl;
    _presenceControllers[workOrderId] = presenceCtrl;

    // Build user list from presenceState() and push to the stream.
    void emitPresence() {
      final channel = _channels[workOrderId];
      if (channel == null || presenceCtrl.isClosed) return;
      final users = channel
          .presenceState()
          .expand((s) => s.presences)
          .map((p) {
            try {
              return PresenceUser.fromMap(p.payload);
            } catch (_) {
              return null;
            }
          })
          .whereType<PresenceUser>()
          .toList();
      presenceCtrl.add(users);
    }

    final channel = _client
        .channel('work_order:$workOrderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'work_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: workOrderId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return; // DELETE — let SyncEngine handle
            if (!orderCtrl.isClosed) orderCtrl.add(_normaliseWorkOrder(newRow));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'work_order_id',
            value: workOrderId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return;
            if (!notesCtrl.isClosed) notesCtrl.add(_normaliseNote(newRow));
          },
        )
        .onPresenceSync((_) => emitPresence())
        .onPresenceJoin((_) => emitPresence())
        .onPresenceLeave((_) => emitPresence());

    channel.subscribe();
    _channels[workOrderId] = channel;
    return channel;
  }

  @override
  Stream<void> watchWorkOrderList() {
    if (_listController == null || _listController!.isClosed) {
      _listController = StreamController<void>.broadcast();
      _listChannel = _client
          .channel('work_orders_list')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'work_orders',
            callback: (_) {
              if (!_listController!.isClosed) _listController!.add(null);
            },
          )
        ..subscribe();
    }
    return _listController!.stream;
  }

  @override
  Stream<Map<String, dynamic>> watchWorkOrder(String workOrderId) {
    _channelFor(workOrderId);
    return _orderControllers[workOrderId]!.stream;
  }

  @override
  Stream<Map<String, dynamic>> watchNotes(String workOrderId) {
    _channelFor(workOrderId);
    return _notesControllers[workOrderId]!.stream;
  }

  @override
  Future<void> joinPresence({
    required String workOrderId,
    required String userId,
    required String displayName,
  }) async {
    final channel = _channelFor(workOrderId);
    await channel.track(PresenceUser(
      userId: userId,
      displayName: displayName,
      isEditing: false,
      joinedAt: DateTime.now().toUtc(),
    ).toMap());
  }

  @override
  Future<void> broadcastEditing({
    required String workOrderId,
    required bool isEditing,
  }) async {
    final channel = _channels[workOrderId];
    if (channel == null) return;

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Find our own presence payload to preserve joinedAt and displayName.
    final existing = channel
        .presenceState()
        .expand((s) => s.presences)
        .where((p) => p.payload['user_id'] == currentUserId)
        .map((p) => p.payload)
        .firstOrNull;

    if (existing == null) return;
    await channel.track({...existing, 'is_editing': isEditing});
  }

  @override
  Future<void> leavePresence(String workOrderId) async {
    final channel = _channels.remove(workOrderId);
    if (channel != null) {
      try {
        await channel.untrack();
        await _client.removeChannel(channel);
      } catch (_) {
        // Best-effort teardown
      }
    }
    _orderControllers.remove(workOrderId)?.close();
    _notesControllers.remove(workOrderId)?.close();
    _presenceControllers.remove(workOrderId)?.close();
  }

  @override
  Stream<List<PresenceUser>> watchPresence(String workOrderId) {
    _channelFor(workOrderId);
    return _presenceControllers[workOrderId]!.stream;
  }

  @override
  void dispose() {
    for (final id in List.of(_channels.keys)) {
      leavePresence(id);
    }
    final lc = _listChannel;
    if (lc != null) {
      try {
        _client.removeChannel(lc);
      } catch (_) {}
    }
    _listController?.close();
  }

  // ── Normalisers — mirrors SupabaseRemoteClient.pullChanges key mapping ──────

  Map<String, dynamic> _normaliseWorkOrder(Map<String, dynamic> r) => {
        'entityType': 'work_order',
        'id': r['id'],
        'title': r['title'],
        'description': r['description'] ?? '',
        'status': r['status'],
        'assignedTo': r['assigned_to'],
        'createdBy': r['created_by'],
        'createdAt': r['created_at'],
        'updatedAt': r['updated_at'],
        'completedAt': r['completed_at'],
        'locationLabel': r['location_label'],
        'remoteId': r['id'],
        'isDirty': false,
        'localVersion': 1,
        'serverVersion': r['server_version'],
      };

  Map<String, dynamic> _normaliseNote(Map<String, dynamic> r) => {
        'id': r['id'],
        'workOrderId': r['work_order_id'],
        'body': r['body'],
        'createdBy': r['created_by'],
        'createdAt': r['created_at'],
      };
}

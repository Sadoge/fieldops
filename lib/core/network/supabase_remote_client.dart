import 'dart:io';

import 'package:fieldops/core/network/remote_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Production remote client backed by Supabase.
/// Wire it up by overriding [remoteClientProvider]:
///   remoteClientProvider.overrideWithValue(SupabaseRemoteClient())
class SupabaseRemoteClient implements RemoteClient {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> pushWorkOrder(
      Map<String, dynamic> payload) async {
    final serverVersion = (payload['serverVersion'] as int? ?? 0) + 1;
    final upsertPayload = {
      'id': payload['id'],
      'title': payload['title'],
      'description': payload['description'],
      'status': payload['status'],
      'assigned_to': payload['assignedTo'],
      'created_by': payload['createdBy'],
      'created_at': payload['createdAt'],
      'updated_at': payload['updatedAt'],
      'completed_at': payload['completedAt'],
      'location_label': payload['locationLabel'],
      'server_version': serverVersion,
    };

    final result = await _db
        .from('work_orders')
        .upsert(upsertPayload)
        .select('id, server_version')
        .single();

    return {
      ...payload,
      'remoteId': result['id'] as String,
      'serverVersion': result['server_version'] as int,
      'isDirty': false,
    };
  }

  @override
  Future<String> uploadPhoto({
    required String localPath,
    required Map<String, dynamic> metadata,
  }) async {
    final file = File(localPath);
    final fileName =
        '${metadata['workOrderId']}/${metadata['id']}.jpg';

    await _db.storage.from('photos').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _db.storage.from('photos').getPublicUrl(fileName);
  }

  @override
  Future<void> pushNote(Map<String, dynamic> payload) async {
    await _db.from('notes').upsert({
      'id': payload['id'],
      'work_order_id': payload['workOrderId'],
      'body': payload['body'],
      'created_by': payload['createdBy'],
      'created_at': payload['createdAt'],
    });
  }

  @override
  Future<void> deleteEntity({
    required String entityType,
    required String entityId,
  }) async {
    final table = switch (entityType) {
      'work_order' => 'work_orders',
      'photo' => 'photos',
      'note' => 'notes',
      _ => throw ArgumentError('Unknown entity type: $entityType'),
    };
    await _db.from(table).delete().eq('id', entityId);
  }

  @override
  Future<List<Map<String, dynamic>>> pullChanges(DateTime since) async {
    final rows = await _db
        .from('work_orders')
        .select()
        .gt('updated_at', since.toIso8601String());

    return (rows as List).map((row) {
      final r = row as Map<String, dynamic>;
      return {
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
    }).toList();
  }
}

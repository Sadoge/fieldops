import 'dart:io';

import 'package:fieldops/core/network/remote_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Returns [value] if it looks like a UUID, otherwise null.
String? _uuidOrNull(dynamic value) {
  if (value is String && _uuidPattern.hasMatch(value)) return value;
  return null;
}

/// Production remote client backed by Supabase.
/// Wire it up by overriding [remoteClientProvider]:
///   remoteClientProvider.overrideWithValue(SupabaseRemoteClient())
class SupabaseRemoteClient implements RemoteClient {
  SupabaseClient get _db => Supabase.instance.client;
  bool _supportsPriority = true;
  bool _supportsDueAt = true;

  @override
  Future<Map<String, dynamic>> pushWorkOrder(Map<String, dynamic> payload) async {
    final serverVersion = (payload['serverVersion'] as int? ?? 0) + 1;
    Map<String, dynamic> upsertPayload = _workOrderUpsertPayload(
      payload,
      serverVersion: serverVersion,
    );
    late final Map<String, dynamic> result;
    try {
      result = await _upsertWorkOrder(upsertPayload);
    } on PostgrestException catch (e) {
      final unsupportedColumns = _unsupportedWorkOrderColumns(e);
      if (unsupportedColumns.isEmpty) rethrow;

      if (unsupportedColumns.contains('priority')) {
        _supportsPriority = false;
      }
      if (unsupportedColumns.contains('due_at')) {
        _supportsDueAt = false;
      }

      upsertPayload = _workOrderUpsertPayload(
        payload,
        serverVersion: serverVersion,
      );
      result = await _upsertWorkOrder(upsertPayload);
    }

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
    final fileName = '${metadata['workOrderId']}/${metadata['id']}.jpg';

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
      'created_by': _uuidOrNull(payload['createdBy']),
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
        'priority': r['priority'],
        'assignedTo': r['assigned_to'],
        'createdBy': r['created_by'],
        'createdAt': r['created_at'],
        'updatedAt': r['updated_at'],
        'dueAt': r['due_at'],
        'completedAt': r['completed_at'],
        'locationLabel': r['location_label'],
        'remoteId': r['id'],
        'isDirty': false,
        'localVersion': 1,
        'serverVersion': r['server_version'],
      };
    }).toList();
  }

  Map<String, dynamic> _workOrderUpsertPayload(
    Map<String, dynamic> payload, {
    required int serverVersion,
  }) {
    final upsertPayload = <String, dynamic>{
      'id': payload['id'],
      'title': payload['title'],
      'description': payload['description'],
      'status': payload['status'],
      'assigned_to': _uuidOrNull(payload['assignedTo']),
      'created_by': _uuidOrNull(payload['createdBy']),
      'created_at': payload['createdAt'],
      'updated_at': payload['updatedAt'],
      'completed_at': payload['completedAt'],
      'location_label': payload['locationLabel'],
      'server_version': serverVersion,
    };
    if (_supportsPriority) {
      upsertPayload['priority'] = payload['priority'];
    }
    if (_supportsDueAt) {
      upsertPayload['due_at'] = payload['dueAt'];
    }
    return upsertPayload;
  }

  Future<Map<String, dynamic>> _upsertWorkOrder(
    Map<String, dynamic> upsertPayload,
  ) async {
    return await _db
        .from('work_orders')
        .upsert(upsertPayload)
        .select('id, server_version')
        .single();
  }

  Set<String> _unsupportedWorkOrderColumns(PostgrestException error) {
    if (error.code != 'PGRST204') return const {};

    final columns = <String>{};
    if (_referencesMissingColumn(error.message, 'priority')) {
      columns.add('priority');
    }
    if (_referencesMissingColumn(error.message, 'due_at')) {
      columns.add('due_at');
    }
    return columns;
  }

  bool _referencesMissingColumn(String? message, String columnName) {
    if (message == null) return false;
    return message.contains("'$columnName'") || message.contains('"$columnName"');
  }
}

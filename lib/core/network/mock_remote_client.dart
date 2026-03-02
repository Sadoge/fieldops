import 'dart:math';

import 'package:fieldops/core/network/remote_client.dart';
import 'package:fieldops/core/utils/id_generator.dart';

class RemoteException implements Exception {
  const RemoteException(this.message, {this.statusCode = 500});
  final String message;
  final int statusCode;

  @override
  String toString() => 'RemoteException($statusCode): $message';
}

/// Simulated server. Replace with [SupabaseRemoteClient] for production.
class MockRemoteClient implements RemoteClient {
  MockRemoteClient({this.latencyMs = 600, this.failureRate = 0.0});

  final int latencyMs;

  /// 0.0 = never fail, 1.0 = always fail. Set to 0.3 to stress-test retries.
  final double failureRate;

  @override
  Future<Map<String, dynamic>> pushWorkOrder(
      Map<String, dynamic> payload) async {
    await _delay();
    _maybeThrow();
    return {
      ...payload,
      'remoteId': 'srv_${IdGenerator.newId()}',
      'serverVersion': (payload['serverVersion'] as int? ?? 0) + 1,
      'isDirty': false,
    };
  }

  @override
  Future<String> uploadPhoto(
      {required String localPath,
      required Map<String, dynamic> metadata}) async {
    await _delay();
    _maybeThrow();
    return 'https://mock.fieldops.local/photos/${IdGenerator.newId()}.jpg';
  }

  @override
  Future<void> pushNote(Map<String, dynamic> payload) async {
    await _delay();
    _maybeThrow();
  }

  @override
  Future<void> deleteEntity(
      {required String entityType, required String entityId}) async {
    await _delay();
    _maybeThrow();
  }

  @override
  Future<List<Map<String, dynamic>>> pullChanges(DateTime since) async {
    await _delay();
    return [];
  }

  Future<void> _delay() =>
      Future.delayed(Duration(milliseconds: latencyMs));

  void _maybeThrow() {
    if (failureRate > 0 && Random().nextDouble() < failureRate) {
      throw const RemoteException('Simulated server error', statusCode: 503);
    }
  }
}

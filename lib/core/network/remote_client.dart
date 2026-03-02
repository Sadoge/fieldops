abstract class RemoteClient {
  Future<Map<String, dynamic>> pushWorkOrder(Map<String, dynamic> payload);
  Future<String> uploadPhoto({
    required String localPath,
    required Map<String, dynamic> metadata,
  });
  Future<void> pushNote(Map<String, dynamic> payload);
  Future<void> deleteEntity({
    required String entityType,
    required String entityId,
  });
  Future<List<Map<String, dynamic>>> pullChanges(DateTime since);
}

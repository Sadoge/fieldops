import 'package:fieldops/features/photos/domain/entities/photo.dart';

abstract class PhotoRepository {
  Stream<List<Photo>> watchByWorkOrder(String workOrderId);
  Future<Photo?> findById(String id);
  Future<void> save(Photo photo);
  Future<void> delete(String id);
  Future<List<Photo>> findUnsynced();
}

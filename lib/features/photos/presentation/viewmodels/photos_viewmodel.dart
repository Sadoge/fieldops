import 'dart:io';

import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/utils/id_generator.dart';
import 'package:fieldops/features/photos/domain/entities/photo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final photosProvider =
    StreamProvider.family<List<Photo>, String>((ref, workOrderId) {
  return ref.watch(photoRepositoryProvider).watchByWorkOrder(workOrderId);
});

class PhotosViewModel extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> capturePhoto({
    required String workOrderId,
    required ImageSource source,
  }) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final filename = '${IdGenerator.newId()}.jpg';
    final destPath = p.join(docsDir.path, 'photos', filename);
    await Directory(p.dirname(destPath)).create(recursive: true);
    await File(picked.path).copy(destPath);

    final sizeBytes = await File(destPath).length();
    final photo = Photo(
      id: IdGenerator.newId(),
      workOrderId: workOrderId,
      localPath: destPath,
      capturedAt: DateTime.now().toUtc(),
      capturedBy: user?.id ?? 'unknown',
      fileSizeBytes: sizeBytes,
    );
    await ref.read(photoRepositoryProvider).save(photo);
    ref.read(syncEngineProvider).sync();
  }
}

final photosViewModelProvider =
    AsyncNotifierProvider.autoDispose<PhotosViewModel, void>(
        PhotosViewModel.new);

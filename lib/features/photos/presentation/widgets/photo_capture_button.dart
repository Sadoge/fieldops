import 'package:fieldops/features/photos/presentation/viewmodels/photos_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class PhotoCaptureButton extends ConsumerWidget {
  const PhotoCaptureButton({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.add_a_photo_outlined),
      tooltip: 'Add photo',
      onPressed: () => _showSourcePicker(context, ref),
    );
  }

  void _showSourcePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _capture(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _capture(context, ref, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capture(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      await ref.read(photosViewModelProvider.notifier).capturePhoto(
            workOrderId: workOrderId,
            source: source,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add photo: $e')));
      }
    }
  }
}

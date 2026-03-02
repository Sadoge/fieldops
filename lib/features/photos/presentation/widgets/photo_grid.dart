import 'dart:io';

import 'package:fieldops/features/photos/presentation/viewmodels/photos_viewmodel.dart';
import 'package:fieldops/shared/widgets/empty_state_view.dart';
import 'package:fieldops/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PhotoGrid extends ConsumerWidget {
  const PhotoGrid({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(workOrderId));

    return photosAsync.when(
      data: (photos) {
        if (photos.isEmpty) {
          return const EmptyStateView(
            message: 'No photos yet',
            icon: Icons.photo_library_outlined,
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: photos.length,
          itemBuilder: (_, i) {
            final photo = photos[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(photo.localPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Colors.grey,
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white),
                    ),
                  ),
                ),
                if (!photo.isSynced)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.cloud_upload_outlined,
                          size: 12, color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

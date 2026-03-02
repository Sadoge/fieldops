import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/notes/presentation/viewmodels/notes_viewmodel.dart';
import 'package:fieldops/shared/widgets/empty_state_view.dart';
import 'package:fieldops/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesList extends ConsumerWidget {
  const NotesList({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider(workOrderId));

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return const EmptyStateView(
            message: 'No notes yet',
            icon: Icons.notes_outlined,
          );
        }
        return Column(
          children: notes
              .map((n) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.body),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(n.createdBy,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              const Spacer(),
                              if (!n.isSynced)
                                const Icon(Icons.cloud_upload_outlined,
                                    size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(DateFormatter.timeAgo(n.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

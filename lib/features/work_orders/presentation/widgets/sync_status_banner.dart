import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/sync/sync_status_notifier.dart';
import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final pendingAsync = ref.watch(pendingChangesCountProvider);
    final pendingCount = pendingAsync.valueOrNull ?? 0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: switch (syncState) {
        SyncStateSyncing() => _Banner(
            icon: Icons.sync,
            text: 'Syncing…',
            color: Colors.blue,
          ),
        SyncStateError(:final message) => _Banner(
            icon: Icons.sync_problem,
            text: 'Sync failed: $message',
            color: Colors.orange,
          ),
        SyncStateIdle(:final lastSyncedAt) => pendingCount > 0
            ? _Banner(
                icon: Icons.cloud_upload_outlined,
                text:
                    '$pendingCount pending change${pendingCount == 1 ? '' : 's'}',
                color: Colors.amber.shade700,
              )
            : lastSyncedAt != null
                ? _Banner(
                    icon: Icons.check_circle_outline,
                    text:
                        'Last synced ${DateFormatter.timeAgo(lastSyncedAt)}',
                    color: Colors.green,
                  )
                : const SizedBox.shrink(),
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withAlpha(38),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: color),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

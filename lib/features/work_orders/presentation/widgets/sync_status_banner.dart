import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/sync/sync_status_notifier.dart';
import 'package:fieldops/core/theme/app_theme.dart';
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
        SyncStateSyncing() => const _Banner(
            icon: Icons.sync,
            text: 'Syncing…',
            color: AppColors.statusNew,
            showProgress: true,
          ),
        SyncStateError(:final message) => _Banner(
            icon: Icons.sync_problem,
            text: 'Sync failed: $message',
            color: Colors.deepOrange.shade700,
          ),
        SyncStateIdle(:final lastSyncedAt) => pendingCount > 0
            ? _Banner(
                icon: Icons.cloud_upload_outlined,
                text:
                    '$pendingCount pending change${pendingCount == 1 ? '' : 's'}',
                color: AppColors.orange,
              )
            : lastSyncedAt != null
                ? _Banner(
                    icon: Icons.check_circle_outline,
                    text: 'Last synced ${DateFormatter.timeAgo(lastSyncedAt)}',
                    color: AppColors.statusCompleted,
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
    this.showProgress = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showProgress)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: color.withAlpha(40),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withAlpha(24),
            border: Border(
              bottom: BorderSide(color: color.withAlpha(60), width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

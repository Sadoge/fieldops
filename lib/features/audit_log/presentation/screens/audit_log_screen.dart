import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/audit_log/domain/entities/audit_log_entry.dart';
import 'package:fieldops/features/audit_log/presentation/viewmodels/audit_log_viewmodel.dart';
import 'package:fieldops/shared/widgets/empty_state_view.dart';
import 'package:fieldops/shared/widgets/error_view.dart';
import 'package:fieldops/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(auditLogProvider(workOrderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: entriesAsync.when(
        data: (entries) => entries.isEmpty
            ? const EmptyStateView(
                message: 'No audit entries yet',
                icon: Icons.history_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _AuditTile(entry: entries[i]),
              ),
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(error: e),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: _actionColor(entry.action).withAlpha(40),
        child: Icon(_actionIcon(entry.action),
            size: 16, color: _actionColor(entry.action)),
      ),
      title: Text(_actionLabel(entry.action),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('by ${entry.performedBy}',
              style: const TextStyle(fontSize: 12)),
          if (entry.note != null)
            Text(entry.note!,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: Text(
        DateFormatter.timeAgo(entry.performedAt),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      isThreeLine: entry.note != null,
    );
  }

  String _actionLabel(AuditAction a) => switch (a) {
        AuditAction.created => 'Created',
        AuditAction.statusChanged => 'Status changed',
        AuditAction.edited => 'Edited',
        AuditAction.photoAdded => 'Photo added',
        AuditAction.noteAdded => 'Note added',
        AuditAction.conflictResolved => 'Conflict resolved',
        AuditAction.synced => 'Synced',
      };

  IconData _actionIcon(AuditAction a) => switch (a) {
        AuditAction.created => Icons.add_circle_outline,
        AuditAction.statusChanged => Icons.swap_horiz,
        AuditAction.edited => Icons.edit_outlined,
        AuditAction.photoAdded => Icons.photo_outlined,
        AuditAction.noteAdded => Icons.note_outlined,
        AuditAction.conflictResolved => Icons.merge_outlined,
        AuditAction.synced => Icons.cloud_done_outlined,
      };

  Color _actionColor(AuditAction a) => switch (a) {
        AuditAction.created => Colors.green,
        AuditAction.statusChanged => Colors.blue,
        AuditAction.edited => Colors.orange,
        AuditAction.photoAdded => Colors.purple,
        AuditAction.noteAdded => Colors.teal,
        AuditAction.conflictResolved => Colors.red,
        AuditAction.synced => Colors.green,
      };
}

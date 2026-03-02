import 'package:fieldops/core/permissions/permission.dart';
import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/router/route_names.dart';
import 'package:fieldops/features/work_orders/presentation/viewmodels/work_order_list_viewmodel.dart';
import 'package:fieldops/features/work_orders/presentation/widgets/sync_status_banner.dart';
import 'package:fieldops/features/work_orders/presentation/widgets/work_order_card.dart';
import 'package:fieldops/features/work_orders/presentation/widgets/work_order_filter_bar.dart';
import 'package:fieldops/shared/widgets/empty_state_view.dart';
import 'package:fieldops/shared/widgets/error_view.dart';
import 'package:fieldops/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkOrderListScreen extends ConsumerWidget {
  const WorkOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(workOrderListProvider);
    final permService = ref.watch(permissionServiceOrNullProvider);
    final canCreate = permService?.can(Permission.createWorkOrder) ?? false;
    final canExport = permService?.can(Permission.exportData) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        actions: [
          if (canExport)
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Export',
              onPressed: () => _showExportSheet(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: () => ref.read(syncEngineProvider).sync(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Audit log',
            onPressed: () => context.push(RouteNames.auditLog),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          const WorkOrderFilterBar(),
          Expanded(
            child: ordersAsync.when(
              data: (orders) => orders.isEmpty
                  ? EmptyStateView(
                      message: 'No work orders yet.',
                      icon: Icons.assignment_outlined,
                      action: canCreate
                          ? FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('New Work Order'),
                              onPressed: () => context.push(RouteNames.workOrderNew),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(syncEngineProvider).sync(),
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (_, i) => WorkOrderCard(
                          order: orders[i],
                          onTap: () => context.push(
                              RouteNames.workOrderDetailPath(orders[i].id)),
                        ),
                      ),
                    ),
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(error: e),
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.workOrderNew),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showExportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportCsv(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPdf(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final orders =
          await ref.read(workOrderListProvider.future);
      final file = await ref.read(csvExporterProvider).export(orders);
      await ref.read(shareServiceProvider).shareFile(file.path, subject: 'Work Orders Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final orders =
          await ref.read(workOrderListProvider.future);
      final file = await ref.read(pdfExporterProvider).export(orders);
      await ref.read(shareServiceProvider).shareFile(file.path, subject: 'Work Orders Report');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}

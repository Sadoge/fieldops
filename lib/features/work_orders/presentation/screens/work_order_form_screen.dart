import 'package:fieldops/features/work_orders/presentation/viewmodels/work_order_detail_viewmodel.dart';
import 'package:fieldops/features/work_orders/presentation/viewmodels/work_order_form_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkOrderFormScreen extends ConsumerStatefulWidget {
  const WorkOrderFormScreen({super.key, this.existingId});

  final String? existingId;

  @override
  ConsumerState<WorkOrderFormScreen> createState() =>
      _WorkOrderFormScreenState();
}

class _WorkOrderFormScreenState
    extends ConsumerState<WorkOrderFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _assignedCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _assignedCtrl.dispose();
    super.dispose();
  }

  void _initFromExisting(WidgetRef ref) {
    if (_initialized || widget.existingId == null) return;
    final orderAsync = ref.read(workOrderDetailProvider(widget.existingId!));
    orderAsync.whenData((order) {
      if (order == null) return;
      ref.read(workOrderFormViewModelProvider.notifier).init(order);
      _titleCtrl.text = order.title;
      _descCtrl.text = order.description;
      _locationCtrl.text = order.locationLabel ?? '';
      _assignedCtrl.text = order.assignedTo;
      _initialized = true;
    });
  }

  Future<void> _submit() async {
    final success =
        await ref.read(workOrderFormViewModelProvider.notifier).submit();
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    _initFromExisting(ref);
    final formState = ref.watch(workOrderFormViewModelProvider);
    final vm = ref.read(workOrderFormViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingId == null
            ? 'New Work Order'
            : 'Edit Work Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *'),
              onChanged: vm.setTitle,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              onChanged: vm.setDescription,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration:
                  const InputDecoration(labelText: 'Location (optional)'),
              onChanged: vm.setLocation,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assignedCtrl,
              decoration:
                  const InputDecoration(labelText: 'Assigned to (user ID)'),
              onChanged: vm.setAssignedTo,
            ),
            if (formState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                formState.errorMessage!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: formState.isSubmitting ? null : _submit,
              child: formState.isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.existingId == null
                      ? 'Create Work Order'
                      : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

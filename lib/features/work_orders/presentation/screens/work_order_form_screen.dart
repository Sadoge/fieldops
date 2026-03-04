import 'package:collection/collection.dart';
import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/utils/date_formatter.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_priority.dart';
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

class _WorkOrderFormScreenState extends ConsumerState<WorkOrderFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
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
      _initialized = true;
    });
  }

  Future<void> _submit() async {
    final success =
        await ref.read(workOrderFormViewModelProvider.notifier).submit();
    if (success && mounted) context.pop();
  }

  Future<void> _pickDueAt() async {
    final vm = ref.read(workOrderFormViewModelProvider.notifier);
    final state = ref.read(workOrderFormViewModelProvider);
    final initial = (state.dueAt ?? DateTime.now()).toLocal();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;

    final localDueAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    vm.setDueAt(localDueAt.toUtc());
  }

  @override
  Widget build(BuildContext context) {
    _initFromExisting(ref);
    final formState = ref.watch(workOrderFormViewModelProvider);
    final vm = ref.read(workOrderFormViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existingId == null ? 'New Work Order' : 'Edit Work Order'),
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
            DropdownButtonFormField<WorkOrderPriority>(
              decoration: const InputDecoration(labelText: 'Priority'),
              initialValue: formState.priority,
              items: WorkOrderPriority.values
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(_priorityLabel(priority)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) vm.setPriority(value);
              },
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Due date'),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formState.dueAt == null
                          ? 'No due date set'
                          : DateFormatter.formatDateTime(formState.dueAt!),
                      style: TextStyle(
                        color: formState.dueAt == null
                            ? Theme.of(context).hintColor
                            : null,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDueAt,
                    child: Text(
                      formState.dueAt == null ? 'Set' : 'Change',
                    ),
                  ),
                  if (formState.dueAt != null)
                    IconButton(
                      tooltip: 'Clear due date',
                      onPressed: () => vm.setDueAt(null),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ref.watch(assignableUsersProvider).when(
                  data: (users) {
                    final selected = users.firstWhereOrNull(
                      (u) => u.id == formState.assignedTo,
                    );
                    return DropdownButtonFormField(
                      decoration: const InputDecoration(labelText: 'Assign to'),
                      initialValue: selected,
                      items: users
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child:
                                    Text('${u.displayName} (${u.role.name})'),
                              ))
                          .toList(),
                      onChanged: (u) => vm.setAssignedTo(u?.id ?? ''),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Could not load users'),
                ),
            if (formState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                formState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: formState.isSubmitting ? null : _submit,
              child: formState.isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.existingId == null
                      ? 'Create Work Order'
                      : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(WorkOrderPriority priority) => switch (priority) {
        WorkOrderPriority.low => 'Low',
        WorkOrderPriority.medium => 'Medium',
        WorkOrderPriority.high => 'High',
        WorkOrderPriority.urgent => 'Urgent',
      };
}

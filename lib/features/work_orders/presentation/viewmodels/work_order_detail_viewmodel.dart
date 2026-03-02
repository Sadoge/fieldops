import 'package:fieldops/core/providers.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workOrderDetailProvider =
    StreamProvider.family<WorkOrder?, String>((ref, id) {
  return ref
      .watch(workOrderRepositoryProvider)
      .watchAll()
      .map((list) => list.firstWhere((o) => o.id == id,
          orElse: () => throw StateError('Work order $id not found')));
});

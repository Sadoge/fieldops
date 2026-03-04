import 'package:fieldops/core/database/tables/audit_log_table.dart';
import 'package:fieldops/core/sync/conflict_resolver.dart';
import 'package:fieldops/features/audit_log/domain/repositories/audit_log_repository.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:fieldops/features/work_orders/domain/entities/work_order_status.dart';
import 'package:fieldops/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkOrderRepository extends Mock implements WorkOrderRepository {}

class MockAuditLogRepository extends Mock implements AuditLogRepository {}

class FakeWorkOrder extends Fake implements WorkOrder {}

WorkOrder _baseOrder({
  String id = 'order-1',
  bool isDirty = false,
  int localVersion = 1,
  int? serverVersion = 1,
  WorkOrderStatus status = WorkOrderStatus.newOrder,
}) =>
    WorkOrder(
      id: id,
      title: 'Test Order',
      description: 'desc',
      status: status,
      priority: WorkOrderPriority.medium,
      assignedTo: 'user-1',
      createdBy: 'user-1',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      isDirty: isDirty,
      localVersion: localVersion,
      serverVersion: serverVersion,
    );

Map<String, dynamic> _remotePayload(WorkOrder order) => {
      'entityType': 'work_order',
      'id': order.id,
      'title': order.title,
      'description': order.description,
      'status': order.status.name,
      'priority': order.priority.name,
      'assignedTo': order.assignedTo,
      'createdBy': order.createdBy,
      'createdAt': order.createdAt.toIso8601String(),
      'updatedAt': order.updatedAt.toIso8601String(),
      'dueAt': null,
      'completedAt': null,
      'locationLabel': null,
      'remoteId': null,
      'isDirty': false,
      'localVersion': order.localVersion,
      'serverVersion': order.serverVersion,
    };

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWorkOrder());
    registerFallbackValue(AuditAction.created);
  });

  late MockWorkOrderRepository workOrderRepo;
  late MockAuditLogRepository auditLogRepo;
  late ConflictResolver resolver;

  setUp(() {
    workOrderRepo = MockWorkOrderRepository();
    auditLogRepo = MockAuditLogRepository();
    resolver = ConflictResolver(
      workOrderRepo: workOrderRepo,
      auditLogRepo: auditLogRepo,
    );

    // Default stubs
    when(() => workOrderRepo.save(any())).thenAnswer((_) async {});
    when(() => workOrderRepo.updateLocalOnly(any())).thenAnswer((_) async {});
    when(() => auditLogRepo.record(
          workOrderId: any(named: 'workOrderId'),
          action: any(named: 'action'),
          performedBy: any(named: 'performedBy'),
          oldValue: any(named: 'oldValue'),
          newValue: any(named: 'newValue'),
          note: any(named: 'note'),
        )).thenAnswer((_) async {});
  });

  group('resolveIncoming — ignores non work_order entities', () {
    test('skips if entityType is missing', () async {
      await resolver.resolveIncoming({'id': 'x'});
      verifyNever(() => workOrderRepo.findById(any()));
    });

    test('skips if entityType is photo', () async {
      await resolver.resolveIncoming({'entityType': 'photo', 'id': 'x'});
      verifyNever(() => workOrderRepo.findById(any()));
    });
  });

  group('resolveIncoming — no local copy', () {
    test('inserts remote order marked clean', () async {
      final remote = _baseOrder(isDirty: false, serverVersion: 2);
      when(() => workOrderRepo.findById('order-1'))
          .thenAnswer((_) async => null);

      await resolver.resolveIncoming(_remotePayload(remote));

      final captured = verify(
        () => workOrderRepo.updateLocalOnly(captureAny()),
      ).captured.single as WorkOrder;
      expect(captured.id, equals('order-1'));
      expect(captured.isDirty, isFalse);
    });
  });

  group('resolveIncoming — local not dirty', () {
    test('server always wins; no audit entry needed', () async {
      final local = _baseOrder(isDirty: false, serverVersion: 1);
      final remote = _baseOrder(isDirty: false, serverVersion: 2);
      when(() => workOrderRepo.findById('order-1'))
          .thenAnswer((_) async => local);

      await resolver.resolveIncoming(_remotePayload(remote));

      verify(() => workOrderRepo.updateLocalOnly(any())).called(1);
      verifyNever(() => auditLogRepo.record(
            workOrderId: any(named: 'workOrderId'),
            action: any(named: 'action'),
            performedBy: any(named: 'performedBy'),
          ));
    });
  });

  group('resolveIncoming — local is dirty', () {
    test('local wins when server version equals local server version',
        () async {
      final local = _baseOrder(isDirty: true, serverVersion: 1);
      final remote = _baseOrder(isDirty: false, serverVersion: 1);
      when(() => workOrderRepo.findById('order-1'))
          .thenAnswer((_) async => local);

      await resolver.resolveIncoming(_remotePayload(remote));

      // Local wins — should NOT persist the remote order locally.
      verifyNever(() => workOrderRepo.updateLocalOnly(any()));
    });

    test('server wins when remote version is higher; audit entry written',
        () async {
      final local = _baseOrder(isDirty: true, serverVersion: 1);
      final remote = _baseOrder(isDirty: false, serverVersion: 3);
      when(() => workOrderRepo.findById('order-1'))
          .thenAnswer((_) async => local);

      await resolver.resolveIncoming(_remotePayload(remote));

      verify(() => workOrderRepo.updateLocalOnly(any())).called(1);
      verify(() => auditLogRepo.record(
            workOrderId: 'order-1',
            action: AuditAction.conflictResolved,
            performedBy: 'system',
            oldValue: any(named: 'oldValue'),
            newValue: any(named: 'newValue'),
            note: any(named: 'note'),
          )).called(1);
    });
  });
}

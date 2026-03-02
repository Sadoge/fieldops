import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:fieldops/core/permissions/permission.dart';
import 'package:fieldops/core/permissions/permission_service.dart';
import 'package:fieldops/core/permissions/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PermissionService serviceFor(Role role) =>
      PermissionService(AppUser.mock(role));

  group('admin', () {
    late PermissionService svc;
    setUp(() => svc = serviceFor(Role.admin));

    test('can do everything', () {
      for (final p in Permission.values) {
        expect(svc.can(p), isTrue, reason: 'admin should have $p');
      }
    });

    test('guard does not throw', () {
      expect(() => svc.guard(Permission.manageUsers), returnsNormally);
    });
  });

  group('supervisor', () {
    late PermissionService svc;
    setUp(() => svc = serviceFor(Role.supervisor));

    test('can create and export', () {
      expect(svc.can(Permission.createWorkOrder), isTrue);
      expect(svc.can(Permission.exportData), isTrue);
      expect(svc.can(Permission.viewAuditLog), isTrue);
    });

    test('cannot delete work orders or manage users', () {
      expect(svc.can(Permission.deleteWorkOrder), isFalse);
      expect(svc.can(Permission.manageUsers), isFalse);
    });
  });

  group('worker', () {
    late PermissionService svc;
    setUp(() => svc = serviceFor(Role.worker));

    test('can edit, change status and add photos/notes', () {
      expect(svc.can(Permission.editWorkOrder), isTrue);
      expect(svc.can(Permission.changeStatus), isTrue);
      expect(svc.can(Permission.addPhoto), isTrue);
      expect(svc.can(Permission.addNote), isTrue);
    });

    test('cannot create, export or view audit log', () {
      expect(svc.can(Permission.createWorkOrder), isFalse);
      expect(svc.can(Permission.exportData), isFalse);
      expect(svc.can(Permission.viewAuditLog), isFalse);
    });
  });

  group('viewer', () {
    late PermissionService svc;
    setUp(() => svc = serviceFor(Role.viewer));

    test('can only view work orders', () {
      expect(svc.can(Permission.viewWorkOrders), isTrue);
      for (final p in Permission.values.where((p) => p != Permission.viewWorkOrders)) {
        expect(svc.can(p), isFalse, reason: 'viewer should NOT have $p');
      }
    });

    test('guard throws PermissionDeniedException for forbidden actions', () {
      expect(
        () => svc.guard(Permission.createWorkOrder),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('PermissionDeniedException message contains permission name', () {
      try {
        svc.guard(Permission.deleteWorkOrder);
        fail('Expected exception');
      } on PermissionDeniedException catch (e) {
        expect(e.toString(), contains('deleteWorkOrder'));
      }
    });
  });
}

import 'permission.dart';
import 'role.dart';

const Map<Role, Set<Permission>> kPermissionMatrix = {
  Role.admin: {
    Permission.viewWorkOrders,
    Permission.createWorkOrder,
    Permission.editWorkOrder,
    Permission.deleteWorkOrder,
    Permission.changeStatus,
    Permission.addPhoto,
    Permission.deletePhoto,
    Permission.addNote,
    Permission.exportData,
    Permission.viewAuditLog,
    Permission.manageUsers,
  },
  Role.supervisor: {
    Permission.viewWorkOrders,
    Permission.createWorkOrder,
    Permission.editWorkOrder,
    Permission.changeStatus,
    Permission.addPhoto,
    Permission.addNote,
    Permission.exportData,
    Permission.viewAuditLog,
  },
  Role.worker: {
    Permission.viewWorkOrders,
    Permission.editWorkOrder,
    Permission.changeStatus,
    Permission.addPhoto,
    Permission.addNote,
  },
  Role.viewer: {
    Permission.viewWorkOrders,
  },
};

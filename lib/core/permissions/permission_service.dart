import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'permission.dart';
import 'permission_matrix.dart';

class PermissionDeniedException implements Exception {
  const PermissionDeniedException(this.permission);
  final Permission permission;

  @override
  String toString() => 'Permission denied: ${permission.name}';
}

class PermissionService {
  const PermissionService(this._user);

  final AppUser _user;

  bool can(Permission permission) =>
      kPermissionMatrix[_user.role]?.contains(permission) ?? false;

  void guard(Permission permission) {
    if (!can(permission)) throw PermissionDeniedException(permission);
  }
}

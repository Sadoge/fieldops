import 'dart:async';
import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:fieldops/core/auth/domain/repositories/auth_repository.dart';
import 'package:fieldops/core/permissions/role.dart';
import 'auth_local_datasource.dart';

/// Mock auth: any email containing "admin", "supervisor", "worker" sets that role.
/// Default role is viewer.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._local);

  final AuthLocalDatasource _local;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> currentUser() => _local.getUser();

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield await _local.getUser();
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final role = _roleFromEmail(email);
    final user = AppUser(
      id: 'user_${email.hashCode.abs()}',
      displayName: email.split('@').first,
      email: email,
      role: role,
    );
    await _local.saveUser(user);
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _local.clearUser();
    _controller.add(null);
  }

  @override
  Future<List<AppUser>> listUsers() async => [
        AppUser.mock(Role.admin),
        AppUser.mock(Role.supervisor),
        AppUser.mock(Role.worker),
        AppUser.mock(Role.viewer),
      ];

  Role _roleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin')) return Role.admin;
    if (lower.contains('supervisor')) return Role.supervisor;
    if (lower.contains('worker')) return Role.worker;
    return Role.viewer;
  }
}

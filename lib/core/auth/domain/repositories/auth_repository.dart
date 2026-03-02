import 'package:fieldops/core/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<AppUser?> currentUser();
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AppUser?> watchCurrentUser();
  Future<List<AppUser>> listUsers();
}

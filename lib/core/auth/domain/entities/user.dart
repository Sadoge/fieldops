import 'package:fieldops/core/permissions/role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
  });

  final String id;
  final String displayName;
  final String email;
  final Role role;

  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    Role? role,
  }) =>
      AppUser(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        role: role ?? this.role,
      );

  static AppUser mock(Role role) => AppUser(
        id: 'user_${role.name}',
        displayName: role.name[0].toUpperCase() + role.name.substring(1),
        email: '${role.name}@fieldops.local',
        role: role,
      );
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:fieldops/core/permissions/role.dart';

const _kUserKey = 'current_user';

class AuthLocalDatasource {
  Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserKey);
    if (raw == null) return null;
    return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(_toJson(user)));
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }

  static AppUser _fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        displayName: j['displayName'] as String,
        email: j['email'] as String,
        role: Role.values.byName(j['role'] as String),
      );

  static Map<String, dynamic> _toJson(AppUser u) => {
        'id': u.id,
        'displayName': u.displayName,
        'email': u.email,
        'role': u.role.name,
      };
}

import 'dart:async';

import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:fieldops/core/auth/domain/repositories/auth_repository.dart';
import 'package:fieldops/core/permissions/role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Production auth backed by Supabase Auth.
/// The user's role is read from their JWT app_metadata:
///   { "role": "admin" | "supervisor" | "worker" | "viewer" }
/// Set this in the Supabase dashboard: Authentication → Users → Edit user
/// or via a Postgres trigger / Edge Function on signup.
class SupabaseAuthRepositoryImpl implements AuthRepository {
  SupabaseClient get _auth => Supabase.instance.client;

  @override
  Future<AppUser?> currentUser() async {
    final session = _auth.auth.currentSession;
    if (session == null) return null;
    return _fromSession(session);
  }

  @override
  Stream<AppUser?> watchCurrentUser() =>
      _auth.auth.onAuthStateChange.map((event) {
        final session = event.session;
        if (session == null) return null;
        return _fromSession(session);
      });

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _auth.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final session = response.session;
    if (session == null) throw const AuthException('Sign-in failed');
    return _fromSession(session);
  }

  @override
  Future<void> signOut() => _auth.auth.signOut();

  /// Fetches all app users via the `list_app_users` Postgres RPC.
  /// Run this once in the Supabase SQL editor:
  ///
  /// ```sql
  /// create or replace function public.list_app_users()
  /// returns table(id uuid, display_name text, email text, role text)
  /// language sql security definer as $$
  ///   select id,
  ///          coalesce(raw_user_meta_data->>'display_name', split_part(email,'@',1)) as display_name,
  ///          email,
  ///          coalesce(raw_app_meta_data->>'role', 'viewer') as role
  ///   from auth.users;
  /// $$;
  /// ```
  @override
  Future<List<AppUser>> listUsers() async {
    final rows =
        await _auth.rpc('list_app_users') as List<dynamic>;
    return rows.map((r) {
      final map = r as Map<String, dynamic>;
      final roleStr = map['role'] as String? ?? 'viewer';
      final role = Role.values.byName(roleStr);
      return AppUser(
        id: map['id'] as String,
        displayName: map['display_name'] as String,
        email: map['email'] as String,
        role: role,
      );
    }).toList();
  }

  AppUser _fromSession(Session session) {
    final user = session.user;
    final meta = user.appMetadata;
    final roleStr = meta['role'] as String? ?? 'viewer';
    final role = Role.values.byName(roleStr);
    return AppUser(
      id: user.id,
      displayName: user.email?.split('@').first ?? user.id,
      email: user.email ?? '',
      role: role,
    );
  }
}

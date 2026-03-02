import 'package:fieldops/core/auth/presentation/screens/login_screen.dart';
import 'package:fieldops/core/permissions/permission.dart';
import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/router/route_names.dart';
import 'package:fieldops/features/audit_log/presentation/screens/audit_log_screen.dart';
import 'package:fieldops/features/work_orders/presentation/screens/work_order_detail_screen.dart';
import 'package:fieldops/features/work_orders/presentation/screens/work_order_form_screen.dart';
import 'package:fieldops/features/work_orders/presentation/screens/work_order_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);

  // Rebuild the router when auth state changes.
  ref.listen(currentUserProvider, (_, next) {
    authNotifier.value = next.valueOrNull != null;
  });

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: RouteNames.workOrderList,
    redirect: (context, state) {
      final isLoggedIn = ref.read(currentUserProvider).valueOrNull != null;
      final isLoginRoute = state.uri.path == RouteNames.login;

      if (!isLoggedIn && !isLoginRoute) return RouteNames.login;
      if (isLoggedIn && isLoginRoute) return RouteNames.workOrderList;

      // Permission guard for audit log
      if (state.uri.path == RouteNames.auditLog) {
        final permService = ref.read(permissionServiceOrNullProvider);
        if (permService == null || !permService.can(Permission.viewAuditLog)) {
          return RouteNames.workOrderList;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.workOrderList,
        builder: (_, __) => const WorkOrderListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const WorkOrderFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => WorkOrderDetailScreen(
              id: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) => WorkOrderFormScreen(
                  existingId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'audit',
                builder: (_, state) => AuditLogScreen(
                  workOrderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.auditLog,
        builder: (_, __) => const AuditLogScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

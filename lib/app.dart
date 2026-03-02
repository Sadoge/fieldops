import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/router/app_router.dart';
import 'package:fieldops/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FieldOpsApp extends ConsumerWidget {
  const FieldOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Trigger sync on reconnect.
    ref.listen(isOnlineProvider, (prev, next) {
      next.whenData((isOnline) {
        if (isOnline && prev?.valueOrNull == false) {
          ref.read(syncEngineProvider).sync();
        }
      });
    });

    return MaterialApp.router(
      title: 'Field Ops',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

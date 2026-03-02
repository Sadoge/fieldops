import 'package:fieldops/app.dart';
import 'package:fieldops/core/config/supabase_config.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

const _syncTaskName = 'fieldopsSyncTask';
const _syncTaskId = 'fieldops.sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    try {
      await container.read(syncEngineProvider).sync();
      return true;
    } catch (_) {
      return false;
    } finally {
      await db.close();
      container.dispose();
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (useSupabase) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  await Workmanager().registerPeriodicTask(
    _syncTaskId,
    _syncTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const ProviderScope(child: FieldOpsApp()));
}

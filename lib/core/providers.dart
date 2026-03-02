import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fieldops/core/auth/data/auth_local_datasource.dart';
import 'package:fieldops/core/auth/data/auth_repository_impl.dart';
import 'package:fieldops/core/auth/data/supabase_auth_repository_impl.dart';
import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:fieldops/core/auth/domain/repositories/auth_repository.dart';
import 'package:fieldops/core/database/app_database.dart';
import 'package:fieldops/core/export/csv_exporter.dart';
import 'package:fieldops/core/export/pdf_exporter.dart';
import 'package:fieldops/core/export/share_service.dart';
import 'package:fieldops/core/network/connectivity_service.dart';
import 'package:fieldops/core/network/mock_remote_client.dart';
import 'package:fieldops/core/network/remote_client.dart';
import 'package:fieldops/core/network/supabase_remote_client.dart';
import 'package:fieldops/core/permissions/permission_service.dart';
import 'package:fieldops/core/sync/conflict_resolver.dart';
import 'package:fieldops/core/sync/sync_engine.dart';
import 'package:fieldops/core/sync/sync_status_notifier.dart';
import 'package:fieldops/features/audit_log/data/repositories/audit_log_repository_impl.dart';
import 'package:fieldops/features/audit_log/domain/repositories/audit_log_repository.dart';
import 'package:fieldops/features/notes/data/repositories/note_repository_impl.dart';
import 'package:fieldops/features/notes/domain/repositories/note_repository.dart';
import 'package:fieldops/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:fieldops/features/photos/domain/repositories/photo_repository.dart';
import 'package:fieldops/features/work_orders/data/repositories/work_order_repository_impl.dart';
import 'package:fieldops/features/work_orders/domain/repositories/work_order_repository.dart';

// ── Database ──────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Backend toggle ─────────────────────────────────────────────────────────────
// Set to true once SupabaseConfig contains real credentials and Supabase is
// initialised in main(). Flip this to false to fall back to the local mock.
const bool useSupabase = true;

// ── Auth ──────────────────────────────────────────────────────────────────────

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>(
  (_) => AuthLocalDatasource(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useSupabase) return SupabaseAuthRepositoryImpl();
  return AuthRepositoryImpl(ref.watch(authLocalDatasourceProvider));
});

final currentUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchCurrentUser(),
);

// ── Permissions ───────────────────────────────────────────────────────────────

final permissionServiceProvider = Provider<PermissionService>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) throw StateError('No authenticated user');
  return PermissionService(user);
});

// ── Repositories ──────────────────────────────────────────────────────────────

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuditLogRepositoryImpl(db.auditLogDao);
});

final workOrderRepositoryProvider = Provider<WorkOrderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WorkOrderRepositoryImpl(
    dao: db.workOrdersDao,
    syncQueueDao: db.syncQueueDao,
    auditLogRepo:
        ref.watch(auditLogRepositoryProvider) as AuditLogRepositoryImpl,
  );
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PhotoRepositoryImpl(dao: db.photosDao, syncQueueDao: db.syncQueueDao);
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NoteRepositoryImpl(dao: db.notesDao, syncQueueDao: db.syncQueueDao);
});

// ── Sync ──────────────────────────────────────────────────────────────────────

final remoteClientProvider = Provider<RemoteClient>(
  (_) => useSupabase ? SupabaseRemoteClient() : MockRemoteClient(),
);

final syncStatusNotifierProvider = Provider<SyncStatusNotifier>(
  (_) => SyncStatusNotifier(),
);

/// Riverpod-friendly wrapper that exposes [SyncState] as a [StateProvider].
final syncStateProvider = StateProvider<SyncState>(
  (_) => const SyncStateIdle(),
);

final conflictResolverProvider = Provider<ConflictResolver>(
  (ref) => ConflictResolver(
    workOrderRepo: ref.watch(workOrderRepositoryProvider),
    auditLogRepo: ref.watch(auditLogRepositoryProvider),
  ),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final notifier = ref.watch(syncStatusNotifierProvider);
  // Forward SyncStatusNotifier changes into syncStateProvider.
  notifier.addListener((state) {
    ref.read(syncStateProvider.notifier).state = state;
  });
  return SyncEngine(
    syncQueueDao: ref.watch(appDatabaseProvider).syncQueueDao,
    workOrderRepo: ref.watch(workOrderRepositoryProvider),
    photoRepo: ref.watch(photoRepositoryProvider),
    remoteClient: ref.watch(remoteClientProvider),
    conflictResolver: ref.watch(conflictResolverProvider),
    statusNotifier: notifier,
  );
});

final pendingChangesCountProvider = StreamProvider<int>(
  (ref) => ref.watch(appDatabaseProvider).syncQueueDao.watchPendingCount(),
);

// ── Connectivity ──────────────────────────────────────────────────────────────

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(),
);

final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onConnectivityChanged,
);

// ── Export ────────────────────────────────────────────────────────────────────

final csvExporterProvider = Provider<CsvExporter>((_) => CsvExporter());

final pdfExporterProvider = Provider<PdfExporter>((_) => PdfExporter());

final shareServiceProvider = Provider<ShareService>((_) => ShareService());

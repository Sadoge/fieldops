import 'dart:async';

import 'package:fieldops/core/auth/domain/entities/user.dart';
import 'package:fieldops/core/permissions/role.dart';
import 'package:fieldops/core/providers.dart';
import 'package:fieldops/core/realtime/presence_user.dart';
import 'package:fieldops/core/realtime/realtime_service.dart';
import 'package:fieldops/core/sync/conflict_resolver.dart';
import 'package:fieldops/features/notes/domain/repositories/note_repository.dart';
import 'package:fieldops/features/work_orders/presentation/viewmodels/realtime_work_order_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockRealtimeService extends Mock implements RealtimeService {}

class MockConflictResolver extends Mock implements ConflictResolver {}

class MockNoteRepository extends Mock implements NoteRepository {}

// ── Fakes (for mocktail registerFallbackValue) ────────────────────────────────

class FakePresenceUser extends Fake implements PresenceUser {}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _workOrderId = 'order-1';

ProviderContainer _makeContainer({
  required MockRealtimeService realtimeSvc,
  required MockConflictResolver conflictResolver,
  required MockNoteRepository noteRepo,
  AppUser? currentUser,
}) {
  return ProviderContainer(
    overrides: [
      realtimeServiceProvider.overrideWithValue(realtimeSvc),
      conflictResolverProvider.overrideWithValue(conflictResolver),
      noteRepositoryProvider.overrideWithValue(noteRepo),
      currentUserProvider.overrideWith(
        (ref) => Stream.value(currentUser ??
            AppUser(
              id: 'user-1',
              displayName: 'Alice',
              email: 'alice@example.com',
              role: Role.worker,
            )),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePresenceUser());
  });

  late MockRealtimeService realtimeSvc;
  late MockConflictResolver conflictResolver;
  late MockNoteRepository noteRepo;
  late StreamController<Map<String, dynamic>> orderStream;
  late StreamController<Map<String, dynamic>> notesStream;
  late StreamController<List<PresenceUser>> presenceStream;

  setUp(() {
    realtimeSvc = MockRealtimeService();
    conflictResolver = MockConflictResolver();
    noteRepo = MockNoteRepository();

    orderStream = StreamController<Map<String, dynamic>>.broadcast();
    notesStream = StreamController<Map<String, dynamic>>.broadcast();
    presenceStream = StreamController<List<PresenceUser>>.broadcast();

    when(() => realtimeSvc.watchWorkOrder(any()))
        .thenAnswer((_) => orderStream.stream);
    when(() => realtimeSvc.watchNotes(any()))
        .thenAnswer((_) => notesStream.stream);
    when(() => realtimeSvc.watchPresence(any()))
        .thenAnswer((_) => presenceStream.stream);
    when(() => realtimeSvc.joinPresence(
          workOrderId: any(named: 'workOrderId'),
          userId: any(named: 'userId'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async {});
    when(() => realtimeSvc.leavePresence(any())).thenAnswer((_) async {});
    when(() => realtimeSvc.broadcastEditing(
          workOrderId: any(named: 'workOrderId'),
          isEditing: any(named: 'isEditing'),
        )).thenAnswer((_) async {});

    when(() => conflictResolver.resolveIncoming(any()))
        .thenAnswer((_) async {});
    when(() => noteRepo.addFromRemote(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    orderStream.close();
    notesStream.close();
    presenceStream.close();
  });

  group('RealtimeWorkOrderNotifier', () {
    test('joins presence channel on build', () async {
      final container = _makeContainer(
        realtimeSvc: realtimeSvc,
        conflictResolver: conflictResolver,
        noteRepo: noteRepo,
      );
      addTearDown(container.dispose);

      // Read the future to trigger and await the async build.
      await container.read(realtimeWorkOrderProvider(_workOrderId).future);

      verify(() => realtimeSvc.joinPresence(
            workOrderId: _workOrderId,
            userId: 'user-1',
            displayName: 'Alice',
          )).called(1);
    });

    test('calls ConflictResolver when a work order event arrives', () async {
      final container = _makeContainer(
        realtimeSvc: realtimeSvc,
        conflictResolver: conflictResolver,
        noteRepo: noteRepo,
      );
      addTearDown(container.dispose);

      await container.read(realtimeWorkOrderProvider(_workOrderId).future);

      final payload = {'entityType': 'work_order', 'id': _workOrderId};
      orderStream.add(payload);
      await Future<void>.delayed(Duration.zero);

      verify(() => conflictResolver.resolveIncoming(payload)).called(1);
    });

    test('calls NoteRepository.addFromRemote when a note event arrives',
        () async {
      final container = _makeContainer(
        realtimeSvc: realtimeSvc,
        conflictResolver: conflictResolver,
        noteRepo: noteRepo,
      );
      addTearDown(container.dispose);

      await container.read(realtimeWorkOrderProvider(_workOrderId).future);

      final payload = {
        'id': 'note-1',
        'workOrderId': _workOrderId,
        'body': 'Hello',
        'createdBy': 'user-1',
        'createdAt': DateTime(2024).toIso8601String(),
      };
      notesStream.add(payload);
      await Future<void>.delayed(Duration.zero);

      verify(() => noteRepo.addFromRemote(payload)).called(1);
    });

    test('calls leavePresence on dispose', () async {
      final container = _makeContainer(
        realtimeSvc: realtimeSvc,
        conflictResolver: conflictResolver,
        noteRepo: noteRepo,
      );

      await container.read(realtimeWorkOrderProvider(_workOrderId).future);

      container.dispose();
      await Future<void>.delayed(Duration.zero);

      verify(() => realtimeSvc.leavePresence(_workOrderId)).called(1);
    });

    test('broadcastEditing delegates to RealtimeService', () async {
      final container = _makeContainer(
        realtimeSvc: realtimeSvc,
        conflictResolver: conflictResolver,
        noteRepo: noteRepo,
      );
      addTearDown(container.dispose);

      await container.read(realtimeWorkOrderProvider(_workOrderId).future);

      await container
          .read(realtimeWorkOrderProvider(_workOrderId).notifier)
          .broadcastEditing(true);

      verify(() => realtimeSvc.broadcastEditing(
            workOrderId: _workOrderId,
            isEditing: true,
          )).called(1);
    });
  });
}

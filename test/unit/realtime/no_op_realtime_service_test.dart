import 'package:fieldops/core/realtime/no_op_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NoOpRealtimeService svc;

  setUp(() => svc = NoOpRealtimeService());

  group('NoOpRealtimeService', () {
    test('watchWorkOrder emits nothing and completes without error', () async {
      final events = await svc.watchWorkOrder('id').toList();
      expect(events, isEmpty);
    });

    test('watchNotes emits nothing and completes without error', () async {
      final events = await svc.watchNotes('id').toList();
      expect(events, isEmpty);
    });

    test('watchPresence emits nothing and completes without error', () async {
      final events = await svc.watchPresence('id').toList();
      expect(events, isEmpty);
    });

    test('joinPresence completes without error', () async {
      await expectLater(
        svc.joinPresence(
            workOrderId: 'id', userId: 'u1', displayName: 'Alice'),
        completes,
      );
    });

    test('broadcastEditing completes without error', () async {
      await expectLater(
        svc.broadcastEditing(workOrderId: 'id', isEditing: true),
        completes,
      );
    });

    test('leavePresence completes without error', () async {
      await expectLater(svc.leavePresence('id'), completes);
    });

    test('dispose is a no-op', () {
      expect(() => svc.dispose(), returnsNormally);
    });
  });
}

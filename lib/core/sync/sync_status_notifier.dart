sealed class SyncState {
  const SyncState();
}

class SyncStateIdle extends SyncState {
  const SyncStateIdle({this.lastSyncedAt});
  final DateTime? lastSyncedAt;
}

class SyncStateSyncing extends SyncState {
  const SyncStateSyncing();
}

class SyncStateError extends SyncState {
  const SyncStateError(this.message);
  final String message;
}

/// Plain Dart class (no Riverpod here) — held as a field inside [SyncEngine]
/// and exposed to the UI via a Riverpod provider in providers.dart.
class SyncStatusNotifier {
  SyncState _state = const SyncStateIdle();
  final _listeners = <void Function(SyncState)>[];

  SyncState get state => _state;
  DateTime? get lastSyncedAt =>
      _state is SyncStateIdle ? (_state as SyncStateIdle).lastSyncedAt : null;

  void addListener(void Function(SyncState) listener) =>
      _listeners.add(listener);

  void removeListener(void Function(SyncState) listener) =>
      _listeners.remove(listener);

  void setSyncing() => _notify(const SyncStateSyncing());
  void setSuccess(DateTime at) => _notify(SyncStateIdle(lastSyncedAt: at));
  void setError(String msg) => _notify(SyncStateError(msg));

  void _notify(SyncState next) {
    _state = next;
    for (final l in List.of(_listeners)) {
      l(next);
    }
  }
}

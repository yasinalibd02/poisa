import 'dart:async';
import 'dart:developer' as developer;

/// Firestore applies a write to its local cache *synchronously* and only
/// completes the future it returns once a server has acknowledged it. Awaiting
/// that future therefore never returns while the device is offline — which is
/// why every save used to spin forever with no connection, even though the row
/// was already in the cache and already on screen.
///
/// Repositories hand the write here instead of awaiting it. Every listener has
/// seen the change by the time this returns, and the SDK replays the write
/// itself once the connection comes back, so "committed locally" is treated as
/// done.
///
/// [label] only ever reaches the debug log — a write that fails for a real
/// reason (rules, a malformed document) is a programming error, not something
/// to interrupt the user with, because by then they have moved on.
void queueWrite(Future<void> write, String label) {
  unawaited(
    write.catchError((Object error, StackTrace stack) {
      developer.log(
        'Deferred Firestore write failed: $label',
        name: 'poisa.offline',
        error: error,
        stackTrace: stack,
      );
    }),
  );
}

/// How long a read may wait on the network before the cached answer (or none
/// at all) is good enough. Firestore's own `get()` has no timeout, so a flaky
/// connection can otherwise hold a screen on its skeleton indefinitely.
const Duration kReadTimeout = Duration(seconds: 6);

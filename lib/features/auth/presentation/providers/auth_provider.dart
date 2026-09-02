import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_failure.dart';
import '../../data/auth_repository.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepository(),
);

/// Live Firebase session. Everything auth-dependent hangs off this.
final StreamProvider<User?> authStateProvider = StreamProvider<User?>((Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The signed-in user, or `null`. Falls back to the synchronous
/// `currentUser` so the very first frame after a warm start is already correct.
final Provider<User?> currentUserProvider = Provider<User?>((Ref ref) {
  final AsyncValue<User?> state = ref.watch(authStateProvider);
  return state.when(
    data: (User? user) => user,
    loading: () => ref.watch(authRepositoryProvider).currentUser,
    error: (Object error, StackTrace stack) => null,
  );
});

final Provider<String?> uidProvider = Provider<String?>(
  (Ref ref) => ref.watch(currentUserProvider)?.uid,
);

/// True when the current session is an anonymous "guest" one — used to swap
/// in the "nothing is saved" copy and the "exit guest mode" action.
final Provider<bool> isGuestProvider = Provider<bool>(
  (Ref ref) => ref.watch(currentUserProvider)?.isAnonymous ?? false,
);

/// Drives the Login button: `loading` while the Google sheet is up, `error`
/// when it failed for a reason worth telling the user about.
final AsyncNotifierProvider<SignInController, void> signInControllerProvider =
    AsyncNotifierProvider<SignInController, void>(SignInController.new);

class SignInController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns `true` when a session was created, `false` when the user simply
  /// backed out (no error UI in that case).
  Future<bool> signInWithGoogle() async {
    state = const AsyncValue<void>.loading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stack) {
      final AppFailure failure = AppFailure.from(error);
      if (failure.isCancelled) {
        state = const AsyncValue<void>.data(null);
        return false;
      }
      state = AsyncValue<void>.error(failure, stack);
      return false;
    }
  }

  /// Opens an anonymous session. Returns `true` once it is live so the caller
  /// can route straight to the dashboard.
  Future<bool> continueAsGuest() async {
    state = const AsyncValue<void>.loading();
    try {
      await ref.read(authRepositoryProvider).continueAsGuest();
      state = const AsyncValue<void>.data(null);
      return true;
    } catch (error, stack) {
      state = AsyncValue<void>.error(AppFailure.from(error), stack);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue<void>.loading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue<void>.data(null);
    } catch (error, stack) {
      state = AsyncValue<void>.error(AppFailure.from(error), stack);
    }
  }
}

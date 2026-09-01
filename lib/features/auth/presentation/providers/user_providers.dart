import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/user_model.dart';
import '../../data/user_repository.dart';
import 'auth_provider.dart';

final Provider<UserRepository> userRepositoryProvider = Provider<UserRepository>(
  (Ref ref) => UserRepository(ref.watch(firestoreRefsProvider)),
);

/// The signed-in user's profile document.
final StreamProvider<UserModel?> userDocProvider = StreamProvider<UserModel?>((
  Ref ref,
) {
  if (ref.watch(uidProvider) == null) {
    return Stream<UserModel?>.value(null);
  }
  return ref.watch(userRepositoryProvider).watchUser();
});

/// Ensures the profile document exists and, on a first sign-in, seeds the
/// default categories and the Cash account. The shell waits on this before
/// showing any data screen, so no screen can render against an unseeded
/// account.
final FutureProvider<void> userBootstrapProvider = FutureProvider<void>((
  Ref ref,
) async {
  final User? user = ref.watch(currentUserProvider);
  if (user == null) return;

  final UserRepository repository = ref.watch(userRepositoryProvider);
  final AppSettings settings = ref.read(settingsProvider);

  await repository.ensureUserDocument(authUser: user, settings: settings);

  // A returning user on a fresh device adopts the preferences stored with
  // their profile, but only where this device has no local choice yet.
  final UserModel? remote = await repository.watchUser().first;
  if (remote != null) {
    await ref
        .read(settingsProvider.notifier)
        .hydrateFromRemote(remote.toMap());
  }
});

/// Pushes local preference changes up to the profile document.
///
/// Local preferences are authoritative for rendering (instant and offline);
/// this mirror exists purely so a second device can adopt them.
final Provider<void> settingsMirrorProvider = Provider<void>((Ref ref) {
  ref.listen<AppSettings>(settingsProvider, (
    AppSettings? previous,
    AppSettings next,
  ) {
    if (previous == null || ref.read(uidProvider) == null) return;
    if (previous.toMap().toString() == next.toMap().toString()) return;
    // Fire-and-forget: a failed mirror must never block the UI, and the next
    // change will retry it.
    ref.read(userRepositoryProvider).updatePreferences(next).ignore();
  });
});

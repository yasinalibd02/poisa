import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'firestore_providers.dart';

/// Whether Firestore currently has a server connection.
///
/// Derived from snapshot metadata on the (tiny) user document rather than a
/// platform connectivity plugin: what matters to the user is whether their
/// writes are reaching the server, not whether a Wi-Fi radio is on.
final StreamProvider<bool> isOnlineProvider = StreamProvider<bool>((Ref ref) {
  if (ref.watch(uidProvider) == null) {
    return Stream<bool>.value(true);
  }
  return ref
      .watch(firestoreRefsProvider)
      .user
      .snapshots(includeMetadataChanges: true)
      .map(
        (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
            !snapshot.metadata.isFromCache,
      )
      .handleError((Object _) => false);
});

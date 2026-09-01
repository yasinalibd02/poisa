import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../utils/app_failure.dart';
import 'firestore_refs.dart';

final Provider<FirebaseFirestore> firestoreProvider = Provider<FirebaseFirestore>(
  (Ref ref) => FirebaseFirestore.instance,
);

/// User-scoped Firestore paths.
///
/// Reading this while signed out is a programming error — every data screen
/// sits behind the router's auth guard, and stream providers check
/// [uidProvider] before touching a repository.
final Provider<FirestoreRefs> firestoreRefsProvider = Provider<FirestoreRefs>((
  Ref ref,
) {
  final String? uid = ref.watch(uidProvider);
  if (uid == null) {
    throw const AppFailure(
      FailureKind.permissionDenied,
      debugMessage: 'Firestore was accessed with no signed-in user.',
    );
  }
  return FirestoreRefs(ref.watch(firestoreProvider), uid);
});

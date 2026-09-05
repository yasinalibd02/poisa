import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

import '../../../core/constants/default_seed_data.dart';
import '../../../core/constants/enums.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/app_failure.dart';
import '../../settings/data/app_settings.dart';
import 'user_model.dart';

/// Owns `users/{uid}`: profile, mirrored preferences, first-login seeding and
/// the full account wipe.
class UserRepository {
  const UserRepository(this._refs);

  final FirestoreRefs _refs;

  /// How many documents to delete per batch during an account wipe.
  /// Firestore's hard limit is 500 writes per batch.
  static const int _deleteBatchSize = 300;

  Stream<UserModel?> watchUser() {
    return _refs.user.snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> doc) =>
          doc.exists ? UserModel.fromDoc(doc) : null,
    );
  }

  /// Creates the profile document on first sign-in and seeds the default
  /// categories plus a single Cash account. Safe to call on every sign-in —
  /// an existing document is only refreshed with the latest Google profile.
  ///
  /// Returns `null` when this call just created the document — there is
  /// nothing to hydrate from, since the values written *are* this device's
  /// local settings. Returns the existing raw document map when the profile
  /// already existed (a returning user, or a second device), so the caller
  /// can hydrate its preferences from it without a second round trip.
  Future<Map<String, Object?>?> ensureUserDocument({
    required User authUser,
    required AppSettings settings,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _refs.user
          .get();
      final DateTime now = DateTime.now();

      if (snapshot.exists) {
        await _refs.user.set(<String, Object?>{
          'displayName': authUser.displayName ?? '',
          'email': authUser.email ?? '',
          'photoUrl': authUser.photoURL,
          'updatedAt': Timestamp.fromDate(now),
        }, SetOptions(merge: true),);
        return snapshot.data();
      }

      final UserModel model = UserModel(
        uid: _refs.uid,
        displayName: authUser.displayName ?? '',
        email: authUser.email ?? '',
        photoUrl: authUser.photoURL,
        currencyCode: settings.currencyCode,
        languageCode: settings.languageCode,
        themeMode: AppSettings.themeModeToName(settings.themeMode),
        useBanglaNumerals: settings.useBanglaNumerals,
        createdAt: now,
        updatedAt: now,
      );

      final WriteBatch batch = _refs.batch();
      batch.set(_refs.user, model.toMap());
      _addSeedWrites(batch, settings.languageCode, now);
      await batch.commit();
      return null;
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  // Fixed, deterministic ids (rather than Firestore's random .doc() ids) make
  // this safe to run more than once — e.g. a first-sign-in race between two
  // devices, or a retry after a dropped connection — since a repeat write
  // overwrites the same seed documents instead of creating duplicates.
  void _addSeedWrites(WriteBatch batch, String languageCode, DateTime now) {
    int order = 0;
    for (final SeedCategory seed in DefaultSeedData.all) {
      batch.set(
        _refs.categories.doc('seed_${seed.key}'),
        seed.toModel(sortOrder: order++, now: now).toMap(),
      );
    }

    batch.set(_refs.accounts.doc('seed_cash'), <String, Object?>{
      'name': DefaultSeedData.cashAccountName(languageCode),
      'type': AccountType.cash.name,
      'icon': AccountType.cash.defaultIconKey,
      'colorHex': '#1B7F6B',
      'openingBalance': 0.0,
      'isArchived': false,
      'sortOrder': 0,
      'createdAt': Timestamp.fromDate(now),
    });
  }

  /// Mirrors local preferences into the profile document so another device
  /// adopts them on sign-in. Fire-and-forget: the local copy already won.
  Future<void> updatePreferences(AppSettings settings) async {
    try {
      await _refs.user.set(<String, Object?>{
        ...settings.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true),);
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Permanently removes every document under `users/{uid}`, then the profile
  /// document itself. Runs before the auth account is deleted, because the
  /// security rules require a live session.
  Future<void> deleteAllData() async {
    try {
      for (final CollectionReference<Map<String, dynamic>> collection
          in <CollectionReference<Map<String, dynamic>>>[
            _refs.transactions,
            _refs.budgets,
            _refs.categories,
            _refs.accounts,
          ]) {
        await _deleteCollection(collection);
      }
      await _refs.user.delete();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await collection
          .limit(_deleteBatchSize)
          .get();
      if (snapshot.docs.isEmpty) return;

      final WriteBatch batch = _refs.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < _deleteBatchSize) return;
    }
  }
}

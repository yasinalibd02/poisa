import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

import '../../../core/constants/default_seed_data.dart';
import '../../../core/constants/enums.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/offline_write.dart';
import '../../../core/utils/app_failure.dart';
import '../../categories/data/category_model.dart';
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
  /// Returns `null` when there was nothing to hydrate from — a profile this
  /// call just created, or one it could not read. Returns the existing raw
  /// document map otherwise (a returning user, or a second device), so the
  /// caller can adopt its preferences without a second round trip.
  ///
  /// Nothing here waits on the network. Firestore applies writes to its local
  /// cache immediately and replays them when the connection returns, so the
  /// app finishes booting and is fully usable with no signal at all.
  Future<Map<String, Object?>?> ensureUserDocument({
    required User authUser,
    required AppSettings settings,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final DocumentSnapshot<Map<String, dynamic>>? snapshot =
          await _readUserDoc();

      if (snapshot != null && snapshot.exists) {
        queueWrite(
          _refs.user.set(<String, Object?>{
            'displayName': authUser.displayName ?? '',
            'email': authUser.email ?? '',
            'photoUrl': authUser.photoURL,
            'updatedAt': Timestamp.fromDate(now),
          }, SetOptions(merge: true),),
          'user profile refresh',
        );
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

      // The profile is missing — or simply unreadable, because the read above
      // found neither a server nor anything in a cold cache. Seeding is gated
      // on the categories collection genuinely being empty rather than on that
      // read, so an unanswered read can never lay a second set of defaults
      // over an account that already has them. That is what used to leave a
      // returning guest looking at two of every category.
      final bool alreadySeeded = await _hasAnyCategory();

      final WriteBatch batch = _refs.batch();
      // Merged, not replaced: an offline boot that guessed wrong about a
      // profile existing must not clobber the preferences already stored on it.
      batch.set(_refs.user, model.toMap(), SetOptions(merge: true));
      if (!alreadySeeded) _addSeedWrites(batch, settings.languageCode, now);
      queueWrite(batch.commit(), 'user bootstrap');

      return null;
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Reads the profile without ever hanging: the server gets [kReadTimeout],
  /// then the local cache answers, and `null` means neither could.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _readUserDoc() async {
    try {
      return await _refs.user.get().timeout(kReadTimeout);
    } catch (_) {
      try {
        return await _refs.user.get(const GetOptions(source: Source.cache));
      } catch (_) {
        return null;
      }
    }
  }

  Future<bool> _hasAnyCategory() async {
    final Query<Map<String, dynamic>> probe = _refs.categories.limit(1);
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await probe
          .get()
          .timeout(kReadTimeout);
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      try {
        final QuerySnapshot<Map<String, dynamic>> cached = await probe.get(
          const GetOptions(source: Source.cache),
        );
        return cached.docs.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Brings an existing account's default categories back in line with
  /// [DefaultSeedData], in one pass over the collection:
  ///
  ///  * collapses defaults that exist more than once — what earlier builds
  ///    left behind when a bootstrap re-seeded an already-seeded account, and
  ///    why returning guests were looking at two of every category;
  ///  * adds the defaults introduced by a later release (the lending
  ///    categories), which a first-sign-in-only seed never reaches.
  ///
  /// Only `isDefault` categories are considered — two user-created categories
  /// sharing a name are the user's business. A no-op once it has run, and safe
  /// to call on every sign-in.
  Future<void> reconcileDefaultCategories() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _read(
        _refs.categories,
      );

      final List<CategoryModel> existing = snapshot.docs
          .map(CategoryModel.fromDoc)
          .toList(growable: false);

      final List<CategoryModel> survivors = await _collapseDuplicates(existing);
      _addMissingDefaults(survivors);
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Merges each group of same-identity default categories down to one,
  /// returning every category that is still live afterwards.
  Future<List<CategoryModel>> _collapseDuplicates(
    List<CategoryModel> all,
  ) async {
    final Map<String, List<CategoryModel>> byIdentity =
        <String, List<CategoryModel>>{};
    for (final CategoryModel category in all) {
      if (!category.isDefault) continue;
      byIdentity
          .putIfAbsent(_identityOf(category), () => <CategoryModel>[])
          .add(category);
    }

    final Set<String> discarded = <String>{};
    for (final List<CategoryModel> group in byIdentity.values) {
      if (group.length < 2) continue;
      group.sort(_canonicalFirst);
      final CategoryModel keep = group.first;
      for (final CategoryModel duplicate in group.skip(1)) {
        discarded.add(duplicate.id);
        await _absorbCategory(duplicate.id, into: keep.id);
      }
    }

    if (discarded.isEmpty) return all;
    return all
        .where((CategoryModel c) => !discarded.contains(c.id))
        .toList(growable: false);
  }

  /// Writes the defaults in [DefaultSeedData.lateAdditions] that this account
  /// is missing.
  ///
  /// Deliberately limited to those: an older default that no longer matches
  /// the seed file has almost certainly just been renamed by the user, and
  /// re-adding it would put a second copy of it on their screen — the exact
  /// problem the pass above exists to clean up.
  ///
  /// A category counts as present under either its canonical id or its English
  /// name, so a lending category the user happened to create by hand is not
  /// doubled either.
  void _addMissingDefaults(List<CategoryModel> existing) {
    final Set<String> presentIds = <String>{
      for (final CategoryModel c in existing) c.id,
    };
    final Set<String> presentIdentities = <String>{
      for (final CategoryModel c in existing) _identityOf(c),
    };

    final Map<CategoryType, int> nextOrder = <CategoryType, int>{};
    for (final CategoryModel c in existing) {
      final int next = c.sortOrder + 1;
      if (next > (nextOrder[c.type] ?? 0)) nextOrder[c.type] = next;
    }

    final DateTime now = DateTime.now();
    final WriteBatch batch = _refs.batch();
    int added = 0;

    for (final SeedCategory seed in DefaultSeedData.lateAdditions) {
      final String id = DefaultSeedData.docIdFor(seed.key);
      final String identity =
          '${seed.type.name}|${seed.nameEn.trim().toLowerCase()}';
      if (presentIds.contains(id) || presentIdentities.contains(identity)) {
        continue;
      }

      final int order = nextOrder[seed.type] ?? 0;
      nextOrder[seed.type] = order + 1;
      batch.set(
        _refs.categories.doc(id),
        seed.toModel(sortOrder: order, now: now).toMap(),
      );
      added++;
    }

    if (added > 0) queueWrite(batch.commit(), 'default category backfill');
  }

  static String _identityOf(CategoryModel category) =>
      '${category.type.name}|${category.nameEn.trim().toLowerCase()}';

  /// Orders a duplicate group so the copy to keep comes first: the canonical
  /// seeded id wins, then the oldest, then the lowest id as a tiebreak so the
  /// result is the same on every device.
  static int _canonicalFirst(CategoryModel a, CategoryModel b) {
    final bool aSeed = a.id.startsWith('seed_');
    final bool bSeed = b.id.startsWith('seed_');
    if (aSeed != bSeed) return aSeed ? -1 : 1;
    final int byAge = a.createdAt.compareTo(b.createdAt);
    if (byAge != 0) return byAge;
    return a.id.compareTo(b.id);
  }

  /// Repoints every reference to [duplicateId] at [into], then deletes it.
  Future<void> _absorbCategory(String duplicateId, {required String into}) async {
    final DateTime now = DateTime.now();

    final QuerySnapshot<Map<String, dynamic>> transactions = await _read(
      _refs.transactions.where('categoryId', isEqualTo: duplicateId),
    );
    final QuerySnapshot<Map<String, dynamic>> budgets = await _read(
      _refs.budgets.where('categoryId', isEqualTo: duplicateId),
    );

    final WriteBatch batch = _refs.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in transactions.docs) {
      batch.update(doc.reference, <String, Object?>{
        'categoryId': into,
        'updatedAt': Timestamp.fromDate(now),
      });
    }
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in budgets.docs) {
      batch.update(doc.reference, <String, Object?>{'categoryId': into});
    }
    batch.delete(_refs.categories.doc(duplicateId));
    queueWrite(batch.commit(), 'category dedupe $duplicateId');
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _read(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get().timeout(kReadTimeout);
    } catch (_) {
      return query.get(const GetOptions(source: Source.cache));
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
        _refs.categories.doc(DefaultSeedData.docIdFor(seed.key)),
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
    queueWrite(
      _refs.user.set(<String, Object?>{
        ...settings.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true),),
      'user preferences mirror',
    );
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

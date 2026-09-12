import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_refs.dart';
import '../../../core/services/offline_write.dart';
import '../../../core/utils/app_failure.dart';
import 'account_model.dart';

/// Owns `users/{uid}/accounts`.
///
/// Balances are *derived* (opening balance ± transactions), never stored, so a
/// deleted or edited transaction can never leave a stale balance behind.
class AccountRepository {
  const AccountRepository(this._refs);

  final FirestoreRefs _refs;

  Stream<List<AccountModel>> watchAll() {
    return _refs.accounts
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(AccountModel.fromDoc).toList(growable: false),
        )
        .handleError((Object error) => throw AppFailure.from(error));
  }

  Future<String> create(AccountModel account) async {
    final DocumentReference<Map<String, dynamic>> doc = _refs.accounts.doc();
    queueWrite(doc.set(account.toMap()), 'account create ${doc.id}');
    return doc.id;
  }

  Future<void> update(AccountModel account) async {
    queueWrite(
      _refs.accounts.doc(account.id).update(account.toMap()),
      'account update ${account.id}',
    );
  }

  Future<void> delete(String id) async {
    queueWrite(_refs.accounts.doc(id).delete(), 'account delete $id');
  }

  Future<void> setArchived(String id, bool archived) async {
    queueWrite(
      _refs.accounts.doc(id).update(<String, Object?>{'isArchived': archived}),
      'account archive $id',
    );
  }

  Future<void> reorder(List<AccountModel> ordered) async {
    final WriteBatch batch = _refs.batch();
    for (int i = 0; i < ordered.length; i++) {
      batch.update(_refs.accounts.doc(ordered[i].id), <String, Object?>{
        'sortOrder': i,
      });
    }
    queueWrite(batch.commit(), 'account reorder');
  }

  int nextSortOrder(List<AccountModel> existing) {
    if (existing.isEmpty) return 0;
    return existing
            .map((AccountModel a) => a.sortOrder)
            .reduce((int a, int b) => a > b ? a : b) +
        1;
  }
}

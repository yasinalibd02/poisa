import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/app_failure.dart';
import 'transaction_model.dart';

/// Owns `users/{uid}/transactions`.
///
/// The ledger is read through a single [watchAll] listener rather than one
/// query per screen. Every derived number — account balances, budget spend,
/// report aggregates — has to be exact, which means seeing every row anyway;
/// and Firestore's offline cache serves that listener locally, so the app
/// opens with correct balances before the network answers. Screens then filter
/// and page that list in memory. For a personal ledger (thousands of rows)
/// this is comfortably cheap; a far larger one would want denormalised running
/// totals instead.
class TransactionRepository {
  const TransactionRepository(this._refs);

  final FirestoreRefs _refs;

  static const int _writeBatchSize = 300;

  Query<Map<String, dynamic>> get _byDateDesc =>
      _refs.transactions.orderBy('date', descending: true);

  /// Every transaction, newest first.
  Stream<List<TransactionModel>> watchAll() => _mapQuery(_byDateDesc);

  Stream<List<TransactionModel>> _mapQuery(Query<Map<String, dynamic>> query) {
    return query
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(TransactionModel.fromDoc)
              .toList(growable: false),
        )
        .handleError((Object error) => throw AppFailure.from(error));
  }

  Future<TransactionModel> create(TransactionModel transaction) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _refs.transactions
          .doc();
      final TransactionModel saved = transaction.copyWith(id: doc.id);
      await doc.set(saved.toMap());
      return saved;
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> update(TransactionModel transaction) async {
    try {
      await _refs.transactions.doc(transaction.id).set(transaction.toMap());
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _refs.transactions.doc(id).delete();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Re-creates a deleted transaction under its original id, so the undo
  /// snackbar restores the exact row rather than a copy.
  Future<void> restore(TransactionModel transaction) async {
    try {
      await _refs.transactions.doc(transaction.id).set(transaction.toMap());
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> deleteMany(Iterable<String> ids) async {
    try {
      final List<String> all = ids.toList(growable: false);
      for (int start = 0; start < all.length; start += _writeBatchSize) {
        final WriteBatch batch = _refs.batch();
        for (final String id in all.skip(start).take(_writeBatchSize)) {
          batch.delete(_refs.transactions.doc(id));
        }
        await batch.commit();
      }
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> restoreMany(Iterable<TransactionModel> transactions) async {
    try {
      final List<TransactionModel> all = transactions.toList(growable: false);
      for (int start = 0; start < all.length; start += _writeBatchSize) {
        final WriteBatch batch = _refs.batch();
        for (final TransactionModel item in all.skip(start).take(
          _writeBatchSize,
        )) {
          batch.set(_refs.transactions.doc(item.id), item.toMap());
        }
        await batch.commit();
      }
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Number of transactions referencing a category — gates category deletion.
  Future<int> countForCategory(String categoryId) =>
      _count(_refs.transactions.where('categoryId', isEqualTo: categoryId));

  /// Number of transactions touching an account, on either side of a transfer.
  Future<int> countForAccount(String accountId) async {
    final List<int> counts = await Future.wait<int>(<Future<int>>[
      _count(_refs.transactions.where('accountId', isEqualTo: accountId)),
      _count(_refs.transactions.where('toAccountId', isEqualTo: accountId)),
    ]);
    return counts[0] + counts[1];
  }

  /// Uses the server-side aggregate when online (one billed read) and falls
  /// back to counting cached documents when there is no connection.
  Future<int> _count(Query<Map<String, dynamic>> query) async {
    try {
      final AggregateQuerySnapshot snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      try {
        final QuerySnapshot<Map<String, dynamic>> cached = await query.get(
          const GetOptions(source: Source.cache),
        );
        return cached.docs.length;
      } catch (error) {
        throw AppFailure.from(error);
      }
    }
  }

  /// Moves every transaction from one category to another, so a category with
  /// history can still be deleted without orphaning rows.
  Future<void> reassignCategory({
    required String fromCategoryId,
    required String toCategoryId,
  }) async {
    await _reassign(
      _refs.transactions.where('categoryId', isEqualTo: fromCategoryId),
      <String, Object?>{'categoryId': toCategoryId},
    );
  }

  /// Same idea for accounts — both the source and destination sides.
  Future<void> reassignAccount({
    required String fromAccountId,
    required String toAccountId,
  }) async {
    await _reassign(
      _refs.transactions.where('accountId', isEqualTo: fromAccountId),
      <String, Object?>{'accountId': toAccountId},
    );
    await _reassign(
      _refs.transactions.where('toAccountId', isEqualTo: fromAccountId),
      <String, Object?>{'toAccountId': toAccountId},
    );
  }

  Future<void> _reassign(
    Query<Map<String, dynamic>> query,
    Map<String, Object?> update,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
          snapshot.docs;
      final Map<String, Object?> payload = <String, Object?>{
        ...update,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      for (int start = 0; start < docs.length; start += _writeBatchSize) {
        final WriteBatch batch = _refs.batch();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs.skip(
          start,
        ).take(_writeBatchSize)) {
          batch.update(doc.reference, payload);
        }
        await batch.commit();
      }
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// One-shot read of everything, for CSV export.
  Future<List<TransactionModel>> fetchAll() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _byDateDesc
          .get();
      return snapshot.docs.map(TransactionModel.fromDoc).toList(growable: false);
    } catch (error) {
      throw AppFailure.from(error);
    }
  }
}

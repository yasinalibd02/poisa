import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/app_failure.dart';
import 'budget_model.dart';

/// Owns `users/{uid}/budgets`. Budgets are per (year, month) slot.
class BudgetRepository {
  const BudgetRepository(this._refs);

  final FirestoreRefs _refs;

  Stream<List<BudgetModel>> watchAll() {
    return _refs.budgets
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(BudgetModel.fromDoc).toList(growable: false),
        )
        .handleError((Object error) => throw AppFailure.from(error));
  }

  Stream<List<BudgetModel>> watchForMonth(int year, int month) {
    return _refs.budgets
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(BudgetModel.fromDoc).toList(growable: false),
        )
        .handleError((Object error) => throw AppFailure.from(error));
  }

  Future<String> create(BudgetModel budget) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _refs.budgets.doc();
      await doc.set(budget.toMap());
      return doc.id;
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> update(BudgetModel budget) async {
    try {
      await _refs.budgets.doc(budget.id).set(budget.toMap());
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _refs.budgets.doc(id).delete();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Copies a whole month's budgets forward. Categories that already have a
  /// budget in the target month are skipped rather than duplicated.
  ///
  /// Returns the number of budgets actually created.
  Future<int> copyMonth({
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> source = await _refs.budgets
          .where('year', isEqualTo: fromYear)
          .where('month', isEqualTo: fromMonth)
          .get();
      if (source.docs.isEmpty) return 0;

      final QuerySnapshot<Map<String, dynamic>> target = await _refs.budgets
          .where('year', isEqualTo: toYear)
          .where('month', isEqualTo: toMonth)
          .get();
      final Set<String?> existing = target.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                doc.data()['categoryId'] as String?,
          )
          .toSet();

      final DateTime now = DateTime.now();
      final WriteBatch batch = _refs.batch();
      int created = 0;

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in source.docs) {
        final BudgetModel budget = BudgetModel.fromDoc(doc);
        if (existing.contains(budget.categoryId)) continue;
        batch.set(
          _refs.budgets.doc(),
          budget
              .copyWith(year: toYear, month: toMonth, createdAt: now)
              .toMap(),
        );
        created++;
      }

      if (created > 0) await batch.commit();
      return created;
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<List<BudgetModel>> fetchAll() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _refs.budgets
          .get();
      return snapshot.docs.map(BudgetModel.fromDoc).toList(growable: false);
    } catch (error) {
      throw AppFailure.from(error);
    }
  }
}

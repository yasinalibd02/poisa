import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/app_failure.dart';
import 'category_model.dart';

/// Owns `users/{uid}/categories`.
class CategoryRepository {
  const CategoryRepository(this._refs);

  final FirestoreRefs _refs;

  /// All categories, ordered the way the user arranged them.
  Stream<List<CategoryModel>> watchAll() {
    return _refs.categories
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(CategoryModel.fromDoc)
              .toList(growable: false),
        )
        .handleError((Object error) => throw AppFailure.from(error));
  }

  Future<String> create(CategoryModel category) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _refs.categories.doc();
      await doc.set(category.toMap());
      return doc.id;
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> update(CategoryModel category) async {
    try {
      await _refs.categories.doc(category.id).update(category.toMap());
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _refs.categories.doc(id).delete();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Persists a drag-to-reorder in one batch.
  Future<void> reorder(List<CategoryModel> orderedSubset) async {
    try {
      final WriteBatch batch = _refs.batch();
      for (int i = 0; i < orderedSubset.length; i++) {
        batch.update(_refs.categories.doc(orderedSubset[i].id), <String, Object?>{
          'sortOrder': i,
        });
      }
      await batch.commit();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// The next free sort position for [type].
  int nextSortOrder(List<CategoryModel> existing, CategoryType type) {
    final Iterable<int> orders = existing
        .where((CategoryModel c) => c.type == type)
        .map((CategoryModel c) => c.sortOrder);
    if (orders.isEmpty) return 0;
    return orders.reduce((int a, int b) => a > b ? a : b) + 1;
  }
}

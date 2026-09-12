import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/offline_write.dart';
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
    final DocumentReference<Map<String, dynamic>> doc = _refs.categories.doc();
    queueWrite(doc.set(category.toMap()), 'category create ${doc.id}');
    return doc.id;
  }

  Future<void> update(CategoryModel category) async {
    queueWrite(
      _refs.categories.doc(category.id).update(category.toMap()),
      'category update ${category.id}',
    );
  }

  Future<void> delete(String id) async {
    queueWrite(_refs.categories.doc(id).delete(), 'category delete $id');
  }

  /// Persists a drag-to-reorder in one batch.
  Future<void> reorder(List<CategoryModel> orderedSubset) async {
    final WriteBatch batch = _refs.batch();
    for (int i = 0; i < orderedSubset.length; i++) {
      batch.update(_refs.categories.doc(orderedSubset[i].id), <String, Object?>{
        'sortOrder': i,
      });
    }
    queueWrite(batch.commit(), 'category reorder');
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

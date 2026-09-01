import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/services/firestore_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/category_model.dart';
import '../../data/category_repository.dart';

final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
      (Ref ref) => CategoryRepository(ref.watch(firestoreRefsProvider)),
    );

/// Live list of every category, in user order. Emits an empty list rather
/// than an error while signed out, so sign-out does not flash a red screen.
final StreamProvider<List<CategoryModel>> categoriesStreamProvider =
    StreamProvider<List<CategoryModel>>((Ref ref) {
      if (ref.watch(uidProvider) == null) {
        return Stream<List<CategoryModel>>.value(const <CategoryModel>[]);
      }
      return ref.watch(categoryRepositoryProvider).watchAll();
    });

/// Categories of one type, for the picker and the Categories tabs.
final ProviderFamily<List<CategoryModel>, CategoryType>
categoriesByTypeProvider = Provider.family<List<CategoryModel>, CategoryType>((
  Ref ref,
  CategoryType type,
) {
  final List<CategoryModel> all =
      ref.watch(categoriesStreamProvider).valueOrNull ?? const <CategoryModel>[];
  return all.where((CategoryModel c) => c.type == type).toList(growable: false);
});

/// id → category, for O(1) lookups when rendering transaction rows.
final Provider<Map<String, CategoryModel>> categoryMapProvider =
    Provider<Map<String, CategoryModel>>((Ref ref) {
      final List<CategoryModel> all =
          ref.watch(categoriesStreamProvider).valueOrNull ??
          const <CategoryModel>[];
      return <String, CategoryModel>{
        for (final CategoryModel category in all) category.id: category,
      };
    });

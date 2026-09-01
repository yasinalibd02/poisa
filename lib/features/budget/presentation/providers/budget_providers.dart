import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/services/firestore_providers.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/budget_model.dart';
import '../../data/budget_repository.dart';

final Provider<BudgetRepository> budgetRepositoryProvider =
    Provider<BudgetRepository>(
      (Ref ref) => BudgetRepository(ref.watch(firestoreRefsProvider)),
    );

final StreamProvider<List<BudgetModel>> budgetsStreamProvider =
    StreamProvider<List<BudgetModel>>((Ref ref) {
      if (ref.watch(uidProvider) == null) {
        return Stream<List<BudgetModel>>.value(const <BudgetModel>[]);
      }
      return ref.watch(budgetRepositoryProvider).watchAll();
    });

/// A budget joined with its category and the amount already spent.
@immutable
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spent,
    required this.daysLeft,
  });

  final BudgetModel budget;

  /// `null` for the overall budget.
  final CategoryModel? category;

  final double spent;
  final int daysLeft;

  double get limit => budget.limitAmount;

  double get remaining => Validators.roundMoney(limit - spent);

  bool get isOverBudget => spent > limit;

  double get overBy => Validators.roundMoney(spent - limit);

  /// `spent / limit`, guarded against a zero limit.
  double get progress => limit <= 0 ? 0 : spent / limit;
}

/// Budgets for the currently selected month, joined with live spend.
///
/// Ordered most-urgent first, so the dashboard's "top 3" are the three the
/// user most needs to see.
final Provider<List<BudgetProgress>> selectedMonthBudgetsProvider =
    Provider<List<BudgetProgress>>((Ref ref) {
      final DateRange range = ref.watch(selectedMonthRangeProvider);
      final List<BudgetModel> all =
          ref.watch(budgetsStreamProvider).valueOrNull ?? const <BudgetModel>[];
      final Map<String, CategoryModel> categories = ref.watch(
        categoryMapProvider,
      );

      final List<BudgetModel> forMonth = all
          .where(
            (BudgetModel b) =>
                b.year == range.start.year && b.month == range.start.month,
          )
          .toList(growable: false);
      if (forMonth.isEmpty) return const <BudgetProgress>[];

      final Map<String, double> spendByCategory = ref.watch(
        categoryTotalsProvider(
          CategoryTotalsQuery(range, CategoryType.expense),
        ),
      );
      final double totalSpend = spendByCategory.values.fold<double>(
        0,
        (double sum, double value) => sum + value,
      );
      final int daysLeft = PeriodUtils.daysRemaining(range, DateTime.now());

      final List<BudgetProgress> progress = forMonth
          .map(
            (BudgetModel budget) => BudgetProgress(
              budget: budget,
              category: budget.categoryId == null
                  ? null
                  : categories[budget.categoryId],
              spent: budget.isOverall
                  ? Validators.roundMoney(totalSpend)
                  : spendByCategory[budget.categoryId] ?? 0,
              daysLeft: daysLeft,
            ),
          )
          .toList();

      progress.sort((BudgetProgress a, BudgetProgress b) {
        // Overall budget always leads, then the closest to its limit.
        if (a.budget.isOverall != b.budget.isOverall) {
          return a.budget.isOverall ? -1 : 1;
        }
        return b.progress.compareTo(a.progress);
      });
      return progress;
    });

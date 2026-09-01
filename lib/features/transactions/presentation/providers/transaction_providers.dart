import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/services/firestore_providers.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/transaction_model.dart';
import '../../data/transaction_repository.dart';

final Provider<TransactionRepository> transactionRepositoryProvider =
    Provider<TransactionRepository>(
      (Ref ref) => TransactionRepository(ref.watch(firestoreRefsProvider)),
    );

/// The whole ledger, newest first. Every other transaction-shaped provider is
/// derived from this one listener — see [TransactionRepository] for why.
final StreamProvider<List<TransactionModel>> allTransactionsProvider =
    StreamProvider<List<TransactionModel>>((Ref ref) {
      if (ref.watch(uidProvider) == null) {
        return Stream<List<TransactionModel>>.value(const <TransactionModel>[]);
      }
      return ref.watch(transactionRepositoryProvider).watchAll();
    });

/// Transactions whose date falls inside [range], newest first.
final ProviderFamily<List<TransactionModel>, DateRange>
transactionsInRangeProvider =
    Provider.family<List<TransactionModel>, DateRange>((
      Ref ref,
      DateRange range,
    ) {
      final List<TransactionModel> all =
          ref.watch(allTransactionsProvider).valueOrNull ??
          const <TransactionModel>[];
      return all
          .where((TransactionModel t) => range.contains(t.date))
          .toList(growable: false);
    });

/// Income / expense / net for a period. Transfers are deliberately excluded:
/// moving money between your own accounts is neither income nor expense.
@immutable
class MoneySummary {
  const MoneySummary({required this.income, required this.expense});

  final double income;
  final double expense;

  double get net => Validators.roundMoney(income - expense);

  static const MoneySummary zero = MoneySummary(income: 0, expense: 0);

  static MoneySummary from(Iterable<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    for (final TransactionModel transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amount;
        case TransactionType.expense:
          expense += transaction.amount;
        case TransactionType.transfer:
          break;
      }
    }
    return MoneySummary(
      income: Validators.roundMoney(income),
      expense: Validators.roundMoney(expense),
    );
  }
}

final ProviderFamily<MoneySummary, DateRange> summaryForRangeProvider =
    Provider.family<MoneySummary, DateRange>((Ref ref, DateRange range) {
      return MoneySummary.from(ref.watch(transactionsInRangeProvider(range)));
    });

/// Key for [categoryTotalsProvider] — a period plus which side of the ledger.
@immutable
class CategoryTotalsQuery {
  const CategoryTotalsQuery(this.range, this.type);

  final DateRange range;
  final CategoryType type;

  @override
  bool operator ==(Object other) =>
      other is CategoryTotalsQuery &&
      other.range == range &&
      other.type == type;

  @override
  int get hashCode => Object.hash(range, type);
}

/// `categoryId → total`, highest first. Backs the donut chart, the report
/// ranking and every budget's spent figure.
final ProviderFamily<Map<String, double>, CategoryTotalsQuery>
categoryTotalsProvider =
    Provider.family<Map<String, double>, CategoryTotalsQuery>((
      Ref ref,
      CategoryTotalsQuery query,
    ) {
      final TransactionType wanted = query.type.asTransactionType;
      final Map<String, double> totals = <String, double>{};

      for (final TransactionModel transaction in ref.watch(
        transactionsInRangeProvider(query.range),
      )) {
        if (transaction.type != wanted) continue;
        final String key = transaction.categoryId ?? '';
        totals[key] = (totals[key] ?? 0) + transaction.amount;
      }

      final List<MapEntry<String, double>> sorted = totals.entries.toList()
        ..sort(
          (MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value),
        );
      return <String, double>{
        for (final MapEntry<String, double> entry in sorted)
          entry.key: Validators.roundMoney(entry.value),
      };
    });

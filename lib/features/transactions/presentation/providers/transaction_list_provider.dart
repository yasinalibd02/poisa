import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/transaction_model.dart';
import 'transaction_providers.dart';

/// Everything the Transactions screen can narrow by.
@immutable
class TransactionFilters {
  const TransactionFilters({
    this.range,
    this.types = const <TransactionType>{},
    this.categoryIds = const <String>{},
    this.accountIds = const <String>{},
    this.minAmount,
    this.maxAmount,
    this.query = '',
  });

  final DateRange? range;
  final Set<TransactionType> types;
  final Set<String> categoryIds;
  final Set<String> accountIds;
  final double? minAmount;
  final double? maxAmount;

  /// Free text matched against the note and the category name in either
  /// language.
  final String query;

  bool get isEmpty =>
      range == null &&
      types.isEmpty &&
      categoryIds.isEmpty &&
      accountIds.isEmpty &&
      minAmount == null &&
      maxAmount == null &&
      query.trim().isEmpty;

  /// How many filter groups are active — shown as a badge on the filter button.
  int get activeCount {
    int count = 0;
    if (range != null) count++;
    if (types.isNotEmpty) count++;
    if (categoryIds.isNotEmpty) count++;
    if (accountIds.isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  TransactionFilters copyWith({
    DateRange? range,
    bool clearRange = false,
    Set<TransactionType>? types,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    double? minAmount,
    bool clearMin = false,
    double? maxAmount,
    bool clearMax = false,
    String? query,
  }) {
    return TransactionFilters(
      range: clearRange ? null : (range ?? this.range),
      types: types ?? this.types,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      minAmount: clearMin ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMax ? null : (maxAmount ?? this.maxAmount),
      query: query ?? this.query,
    );
  }
}

final NotifierProvider<TransactionFiltersController, TransactionFilters>
transactionFiltersProvider =
    NotifierProvider<TransactionFiltersController, TransactionFilters>(
      TransactionFiltersController.new,
    );

class TransactionFiltersController extends Notifier<TransactionFilters> {
  @override
  TransactionFilters build() => const TransactionFilters();

  void apply(TransactionFilters filters) {
    state = filters;
    ref.read(transactionPageProvider.notifier).reset();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    ref.read(transactionPageProvider.notifier).reset();
  }

  void clear() {
    state = TransactionFilters(query: state.query);
    ref.read(transactionPageProvider.notifier).reset();
  }

  void clearAll() {
    state = const TransactionFilters();
    ref.read(transactionPageProvider.notifier).reset();
  }
}

/// How many rows are currently rendered. The ledger is already in memory (one
/// Firestore listener), so "pagination" here means growing the render window
/// as the user scrolls rather than issuing more queries.
final NotifierProvider<TransactionPageController, int> transactionPageProvider =
    NotifierProvider<TransactionPageController, int>(
      TransactionPageController.new,
    );

class TransactionPageController extends Notifier<int> {
  static const int pageSize = 20;

  @override
  int build() => pageSize;

  void loadMore() => state = state + pageSize;

  void reset() {
    if (state != pageSize) state = pageSize;
  }
}

/// The ledger with every active filter applied, newest first.
final Provider<List<TransactionModel>> filteredTransactionsProvider =
    Provider<List<TransactionModel>>((Ref ref) {
      final List<TransactionModel> all =
          ref.watch(allTransactionsProvider).valueOrNull ??
          const <TransactionModel>[];
      final TransactionFilters filters = ref.watch(transactionFiltersProvider);
      if (filters.isEmpty) return all;

      final Map<String, CategoryModel> categories = ref.watch(
        categoryMapProvider,
      );
      final Map<String, AccountModel> accounts = ref.watch(accountMapProvider);
      final String query = filters.query.trim().toLowerCase();

      return all.where((TransactionModel t) {
        if (filters.range != null && !filters.range!.contains(t.date)) {
          return false;
        }
        if (filters.types.isNotEmpty && !filters.types.contains(t.type)) {
          return false;
        }
        if (filters.categoryIds.isNotEmpty &&
            !filters.categoryIds.contains(t.categoryId)) {
          return false;
        }
        if (filters.accountIds.isNotEmpty &&
            !filters.accountIds.contains(t.accountId) &&
            !filters.accountIds.contains(t.toAccountId)) {
          return false;
        }
        if (filters.minAmount != null && t.amount < filters.minAmount!) {
          return false;
        }
        if (filters.maxAmount != null && t.amount > filters.maxAmount!) {
          return false;
        }
        if (query.isNotEmpty) {
          final CategoryModel? category = categories[t.categoryId];
          final AccountModel? account = accounts[t.accountId];
          final bool matches =
              t.note.toLowerCase().contains(query) ||
              (category?.searchableText.contains(query) ?? false) ||
              (account?.name.toLowerCase().contains(query) ?? false);
          if (!matches) return false;
        }
        return true;
      }).toList(growable: false);
    });

/// One day's worth of rows plus that day's net subtotal.
@immutable
class DayGroup {
  const DayGroup({
    required this.day,
    required this.transactions,
    required this.subtotal,
  });

  final DateTime day;
  final List<TransactionModel> transactions;

  /// Income minus expense for the day; transfers do not move the needle.
  final double subtotal;
}

/// The visible window of filtered transactions, grouped by day.
final Provider<List<DayGroup>> transactionDayGroupsProvider =
    Provider<List<DayGroup>>((Ref ref) {
      final List<TransactionModel> filtered = ref.watch(
        filteredTransactionsProvider,
      );
      final int visible = ref.watch(transactionPageProvider);
      final List<TransactionModel> window = filtered
          .take(visible)
          .toList(growable: false);

      final List<DayGroup> groups = <DayGroup>[];
      DateTime? currentDay;
      List<TransactionModel> bucket = <TransactionModel>[];
      double subtotal = 0;

      void flush() {
        final DateTime? day = currentDay;
        if (day == null) return;
        groups.add(
          DayGroup(
            day: day,
            transactions: List<TransactionModel>.unmodifiable(bucket),
            subtotal: Validators.roundMoney(subtotal),
          ),
        );
      }

      for (final TransactionModel transaction in window) {
        final DateTime day = PeriodUtils.dayStart(transaction.date);
        if (currentDay == null || day != currentDay) {
          flush();
          currentDay = day;
          bucket = <TransactionModel>[];
          subtotal = 0;
        }
        bucket.add(transaction);
        if (!transaction.type.isTransfer) subtotal += transaction.signedAmount;
      }
      flush();

      return groups;
    });

/// True while more filtered rows exist beyond the render window.
final Provider<bool> hasMoreTransactionsProvider = Provider<bool>((Ref ref) {
  return ref.watch(filteredTransactionsProvider).length >
      ref.watch(transactionPageProvider);
});

/// Ids selected in multi-select mode. Empty means selection mode is off.
final NotifierProvider<TransactionSelectionController, Set<String>>
transactionSelectionProvider =
    NotifierProvider<TransactionSelectionController, Set<String>>(
      TransactionSelectionController.new,
    );

class TransactionSelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool get isActive => state.isNotEmpty;

  void toggle(String id) {
    final Set<String> next = <String>{...state};
    if (!next.remove(id)) next.add(id);
    state = next;
  }

  void clear() {
    if (state.isNotEmpty) state = const <String>{};
  }
}

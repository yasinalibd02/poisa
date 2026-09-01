import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// One slice of the breakdown: a category, its total, its share and how many
/// transactions made it up.
@immutable
class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.amount,
    required this.fraction,
    required this.count,
  });

  /// `null` when transactions reference a category that no longer exists.
  final CategoryModel? category;

  final double amount;
  final double fraction;
  final int count;

  String get colorHex =>
      category?.colorHex ?? AppColors.toHex(AppColors.textMutedLight);

  String get iconKey => category?.icon ?? 'category';
}

/// Category breakdown for a period and ledger side, largest first.
final ProviderFamily<List<CategoryShare>, CategoryTotalsQuery>
categorySharesProvider =
    Provider.family<List<CategoryShare>, CategoryTotalsQuery>((
      Ref ref,
      CategoryTotalsQuery query,
    ) {
      final Map<String, double> totals = ref.watch(
        categoryTotalsProvider(query),
      );
      if (totals.isEmpty) return const <CategoryShare>[];

      final Map<String, CategoryModel> categories = ref.watch(
        categoryMapProvider,
      );
      final TransactionType wanted = query.type.asTransactionType;

      final Map<String, int> counts = <String, int>{};
      for (final TransactionModel transaction in ref.watch(
        transactionsInRangeProvider(query.range),
      )) {
        if (transaction.type != wanted) continue;
        final String key = transaction.categoryId ?? '';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      final double sum = totals.values.fold<double>(
        0,
        (double acc, double value) => acc + value,
      );
      if (sum <= 0) return const <CategoryShare>[];

      return totals.entries
          .map(
            (MapEntry<String, double> entry) => CategoryShare(
              category: categories[entry.key],
              amount: entry.value,
              fraction: entry.value / sum,
              count: counts[entry.key] ?? 0,
            ),
          )
          .toList(growable: false);
    });

/// The Reports screen's period selection.
final NotifierProvider<ReportPeriodController, ReportPeriod>
reportPeriodProvider =
    NotifierProvider<ReportPeriodController, ReportPeriod>(
      ReportPeriodController.new,
    );

class ReportPeriodController extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.month;

  void set(ReportPeriod period) => state = period;
}

/// The custom range, set only when [ReportPeriod.custom] is active.
final NotifierProvider<CustomRangeController, DateRange?> customRangeProvider =
    NotifierProvider<CustomRangeController, DateRange?>(
      CustomRangeController.new,
    );

class CustomRangeController extends Notifier<DateRange?> {
  @override
  DateRange? build() => null;

  void set(DateRange range) {
    state = range;
    ref.read(reportPeriodProvider.notifier).set(ReportPeriod.custom);
  }
}

/// Whether Reports is showing the expense or income side.
final NotifierProvider<ReportSideController, CategoryType> reportSideProvider =
    NotifierProvider<ReportSideController, CategoryType>(
      ReportSideController.new,
    );

class ReportSideController extends Notifier<CategoryType> {
  @override
  CategoryType build() => CategoryType.expense;

  void set(CategoryType type) => state = type;

  void toggle() => state = state == CategoryType.expense
      ? CategoryType.income
      : CategoryType.expense;
}

/// The resolved date range for the current Reports selection.
final Provider<DateRange> reportRangeProvider = Provider<DateRange>((Ref ref) {
  final AppSettings settings = ref.watch(settingsProvider);
  return PeriodUtils.rangeFor(
    ref.watch(reportPeriodProvider),
    DateTime.now(),
    firstDayOfWeek: settings.firstDayOfWeek,
    firstDayOfMonth: settings.firstDayOfMonth,
    custom: ref.watch(customRangeProvider),
  );
});

/// Income and expense for one month, for the six-month comparison bars.
@immutable
class MonthlyTotals {
  const MonthlyTotals({
    required this.range,
    required this.income,
    required this.expense,
  });

  final DateRange range;
  final double income;
  final double expense;

  double get maxSide => income > expense ? income : expense;
}

/// The last six whole months, oldest first.
final Provider<List<MonthlyTotals>> monthlyComparisonProvider =
    Provider<List<MonthlyTotals>>((Ref ref) {
      final int firstDay = ref.watch(
        settingsProvider.select((AppSettings s) => s.firstDayOfMonth),
      );
      final List<DateRange> months = PeriodUtils.lastMonths(
        DateTime.now(),
        6,
        firstDayOfMonth: firstDay,
      );
      return months.map((DateRange range) {
        final MoneySummary summary = ref.watch(summaryForRangeProvider(range));
        return MonthlyTotals(
          range: range,
          income: summary.income,
          expense: summary.expense,
        );
      }).toList(growable: false);
    });

/// One day's total, for the trend line.
@immutable
class DailyPoint {
  const DailyPoint({required this.day, required this.amount});

  final DateTime day;
  final double amount;
}

/// Daily totals across the report range for the selected ledger side.
/// Days with no activity are included as zero, so the line reads as a real
/// timeline rather than a series of disconnected spikes.
final Provider<List<DailyPoint>> dailyTrendProvider = Provider<List<DailyPoint>>(
  (Ref ref) {
    final DateRange range = ref.watch(reportRangeProvider);
    final TransactionType wanted = ref
        .watch(reportSideProvider)
        .asTransactionType;

    final Map<DateTime, double> byDay = <DateTime, double>{};
    for (final TransactionModel transaction in ref.watch(
      transactionsInRangeProvider(range),
    )) {
      if (transaction.type != wanted) continue;
      final DateTime day = PeriodUtils.dayStart(transaction.date);
      byDay[day] = (byDay[day] ?? 0) + transaction.amount;
    }

    // A year's worth of daily points is unreadable on a phone; bucket by month
    // once the range gets long.
    final int days = range.dayCount;
    if (days > 92) {
      final Map<DateTime, double> byMonth = <DateTime, double>{};
      byDay.forEach((DateTime day, double amount) {
        final DateTime month = DateTime(day.year, day.month);
        byMonth[month] = (byMonth[month] ?? 0) + amount;
      });
      final List<DateTime> keys = byMonth.keys.toList()..sort();
      return keys
          .map(
            (DateTime month) => DailyPoint(
              day: month,
              amount: Validators.roundMoney(byMonth[month]!),
            ),
          )
          .toList(growable: false);
    }

    return List<DailyPoint>.generate(days, (int index) {
      final DateTime day = PeriodUtils.dayStart(
        range.start.add(Duration(days: index)),
      );
      return DailyPoint(
        day: day,
        amount: Validators.roundMoney(byDay[day] ?? 0),
      );
    });
  },
);

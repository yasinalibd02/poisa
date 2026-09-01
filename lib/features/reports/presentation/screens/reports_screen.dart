import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/report_providers.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/daily_trend_chart.dart';
import '../widgets/income_expense_bars.dart';

/// Statistics: a breakdown donut, six-month comparison bars, a trend line and
/// a ranked category list — all for the selected period and ledger side.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TransactionModel>> ledger = ref.watch(
      allTransactionsProvider,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(context.l10n.reports)),
      body: ledger.when(
        loading: () => const _ReportsSkeleton(),
        error: (Object error, _) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(allTransactionsProvider),
        ),
        data: (_) => const _ReportsBody(),
      ),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReportPeriod period = ref.watch(reportPeriodProvider);
    final CategoryType side = ref.watch(reportSideProvider);
    final DateRange range = ref.watch(reportRangeProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final DateLabels dates = ref.watch(dateLabelsProvider);
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );

    final List<CategoryShare> shares = ref.watch(
      categorySharesProvider(CategoryTotalsQuery(range, side)),
    );
    final double total = shares.fold<double>(
      0,
      (double sum, CategoryShare share) => sum + share.amount,
    );
    final Color sideColor = side == CategoryType.expense
        ? AppColors.expense
        : AppColors.income;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        96,
      ),
      children: <Widget>[
        _PeriodChips(
          selected: period,
          onSelected: (ReportPeriod value) async {
            if (value == ReportPeriod.custom) {
              await _pickCustomRange(context, ref);
            } else {
              ref.read(reportPeriodProvider.notifier).set(value);
            }
          },
        ),
        AppSizes.gapMd,
        Text(
          money.localizeDigits(dates.rangeLabel(range)),
          style: context.texts.bodySmall,
        ),
        AppSizes.gapLg,
        SegmentedTabs<CategoryType>(
          values: const <CategoryType>[
            CategoryType.expense,
            CategoryType.income,
          ],
          labels: <String>[context.l10n.expense, context.l10n.income],
          activeColors: const <Color>[AppColors.expense, AppColors.income],
          selected: side,
          onChanged: ref.read(reportSideProvider.notifier).set,
        ),
        AppSizes.gapXl,

        if (shares.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
            child: EmptyStateView(
              icon: Icons.insights_rounded,
              title: context.l10n.noDataForPeriod,
              message: context.l10n.noDataForPeriodBody,
              compact: true,
            ),
          )
        else ...<Widget>[
          KoriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  side == CategoryType.expense
                      ? context.l10n.expenseBreakdown
                      : context.l10n.incomeBreakdown,
                  style: context.texts.titleSmall,
                ),
                AppSizes.gapLg,
                Center(
                  child: CategoryDonutChart(
                    shares: shares,
                    centerLabel: money.compact(total),
                    centerSubLabel: side == CategoryType.expense
                        ? context.l10n.expense
                        : context.l10n.income,
                    size: 196,
                  ),
                ),
                AppSizes.gapXl,
                DonutLegend(
                  shares: shares,
                  maxItems: 6,
                  labelFor: (CategoryShare share) =>
                      share.category?.displayName(language) ??
                      context.l10n.unknownCategory,
                  amountFor: (CategoryShare share) =>
                      money.format(share.amount),
                  percentFor: (CategoryShare share) =>
                      money.percent(share.fraction),
                ),
              ],
            ),
          ),
          AppSizes.gapLg,
        ],

        KoriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.incomeVsExpense,
                style: context.texts.titleSmall,
              ),
              AppSizes.gapXs,
              Text(context.l10n.lastSixMonths, style: context.texts.bodySmall),
              AppSizes.gapLg,
              IncomeExpenseBars(
                months: ref.watch(monthlyComparisonProvider),
                monthLabel: (MonthlyTotals m) => dates.monthShort(m.range.start),
                compactAmount: money.compact,
              ),
              AppSizes.gapLg,
              ChartLegend(
                entries: <({Color color, String label})>[
                  (color: AppColors.income, label: context.l10n.income),
                  (color: AppColors.expense, label: context.l10n.expense),
                ],
              ),
            ],
          ),
        ),
        AppSizes.gapLg,

        KoriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(context.l10n.dailyTrend, style: context.texts.titleSmall),
              AppSizes.gapLg,
              DailyTrendChart(
                points: ref.watch(dailyTrendProvider),
                color: sideColor,
                compactAmount: money.compact,
                pointLabel: (DailyPoint point) => money.localizeDigits(
                  range.dayCount > 92
                      ? dates.monthShort(point.day)
                      : '${point.day.day}',
                ),
              ),
            ],
          ),
        ),

        if (shares.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: context.l10n.categoryRanking,
            padding: const EdgeInsets.fromLTRB(0, AppSizes.xl, 0, AppSizes.md),
          ),
          for (final CategoryShare share in shares)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: _RankRow(
                share: share,
                label: share.category?.displayName(language) ??
                    context.l10n.unknownCategory,
                amount: money.format(share.amount),
                percent: money.percent(share.fraction),
                count: money.localizeDigits(
                  context.l10n.transactionCount(share.count),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    ref
        .read(customRangeProvider.notifier)
        .set(
          DateRange(
            PeriodUtils.dayStart(picked.start),
            PeriodUtils.dayStart(picked.end).add(const Duration(days: 1)),
          ),
        );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.selected, required this.onSelected});

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final ReportPeriod period in ReportPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.sm),
              child: ChoiceChip(
                selected: selected == period,
                label: Text(_label(context, period)),
                onSelected: (_) => onSelected(period),
              ),
            ),
        ],
      ),
    );
  }

  String _label(BuildContext context, ReportPeriod period) => switch (period) {
    ReportPeriod.week => context.l10n.periodWeek,
    ReportPeriod.month => context.l10n.periodMonth,
    ReportPeriod.year => context.l10n.periodYear,
    ReportPeriod.custom => context.l10n.periodCustom,
  };
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.share,
    required this.label,
    required this.amount,
    required this.percent,
    required this.count,
  });

  final CategoryShare share;
  final String label;
  final String amount;
  final String percent;
  final String count;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.fromHex(share.colorHex);
    return KoriCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: <Widget>[
          IconBadge(
            iconKey: share.iconKey,
            colorHex: share.colorHex,
            size: 40,
          ),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.fraction.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: context.colors.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(count, style: context.texts.bodySmall),
              ],
            ),
          ),
          AppSizes.hGapMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                amount,
                style: context.texts.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(percent, style: context.texts.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ShimmerBox(height: 34, width: 240, radius: AppSizes.radiusPill),
          AppSizes.gapXl,
          CardSkeleton(height: 300),
          AppSizes.gapLg,
          CardSkeleton(height: 220),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// The month's income and expense side by side, with a compact six-bar history
/// and a period switch in the header.
class IncomeExpenseCard extends ConsumerStatefulWidget {
  const IncomeExpenseCard({super.key});

  @override
  ConsumerState<IncomeExpenseCard> createState() => _IncomeExpenseCardState();
}

enum _Period { thisMonth, lastMonth }

class _IncomeExpenseCardState extends ConsumerState<IncomeExpenseCard> {
  _Period _period = _Period.thisMonth;

  @override
  Widget build(BuildContext context) {
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final int firstDay = ref.watch(
      settingsProvider.select((AppSettings s) => s.firstDayOfMonth),
    );

    final DateTime anchor = _period == _Period.thisMonth
        ? DateTime.now()
        : PeriodUtils.addMonths(DateTime.now(), -1);
    final DateRange range = PeriodUtils.monthRange(
      anchor,
      firstDayOfMonth: firstDay,
    );
    final MoneySummary summary = ref.watch(summaryForRangeProvider(range));
    final List<MonthlyTotals> history = ref
        .watch(monthlyComparisonProvider)
        .reversed
        .take(4)
        .toList()
        .reversed
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.xl,
            AppSizes.screenPadding,
            AppSizes.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.incomeVsExpense,
                  style: context.texts.titleMedium,
                ),
              ),
              _PeriodDropdown(
                value: _period,
                onChanged: (_Period next) => setState(() => _period = next),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: KoriCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _Figure(
                        label: context.l10n.income,
                        value: money.format(summary.income),
                        color: AppColors.income,
                      ),
                      AppSizes.gapLg,
                      _Figure(
                        label: context.l10n.expense,
                        value: money.format(summary.expense),
                        color: AppColors.expense,
                      ),
                    ],
                  ),
                ),
                AppSizes.hGapLg,
                _MiniBars(months: history),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: context.texts.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: context.texts.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({required this.value, required this.onChanged});

  final _Period value;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final String label = value == _Period.thisMonth
        ? context.l10n.thisMonth
        : context.l10n.lastMonth;

    return PopupMenuButton<_Period>(
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      shape: const RoundedRectangleBorder(borderRadius: AppSizes.brMd),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_Period>>[
        PopupMenuItem<_Period>(
          value: _Period.thisMonth,
          child: Text(context.l10n.thisMonth),
        ),
        PopupMenuItem<_Period>(
          value: _Period.lastMonth,
          child: Text(context.l10n.lastMonth),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.sm, AppSizes.sm),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: context.texts.labelMedium),
            Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped income/expense bars — a small echo of the Reports chart.
class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.months});

  final List<MonthlyTotals> months;

  static const double _height = 96;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const SizedBox.shrink();

    final double maxSide = months.fold<double>(
      0,
      (double max, MonthlyTotals m) => m.maxSide > max ? m.maxSide : max,
    );
    final double ceiling = maxSide <= 0 ? 1 : maxSide;

    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final MonthlyTotals m in months)
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _Bar(
                    fraction: m.income / ceiling,
                    color: AppColors.income,
                    maxHeight: _height,
                  ),
                  const SizedBox(width: 3),
                  _Bar(
                    fraction: m.expense / ceiling,
                    color: AppColors.expense,
                    maxHeight: _height,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.maxHeight,
  });

  final double fraction;
  final Color color;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final double f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: f),
      duration: AppSizes.slow,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, _) => Container(
        width: 8,
        height: (maxHeight * value).clamp(3.0, maxHeight),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}

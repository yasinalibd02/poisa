import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../reports/presentation/widgets/category_donut_chart.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/dashboard_providers.dart';

/// This month's expense breakdown: a donut with the category legend beside it.
class SpendingDonutCard extends ConsumerWidget {
  const SpendingDonutCard({super.key});

  /// Categories shown by name before the rest collapse into "Others".
  static const int _namedRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateRange range = ref.watch(selectedMonthRangeProvider);
    final List<CategoryShare> shares = ref.watch(
      categorySharesProvider(
        CategoryTotalsQuery(range, CategoryType.expense),
      ),
    );
    if (shares.isEmpty) return const SizedBox.shrink();

    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );
    final double total = shares.fold<double>(
      0,
      (double sum, CategoryShare share) => sum + share.amount,
    );

    final List<_LegendRow> rows = _legendRows(context, shares, language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: context.l10n.spendingOverview),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: KoriCard(
            onTap: () => context.go(AppRoutes.reports),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget donut = CategoryDonutChart(
                  shares: shares,
                  centerLabel: money.format(total),
                  centerSubLabel: context.l10n.totalExpense,
                  size: 164,
                  onTap: () => context.go(AppRoutes.reports),
                );
                final Widget legend = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final _LegendRow row in rows) _LegendTile(row: row),
                  ],
                );

                if (constraints.maxWidth < 340) {
                  return Column(
                    children: <Widget>[donut, AppSizes.gapLg, legend],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    donut,
                    AppSizes.hGapLg,
                    Expanded(child: legend),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<_LegendRow> _legendRows(
    BuildContext context,
    List<CategoryShare> shares,
    String language,
  ) {
    final List<_LegendRow> rows = <_LegendRow>[
      for (final CategoryShare share in shares.take(_namedRows))
        _LegendRow(
          color: AppColors.fromHex(share.colorHex),
          label:
              share.category?.displayName(language) ??
              context.l10n.unknownCategory,
          amount: share.amount,
        ),
    ];
    if (shares.length > _namedRows) {
      final double othersTotal = shares
          .skip(_namedRows)
          .fold<double>(0, (double sum, CategoryShare s) => sum + s.amount);
      rows.add(
        _LegendRow(
          color: AppColors.textMutedLight,
          label: context.l10n.othersCategory,
          amount: othersTotal,
        ),
      );
    }
    return rows;
  }
}

class _LegendRow {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
  });

  final Color color;
  final String label;
  final double amount;
}

class _LegendTile extends ConsumerWidget {
  const _LegendTile({required this.row});

  final _LegendRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: row.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          AppSizes.hGapSm,
          Expanded(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium,
            ),
          ),
          AppSizes.hGapSm,
          Text(
            money.format(row.amount),
            style: context.texts.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

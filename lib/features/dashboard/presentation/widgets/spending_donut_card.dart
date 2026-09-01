import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
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

/// This month's expense breakdown as a compact donut. Tapping opens Reports.
class SpendingDonutCard extends ConsumerWidget {
  const SpendingDonutCard({super.key});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: context.l10n.spendingByCategory,
          actionLabel: context.l10n.actionSeeAll,
          onAction: () => context.go(AppRoutes.reports),
        ),
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
                  centerLabel: money.compact(total),
                  centerSubLabel: context.l10n.expense,
                  size: 148,
                  onTap: () => context.go(AppRoutes.reports),
                );
                final Widget legend = DonutLegend(
                  shares: shares,
                  labelFor: (CategoryShare share) =>
                      share.category?.displayName(language) ??
                      context.l10n.unknownCategory,
                  amountFor: (CategoryShare share) =>
                      money.format(share.amount),
                  percentFor: (CategoryShare share) =>
                      money.percent(share.fraction),
                );

                // Stack the legend under the donut on narrow phones, where a
                // side-by-side layout would squeeze category names to nothing.
                if (constraints.maxWidth < 340) {
                  return Column(
                    children: <Widget>[
                      donut,
                      AppSizes.gapLg,
                      legend,
                    ],
                  );
                }
                return Row(
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
}

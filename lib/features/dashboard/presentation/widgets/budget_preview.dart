import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// The three most pressing budgets for the selected month.
class BudgetPreview extends ConsumerWidget {
  const BudgetPreview({super.key});

  static const int _maxRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<BudgetProgress> budgets = ref.watch(
      selectedMonthBudgetsProvider,
    );
    if (budgets.isEmpty) return const SizedBox.shrink();

    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: context.l10n.budgets,
          actionLabel: context.l10n.actionSeeAll,
          onAction: () => context.push(AppRoutes.budget),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: KoriCard(
            onTap: () => context.push(AppRoutes.budget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.sm,
            ),
            child: Column(
              children: <Widget>[
                for (final BudgetProgress budget
                    in budgets.take(_maxRows))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.md,
                    ),
                    child: _BudgetRow(
                      progress: budget,
                      label: budget.budget.isOverall
                          ? context.l10n.overallBudgetShort
                          : budget.category?.displayName(language) ??
                                context.l10n.unknownCategory,
                      money: money,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.progress,
    required this.label,
    required this.money,
  });

  final BudgetProgress progress;
  final String label;
  final MoneyFormatter money;

  @override
  Widget build(BuildContext context) {
    final bool over = progress.isOverBudget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall,
              ),
            ),
            AppSizes.hGapSm,
            Text(
              over
                  ? context.l10n.overBudgetBy(money.format(progress.overBy))
                  : context.l10n.remaining(money.format(progress.remaining)),
              style: context.texts.labelMedium?.copyWith(
                color: over
                    ? context.colors.error
                    : context.colors.onSurfaceVariant,
                fontWeight: over ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
        AppSizes.gapSm,
        BudgetProgressBar(progress: progress.progress),
        AppSizes.gapXs,
        Text(
          context.l10n.spentOfLimit(
            money.format(progress.spent),
            money.format(progress.limit),
          ),
          style: context.texts.bodySmall,
        ),
      ],
    );
  }
}

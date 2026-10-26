import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/month_selector.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/budget_model.dart';
import '../providers/budget_providers.dart';
import '../widgets/budget_editor_sheet.dart';

/// Monthly budgets with live spend, ordered by how close each is to its limit.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BudgetModel>> budgets = ref.watch(
      budgetsStreamProvider,
    );
    final List<BudgetProgress> progress = ref.watch(
      selectedMonthBudgetsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.budgets),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.copyLastMonth,
            onPressed: () => _copyLastMonth(context, ref),
            icon: const Icon(CupertinoIcons.doc_on_doc),
          ),
          AppSizes.hGapXs,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBudgetEditor(context),
        icon: const Icon(CupertinoIcons.add),
        label: Text(context.l10n.newBudget),
      ),
      body: Column(
        children: <Widget>[
          AppSizes.gapSm,
          const MonthSelector(),
          AppSizes.gapMd,
          Expanded(
            child: budgets.when(
              loading: () => const ListSkeleton(rows: 4),
              error: (Object error, _) => ErrorStateView(
                error: error,
                onRetry: () => ref.invalidate(budgetsStreamProvider),
              ),
              data: (_) => progress.isEmpty
                  ? EmptyStateView(
                      icon: CupertinoIcons.flag_fill,
                      title: context.l10n.noBudgetsTitle,
                      message: context.l10n.noBudgetsBody,
                      actionLabel: context.l10n.newBudget,
                      onAction: () => showBudgetEditor(context),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.screenPadding,
                        AppSizes.sm,
                        AppSizes.screenPadding,
                        96,
                      ),
                      itemCount: progress.length,
                      separatorBuilder:
                          (BuildContext context, int index) => AppSizes.gapMd,
                      itemBuilder: (BuildContext context, int index) =>
                          _BudgetCard(progress: progress[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pulls the previous month's budgets forward, skipping any category that
  /// already has one this month.
  Future<void> _copyLastMonth(BuildContext context, WidgetRef ref) async {
    final DateRange current = ref.read(selectedMonthRangeProvider);
    final DateTime previous = PeriodUtils.addMonths(current.start, -1);

    try {
      final int copied = await ref
          .read(budgetRepositoryProvider)
          .copyMonth(
            fromYear: previous.year,
            fromMonth: previous.month,
            toYear: current.start.year,
            toMonth: current.start.month,
          );
      if (!context.mounted) return;
      AppSnack.success(context, context.l10n.budgetsCopied(copied));
    } catch (error) {
      if (!context.mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );
    final bool over = progress.isOverBudget;
    final String label = progress.budget.isOverall
        ? context.l10n.overallBudget
        : progress.category?.displayName(language) ??
              context.l10n.unknownCategory;

    return KoriCard(
      onTap: () => showBudgetEditor(context, existing: progress.budget),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconBadge(
                iconKey: progress.budget.isOverall
                    ? 'savings'
                    : progress.category?.icon ?? 'category',
                colorHex: progress.budget.isOverall
                    ? '#1B7F6B'
                    : progress.category?.colorHex ?? '#6B7A87',
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
                    const SizedBox(height: 2),
                    Text(
                      money.localizeDigits(
                        context.l10n.daysLeft(progress.daysLeft),
                      ),
                      style: context.texts.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.actionDelete,
                onPressed: () => _confirmDelete(context, ref),
                icon: Icon(
                  CupertinoIcons.trash,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSizes.gapMd,
          BudgetProgressBar(progress: progress.progress, height: 10),
          AppSizes.gapMd,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.spentOfLimit(
                    money.format(progress.spent),
                    money.format(progress.limit),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium,
                ),
              ),
              AppSizes.hGapSm,
              Text(
                over
                    ? context.l10n.overBudgetBy(money.format(progress.overBy))
                    : context.l10n.remaining(money.format(progress.remaining)),
                style: context.texts.labelLarge?.copyWith(
                  color: over
                      ? context.colors.error
                      : BudgetProgressBar.colorFor(progress.progress),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: context.l10n.deleteBudgetTitle,
      message: context.l10n.deleteBudgetBody,
      confirmLabel: context.l10n.actionDelete,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(budgetRepositoryProvider).delete(progress.budget.id);
      if (!context.mounted) return;
      AppSnack.success(context, context.l10n.budgetDeleted);
    } catch (error) {
      if (!context.mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }
}

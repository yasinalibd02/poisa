import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/dismissible_transaction.dart';
import '../widgets/account_cards.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_preview.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/month_selector.dart';
import '../widgets/spending_donut_card.dart';

/// Home. Everything here is derived from the single ledger stream, so it is
/// correct and instant offline.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const int _recentCount = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TransactionModel>> ledger = ref.watch(
      allTransactionsProvider,
    );

    return ledger.when(
      loading: () => const _DashboardSkeleton(),
      error: (Object error, _) => Column(
        children: <Widget>[
          const DashboardAppBar(),
          Expanded(
            child: ErrorStateView(
              error: error,
              onRetry: () => ref.invalidate(allTransactionsProvider),
            ),
          ),
        ],
      ),
      data: (List<TransactionModel> all) => _DashboardBody(all: all),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.all});

  final List<TransactionModel> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TransactionModel> recent = all
        .take(DashboardScreen._recentCount)
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allTransactionsProvider);
        await ref.read(allTransactionsProvider.future);
      },
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(child: DashboardAppBar()),
          const SliverToBoxAdapter(child: AppSizes.gapSm),
          const SliverToBoxAdapter(child: MonthSelector()),
          const SliverToBoxAdapter(child: AppSizes.gapLg),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            sliver: SliverToBoxAdapter(child: BalanceCard()),
          ),
          const SliverToBoxAdapter(child: AppSizes.gapXl),
          const SliverToBoxAdapter(child: AccountCardsRow()),
          const SliverToBoxAdapter(child: SpendingDonutCard()),
          const SliverToBoxAdapter(child: BudgetPreview()),

          if (all.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSizes.xl),
                child: EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: context.l10n.noTransactionsTitle,
                  message: context.l10n.noTransactionsBody,
                  actionLabel: context.l10n.addTransaction,
                  onAction: () => context.push(AppRoutes.transactionNew),
                ),
              ),
            )
          else ...<Widget>[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: context.l10n.recentTransactions,
                actionLabel: context.l10n.actionSeeAll,
                onAction: () => context.go(AppRoutes.transactions),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
              ),
              sliver: SliverList.builder(
                itemCount: recent.length,
                itemBuilder: (BuildContext context, int index) {
                  final TransactionModel transaction = recent[index];
                  return DismissibleTransaction(
                    key: ValueKey<String>(transaction.id),
                    transaction: transaction,
                    onTap: () => context.push(
                      AppRoutes.transactionEdit,
                      extra: transaction,
                    ),
                  );
                },
              ),
            ),
          ],

          // Clears the docked FAB and bottom bar.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSizes.gapLg,
          ShimmerBox(height: 24, width: 200),
          AppSizes.gapXl,
          CardSkeleton(height: 168),
          AppSizes.gapXl,
          CardSkeleton(height: 104),
          AppSizes.gapXl,
          ShimmerBox(height: 20, width: 160),
          AppSizes.gapLg,
          ListSkeleton(rows: 5, padding: EdgeInsets.zero),
        ],
      ),
    );
  }
}

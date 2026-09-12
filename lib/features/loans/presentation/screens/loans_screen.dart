import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/widgets/dismissible_transaction.dart';
import '../providers/loan_providers.dart';

/// The lending ledger in one place: what you are still owed, what you still
/// owe, and every transaction behind both figures.
///
/// Nothing is stored separately for it — a loan is an ordinary transaction
/// filed under one of the four seeded lending categories, so balances, reports
/// and the CSV/PDF export all stay consistent with it for free.
class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoanLedger ledger = ref.watch(loanLedgerProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loans)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.transactionNew),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.addTransaction),
      ),
      body: ledger.isEmpty
          ? EmptyStateView(
              icon: Icons.handshake_rounded,
              title: context.l10n.noLoansTitle,
              message: context.l10n.noLoansBody,
              actionLabel: context.l10n.addTransaction,
              onAction: () => context.push(AppRoutes.transactionNew),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, AppSizes.md, 0, 96),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                  ),
                  child: _PositionCard(ledger: ledger, money: money),
                ),
                SectionHeader(title: context.l10n.loansBreakdown),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                  ),
                  child: KoriCard(
                    child: Column(
                      children: <Widget>[
                        _BreakdownRow(
                          label: context.l10n.loanGivenTotal,
                          value: money.format(ledger.given),
                          type: TransactionType.expense,
                        ),
                        const Divider(height: AppSizes.xl),
                        _BreakdownRow(
                          label: context.l10n.loanRecoveredTotal,
                          value: money.format(ledger.recovered),
                          type: TransactionType.income,
                        ),
                        const Divider(height: AppSizes.xl),
                        _BreakdownRow(
                          label: context.l10n.loanTakenTotal,
                          value: money.format(ledger.taken),
                          type: TransactionType.income,
                        ),
                        const Divider(height: AppSizes.xl),
                        _BreakdownRow(
                          label: context.l10n.loanRepaidTotal,
                          value: money.format(ledger.repaid),
                          type: TransactionType.expense,
                        ),
                      ],
                    ),
                  ),
                ),
                SectionHeader(title: context.l10n.loanHistory),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                  ),
                  child: Column(
                    children: <Widget>[
                      for (final TransactionModel transaction
                          in ledger.transactions)
                        DismissibleTransaction(
                          key: ValueKey<String>('loan-${transaction.id}'),
                          transaction: transaction,
                          showTime: false,
                          onTap: () => context.push(
                            AppRoutes.transactionEdit,
                            extra: transaction,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// The two numbers the screen exists for, side by side, with the net position
/// underneath so a glance answers "am I up or down overall".
class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.ledger, required this.money});

  final LoanLedger ledger;
  final MoneyFormatter money;

  @override
  Widget build(BuildContext context) {
    final double net = ledger.net;
    final bool upDown = net >= 0;

    return KoriCard(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _Position(
                  icon: Icons.call_received_rounded,
                  label: context.l10n.loansReceivable,
                  value: money.format(ledger.receivable),
                  color: AppColors.income,
                ),
              ),
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                color: context.colors.outlineVariant,
              ),
              Expanded(
                child: _Position(
                  icon: Icons.call_made_rounded,
                  label: context.l10n.loansPayable,
                  value: money.format(ledger.payable),
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          AppSizes.gapLg,
          const Divider(height: 1),
          AppSizes.gapLg,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.loansNet,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppSizes.hGapSm,
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    money.formatSigned(net),
                    style: context.texts.titleMedium?.copyWith(
                      color: upDown ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSizes.gapXs,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              upDown ? context.l10n.loansNetUp : context.l10n.loansNetDown,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Position extends StatelessWidget {
  const _Position({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 15, color: color),
            AppSizes.hGapXs,
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySmall,
              ),
            ),
          ],
        ),
        AppSizes.gapXs,
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

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.type,
  });

  final String label;
  final String value;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: context.texts.bodyMedium)),
        AppSizes.hGapSm,
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: AmountText(text: value, type: type),
          ),
        ),
      ],
    );
  }
}

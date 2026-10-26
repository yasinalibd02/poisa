import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../categories/presentation/widgets/move_target_sheet.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/account_model.dart';
import '../providers/account_providers.dart';
import '../widgets/account_editor_sheet.dart';
import '../widgets/account_type_label.dart';

/// Wallets: net worth at the top, then every account with its live balance.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AccountModel>> accounts = ref.watch(
      accountsStreamProvider,
    );
    final Map<String, double> balances = ref.watch(accountBalancesProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.manageAccounts),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.showArchived,
            isSelected: _showArchived,
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: const Icon(CupertinoIcons.archivebox),
            selectedIcon: const Icon(CupertinoIcons.archivebox_fill),
          ),
          AppSizes.hGapXs,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountEditor(context),
        icon: const Icon(CupertinoIcons.add),
        label: Text(context.l10n.newAccount),
      ),
      body: accounts.when(
        loading: () => const ListSkeleton(rows: 5),
        error: (Object error, _) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(accountsStreamProvider),
        ),
        data: (List<AccountModel> all) {
          final List<AccountModel> visible = all
              .where((AccountModel a) => _showArchived || !a.isArchived)
              .toList(growable: false);

          if (visible.isEmpty) {
            return EmptyStateView(
              icon: CupertinoIcons.creditcard_fill,
              title: context.l10n.noAccountsTitle,
              message: context.l10n.noAccountsBody,
              actionLabel: context.l10n.newAccount,
              onAction: () => showAccountEditor(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.lg,
              AppSizes.screenPadding,
              96,
            ),
            children: <Widget>[
              _NetWorthCard(value: money.format(ref.watch(netWorthProvider))),
              AppSizes.gapXl,
              for (final AccountModel account in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: _AccountRow(
                    account: account,
                    balance: money.format(
                      balances[account.id] ?? account.openingBalance,
                    ),
                    onEdit: () =>
                        showAccountEditor(context, existing: account),
                    onArchiveToggle: () => _toggleArchive(account),
                    onDelete: () => _startDeleteFlow(account, all),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleArchive(AccountModel account) async {
    try {
      await ref
          .read(accountRepositoryProvider)
          .setArchived(account.id, !account.isArchived);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }

  /// Deleting an account that still has transactions would orphan them, so the
  /// user moves them to another account first. The last account cannot go at
  /// all — every transaction needs somewhere to live.
  Future<void> _startDeleteFlow(
    AccountModel account,
    List<AccountModel> all,
  ) async {
    if (all.length <= 1) {
      AppSnack.show(context, context.l10n.lastAccountCannotDelete);
      return;
    }

    final int count = await ref
        .read(transactionRepositoryProvider)
        .countForAccount(account.id);
    if (!mounted) return;

    if (count == 0) {
      final bool confirmed = await showConfirmDialog(
        context,
        title: context.l10n.deleteAccountTitle,
        message: context.l10n.deleteAccountBody(account.name),
        confirmLabel: context.l10n.actionDelete,
      );
      if (!confirmed || !mounted) return;
      await _delete(account);
      return;
    }

    final List<AccountModel> alternatives = all
        .where((AccountModel a) => a.id != account.id)
        .toList(growable: false);

    final String? targetId = await showMoveTargetSheet(
      context,
      title: context.l10n.accountInUseTitle,
      message: context.l10n.accountInUseBody(count),
      pickerLabel: context.l10n.moveTransactionsToAccount,
      confirmLabel: context.l10n.moveAndDelete,
      options: alternatives
          .map(
            (AccountModel a) => MoveTarget(
              id: a.id,
              label: a.name,
              iconKey: a.icon,
              colorHex: a.colorHex,
            ),
          )
          .toList(growable: false),
    );
    if (targetId == null || !mounted) return;

    try {
      await ref
          .read(transactionRepositoryProvider)
          .reassignAccount(fromAccountId: account.id, toAccountId: targetId);
      await _delete(account);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }

  Future<void> _delete(AccountModel account) async {
    try {
      await ref.read(accountRepositoryProvider).delete(account.id);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.accountDeleted);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: const BoxDecoration(
        borderRadius: AppSizes.brLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.netWorth,
            style: context.texts.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          AppSizes.gapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: context.texts.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.balance,
    required this.onEdit,
    required this.onArchiveToggle,
    required this.onDelete,
  });

  final AccountModel account;
  final String balance;
  final VoidCallback onEdit;
  final VoidCallback onArchiveToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return KoriCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
      ),
      child: Row(
        children: <Widget>[
          IconBadge(iconKey: account.icon, colorHex: account.colorHex),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall,
                      ),
                    ),
                    if (account.isArchived) ...<Widget>[
                      AppSizes.hGapSm,
                      _ArchivedTag(label: context.l10n.archived),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  accountTypeLabel(context, account.type),
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          AppSizes.hGapSm,
          Text(
            balance,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          PopupMenuButton<_AccountAction>(
            icon: const Icon(CupertinoIcons.ellipsis_vertical),
            onSelected: (_AccountAction action) => switch (action) {
              _AccountAction.edit => onEdit(),
              _AccountAction.archive => onArchiveToggle(),
              _AccountAction.delete => onDelete(),
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_AccountAction>>[
                  PopupMenuItem<_AccountAction>(
                    value: _AccountAction.edit,
                    child: Text(context.l10n.actionEdit),
                  ),
                  PopupMenuItem<_AccountAction>(
                    value: _AccountAction.archive,
                    child: Text(
                      account.isArchived
                          ? context.l10n.unarchive
                          : context.l10n.archive,
                    ),
                  ),
                  PopupMenuItem<_AccountAction>(
                    value: _AccountAction.delete,
                    child: Text(
                      context.l10n.actionDelete,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}

enum _AccountAction { edit, archive, delete }

class _ArchivedTag extends StatelessWidget {
  const _ArchivedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.outlineVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(label, style: context.texts.labelSmall),
    );
  }
}

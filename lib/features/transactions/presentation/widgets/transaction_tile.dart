import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/transaction_model.dart';

/// One row in any transaction list. Shows the category icon, a title, the
/// note/account line and the signed amount.
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    this.showTime = false,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;
  final bool showTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final DateLabels dates = ref.watch(dateLabelsProvider);
    final Map<String, CategoryModel> categories = ref.watch(categoryMapProvider);
    final Map<String, AccountModel> accounts = ref.watch(accountMapProvider);

    final CategoryModel? category = transaction.categoryId == null
        ? null
        : categories[transaction.categoryId];
    final AccountModel? account = accounts[transaction.accountId];
    final AccountModel? toAccount = transaction.toAccountId == null
        ? null
        : accounts[transaction.toAccountId];

    final String title = transaction.type.isTransfer
        ? context.l10n.transfer
        : category?.displayName(language) ?? context.l10n.unknownCategory;

    final String subtitle = _subtitle(context, account, toAccount);

    return Material(
      color: selected
          ? context.colors.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: AppSizes.brMd,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppSizes.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.md,
          ),
          child: Row(
            children: <Widget>[
              _Leading(
                selectionMode: selectionMode,
                selected: selected,
                transaction: transaction,
                category: category,
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall,
                    ),
                    if (subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              AppSizes.hGapSm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  AmountText(
                    text: transaction.type.isTransfer
                        ? money.format(transaction.amount)
                        : money.formatSigned(transaction.signedAmount),
                    type: transaction.type,
                  ),
                  if (showTime) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      money.localizeDigits(dates.time(transaction.date)),
                      style: context.texts.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Note first — it is what the user actually wrote — then the account, or
  /// the two accounts for a transfer.
  String _subtitle(
    BuildContext context,
    AccountModel? account,
    AccountModel? toAccount,
  ) {
    final String note = transaction.note.trim();
    if (transaction.type.isTransfer) {
      final String from = account?.name ?? context.l10n.unknownAccount;
      final String to = toAccount?.name ?? context.l10n.unknownAccount;
      final String route = '$from → $to';
      return note.isEmpty ? route : '$note · $route';
    }
    final String accountName = account?.name ?? '';
    if (note.isEmpty) return accountName;
    if (accountName.isEmpty) return note;
    return '$note · $accountName';
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.selectionMode,
    required this.selected,
    required this.transaction,
    required this.category,
  });

  final bool selectionMode;
  final bool selected;
  final TransactionModel transaction;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context) {
    if (selectionMode) {
      return SizedBox.square(
        dimension: 44,
        child: Center(
          child: AnimatedContainer(
            duration: AppSizes.fast,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? context.colors.primary : Colors.transparent,
              border: Border.all(
                color: selected
                    ? context.colors.primary
                    : context.colors.outlineVariant,
                width: 2,
              ),
            ),
            child: selected
                ? Icon(
                    CupertinoIcons.checkmark,
                    size: 16,
                    color: context.colors.onPrimary,
                  )
                : null,
          ),
        ),
      );
    }

    if (transaction.type.isTransfer) {
      return IconBadge(
        iconKey: 'refund',
        colorHex: AppColors.toHex(AppColors.transfer),
      );
    }

    return IconBadge(
      iconKey: category?.icon ?? 'category',
      colorHex:
          category?.colorHex ??
          AppColors.toHex(
            transaction.type == TransactionType.income
                ? AppColors.income
                : AppColors.expense,
          ),
    );
  }
}

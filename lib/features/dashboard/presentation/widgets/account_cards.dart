import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Horizontally scrolling wallet cards with each account's live balance.
class AccountCardsRow extends ConsumerWidget {
  const AccountCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AccountModel> accounts = ref.watch(activeAccountsProvider);
    final Map<String, double> balances = ref.watch(accountBalancesProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);

    if (accounts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        itemCount: accounts.length + 1,
        separatorBuilder: (BuildContext context, int index) => AppSizes.hGapMd,
        itemBuilder: (BuildContext context, int index) {
          if (index == accounts.length) {
            return _ManageCard(onTap: () => context.push(AppRoutes.accounts));
          }
          final AccountModel account = accounts[index];
          return _AccountCard(
            account: account,
            balanceLabel: money.format(
              balances[account.id] ?? account.openingBalance,
            ),
            onTap: () => context.push(AppRoutes.accounts),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balanceLabel,
    required this.onTap,
  });

  final AccountModel account;
  final String balanceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.fromHex(account.colorHex);
    return Material(
      color: context.colors.surface,
      borderRadius: AppSizes.brMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 158,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            borderRadius: AppSizes.brMd,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      AppIcons.resolve(account.icon),
                      size: 17,
                      color: color,
                    ),
                  ),
                  AppSizes.hGapSm,
                  Expanded(
                    child: Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelLarge,
                    ),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  balanceLabel,
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppSizes.brMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DottedBorderBox(
          child: SizedBox(
            width: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.add_rounded,
                  color: context.colors.primary,
                  size: 22,
                ),
                AppSizes.gapXs,
                Text(
                  context.l10n.accounts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelMedium?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed-looking affordance for "add / manage" tiles.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSizes.brMd,
        color: context.colors.primary.withValues(alpha: 0.06),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }
}

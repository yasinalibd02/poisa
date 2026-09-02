import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// The Poisa wordmark on the left with a notification bell and an overflow
/// menu on the right.
class DashboardAppBar extends ConsumerWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.sm,
          AppSizes.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.headlineSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            _RoundIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: context.l10n.recentTransactions,
              onTap: () => context.go(AppRoutes.transactions),
            ),
            AppSizes.hGapXs,
            _OverflowMenu(),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 24, color: context.colors.onSurface),
    );
  }
}

/// The `⋮` menu — everything the redesigned dashboard no longer shows inline
/// (accounts, categories, budgets) is still one tap away here.
class _OverflowMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.settings,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 24,
        color: context.colors.onSurface,
      ),
      onSelected: (String route) => context.push(route),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: AppRoutes.accounts,
          child: _MenuRow(
            icon: Icons.account_balance_wallet_outlined,
            label: context.l10n.accounts,
          ),
        ),
        PopupMenuItem<String>(
          value: AppRoutes.budget,
          child: _MenuRow(
            icon: Icons.savings_outlined,
            label: context.l10n.budgets,
          ),
        ),
        PopupMenuItem<String>(
          value: AppRoutes.categories,
          child: _MenuRow(
            icon: Icons.category_outlined,
            label: context.l10n.categories,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: AppRoutes.settings,
          child: _MenuRow(
            icon: Icons.settings_outlined,
            label: context.l10n.settings,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
        AppSizes.hGapMd,
        Text(label, style: context.texts.bodyMedium),
      ],
    );
  }
}

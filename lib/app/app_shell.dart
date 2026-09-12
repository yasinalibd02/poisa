import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_sizes.dart';
import '../core/extensions/context_x.dart';
import '../core/widgets/state_views.dart';
import '../features/auth/presentation/providers/user_providers.dart';
import 'routes.dart';

/// Persistent chrome around the four tabbed screens: the bottom navigation bar
/// and the centre "add transaction" FAB.
///
/// There is deliberately no "you are offline" banner. Every read is served
/// from the local cache and every write is applied to it immediately and
/// replayed when the connection returns, so a missing connection changes
/// nothing the user can act on — the banner only ever announced a state that
/// was not a problem, and it did so by sitting on top of the status bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  /// Tag shared with the editor screen's card, so the FAB grows into the form.
  static const String addTransactionHeroTag = 'kori-add-transaction';

  static const List<String> _destinations = <String>[
    AppRoutes.dashboard,
    AppRoutes.transactions,
    AppRoutes.reports,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps preference changes flowing to the user's profile document.
    ref.watch(settingsMirrorProvider);
    final AsyncValue<void> bootstrap = ref.watch(userBootstrapProvider);

    return Scaffold(
      body: bootstrap.when(
        // Seeding only ever runs once, on the very first sign-in.
        loading: () => const _BootstrapSkeleton(),
        error: (Object error, _) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(userBootstrapProvider),
        ),
        data: (_) => child,
      ),
      floatingActionButton: Hero(
        tag: addTransactionHeroTag,
        child: FloatingActionButton(
          // Scaffold wraps its FAB in a Hero of its own; without this the
          // default tag nests inside ours and trips Hero's "no descendant
          // Hero" assertion.
          heroTag: null,
          onPressed: () => context.push(AppRoutes.transactionNew),
          tooltip: context.l10n.addTransaction,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _KoriNavBar(
        currentIndex: _indexFor(location),
        onSelect: (int index) => context.go(_destinations[index]),
      ),
    );
  }

  int _indexFor(String location) {
    final int index = _destinations.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
  }
}

class _KoriNavBar extends StatelessWidget {
  const _KoriNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Material(
      color: colors.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: <Widget>[
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: context.l10n.home,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: context.l10n.transactions,
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
              // Space reserved for the docked FAB.
              const SizedBox(width: 72),
              _NavItem(
                icon: Icons.pie_chart_outline_rounded,
                activeIcon: Icons.pie_chart_rounded,
                label: context.l10n.reports,
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: context.l10n.profile,
                selected: currentIndex == 3,
                onTap: () => onSelect(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? context.colors.primary
        : context.colors.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.brSm,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedSwitcher(
              duration: AppSizes.fast,
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey<bool>(selected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.texts.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown for the brief moment while the profile document is created and the
/// default categories are seeded.
class _BootstrapSkeleton extends StatelessWidget {
  const _BootstrapSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ShimmerBox(height: 28, width: 180),
          AppSizes.gapXl,
          CardSkeleton(height: 150),
          AppSizes.gapLg,
          CardSkeleton(height: 96),
          AppSizes.gapLg,
          Expanded(child: ListSkeleton(rows: 4, padding: EdgeInsets.zero)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// Pinned Income / Expense / Net strip above the transactions list.
class SummaryBar extends StatelessWidget {
  const SummaryBar({
    super.key,
    required this.income,
    required this.expense,
    required this.net,
  });

  final String income;
  final String expense;
  final String net;

  static const double height = 62;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: context.theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        0,
        AppSizes.screenPadding,
        AppSizes.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppSizes.brMd,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            _Cell(
              label: context.l10n.income,
              value: income,
              color: AppColors.income,
            ),
            _Divider(),
            _Cell(
              label: context.l10n.expense,
              value: expense,
              color: AppColors.expense,
            ),
            _Divider(),
            _Cell(
              label: context.l10n.net,
              value: net,
              color: context.colors.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: context.texts.titleSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: context.colors.outlineVariant);
  }
}

/// Pins [SummaryBar] to the top of the scroll view.
class PinnedSummaryBar extends SliverPersistentHeaderDelegate {
  const PinnedSummaryBar({required this.child});

  final SummaryBar child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  double get maxExtent => SummaryBar.height;

  @override
  double get minExtent => SummaryBar.height;

  @override
  bool shouldRebuild(covariant PinnedSummaryBar oldDelegate) =>
      oldDelegate.child.income != child.income ||
      oldDelegate.child.expense != child.expense ||
      oldDelegate.child.net != child.net;
}

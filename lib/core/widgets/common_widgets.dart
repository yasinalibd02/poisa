import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../constants/enums.dart';
import '../extensions/context_x.dart';

/// A signed, coloured money value: green `+৳1,200`, red `−৳350`.
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.text,
    required this.type,
    this.style,
    this.neutral = false,
  });

  final String text;
  final TransactionType type;
  final TextStyle? style;

  /// Renders in the default text colour — for totals where the sign is
  /// already obvious from context.
  final bool neutral;

  static Color colorFor(TransactionType type) => switch (type) {
    TransactionType.income => AppColors.income,
    TransactionType.expense => AppColors.expense,
    TransactionType.transfer => AppColors.transfer,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (style ?? context.texts.titleSmall)?.copyWith(
        color: neutral ? context.colors.onSurface : colorFor(type),
        fontWeight: FontWeight.w600,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Rounded-square icon chip tinted with a category's or account's colour.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.iconKey,
    required this.colorHex,
    this.size = 44,
    this.selected = false,
  });

  final String iconKey;
  final String colorHex;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.fromHex(colorHex);
    return AnimatedContainer(
      duration: AppSizes.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: selected ? Border.all(color: color, width: 2) : null,
      ),
      child: Icon(
        AppIcons.resolve(iconKey),
        size: size * 0.5,
        color: context.isDark ? Color.lerp(color, Colors.white, 0.25) : color,
      ),
    );
  }
}

/// Section title with an optional trailing action ("See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppSizes.screenPadding,
      AppSizes.xl,
      AppSizes.screenPadding,
      AppSizes.md,
    ),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: context.texts.titleMedium)),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// The app's standard surface: rounded, hairline-bordered, soft.
class KoriCard extends StatelessWidget {
  const KoriCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.lg),
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? context.colors.surface,
      borderRadius: AppSizes.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppSizes.brLg,
            border: border ?? Border.all(color: context.colors.outlineVariant),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Segmented control used for Expense / Income (and the three-way transaction
/// type switch).
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.activeColors,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Optional per-segment accent (expense red, income green, transfer blue).
  final List<Color>? activeColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: AppSizes.brMd,
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                active: values[i] == selected,
                activeColor:
                    activeColors?[i] ?? context.colors.primary,
                onTap: () => onChanged(values[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppSizes.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: AppSizes.brSm,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.titleSmall?.copyWith(
            color: active ? Colors.white : context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Progress bar that switches colour at the 70% and 100% budget thresholds.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
  });

  /// `spent / limit`; values above 1 are clamped for the bar but still turn it
  /// red.
  final double progress;
  final double height;

  static Color colorFor(double progress) {
    if (progress >= 1) return AppColors.budgetDanger;
    if (progress >= 0.7) return AppColors.budgetWarning;
    return AppColors.budgetSafe;
  }

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.isNaN ? 0 : progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped),
        duration: AppSizes.slow,
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, _) => LinearProgressIndicator(
          value: value,
          minHeight: height,
          backgroundColor: context.colors.outlineVariant,
          valueColor: AlwaysStoppedAnimation<Color>(colorFor(progress)),
        ),
      ),
    );
  }
}

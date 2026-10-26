import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../extensions/context_x.dart';
import '../utils/app_failure.dart';

/// Friendly empty state: an illustration, a headline, a line of guidance and
/// an optional call to action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _EmptyIllustration(icon: icon, size: compact ? 84 : 116),
            SizedBox(height: compact ? AppSizes.lg : AppSizes.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleMedium,
            ),
            AppSizes.gapSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              AppSizes.gapXl,
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.primary.withValues(alpha: 0.14),
            colors.secondary.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Icon(icon, size: size * 0.42, color: colors.primary),
    );
  }
}

/// Error state with a retry affordance. Used for `AsyncValue.error`.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppFailure failure = AppFailure.from(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _EmptyIllustration(
              icon: failure.kind == FailureKind.network
                  ? CupertinoIcons.wifi_slash
                  : CupertinoIcons.exclamationmark_circle,
              size: 96,
            ),
            AppSizes.gapXl,
            Text(context.l10n.errorTitle, style: context.texts.titleMedium),
            AppSizes.gapSm,
            Text(
              failure.localizedMessage(context.l10n),
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...<Widget>[
              AppSizes.gapXl,
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(CupertinoIcons.arrow_clockwise),
                label: Text(context.l10n.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single shimmering block. Composed into skeletons instead of dropping a
/// bare spinner in the middle of a screen.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppSizes.radiusSm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = context.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final Color highlight = context.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.02);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * t, 0),
              end: Alignment(1 - 2 * t, 0),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a list of rows (transactions, categories, budgets).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 6, this.padding});

  final int rows;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding:
          padding ?? const EdgeInsets.all(AppSizes.screenPadding),
      itemCount: rows,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (BuildContext context, int index) => AppSizes.gapMd,
      itemBuilder: (BuildContext context, int index) => const Row(
        children: <Widget>[
          ShimmerBox(width: 44, height: 44, radius: AppSizes.radiusSm),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(width: 140, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 90, height: 12),
              ],
            ),
          ),
          AppSizes.hGapMd,
          ShimmerBox(width: 64, height: 16),
        ],
      ),
    );
  }
}

/// Skeleton for the dashboard's stacked cards.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(height: height, radius: AppSizes.radiusLg);
  }
}

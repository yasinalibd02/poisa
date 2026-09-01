import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// One of the two big language cards on the final onboarding step, reused by
/// the Settings language sheet.
class LanguageChoiceCard extends StatelessWidget {
  const LanguageChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.10)
          : colors.surface,
      borderRadius: AppSizes.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppSizes.fast,
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.xl,
            horizontal: AppSizes.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSizes.brLg,
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              AnimatedScale(
                duration: AppSizes.fast,
                scale: selected ? 1 : 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              AppSizes.gapSm,
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.texts.titleMedium?.copyWith(
                  color: selected ? colors.primary : colors.onSurface,
                ),
              ),
              AppSizes.gapXs,
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// One value-proposition slide: a tinted icon, a headline and a short body.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  context.colors.primary.withValues(alpha: 0.16),
                  context.colors.secondary.withValues(alpha: 0.14),
                ],
              ),
            ),
            child: Icon(icon, size: 74, color: context.colors.primary),
          ),
          AppSizes.gapXxl,
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.texts.headlineSmall,
          ),
          AppSizes.gapMd,
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.texts.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

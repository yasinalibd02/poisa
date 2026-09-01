import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// Date heading with that day's net subtotal.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.label,
    required this.subtotal,
    required this.subtotalColor,
  });

  final String label;
  final String subtotal;
  final Color subtotalColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.sm,
        AppSizes.lg,
        AppSizes.sm,
        AppSizes.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppSizes.hGapSm,
          Text(
            subtotal,
            style: context.texts.labelLarge?.copyWith(
              color: subtotalColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

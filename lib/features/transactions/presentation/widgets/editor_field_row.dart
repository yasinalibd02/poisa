import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// A tappable "label / value" row used for the account and date pickers in
/// the transaction editor.
class EditorFieldRow extends StatelessWidget {
  const EditorFieldRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.emphasised = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  /// False when [value] is a placeholder prompt rather than a real choice.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: AppSizes.brMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSizes.brMd,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: context.texts.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall?.copyWith(
                        color: emphasised
                            ? context.colors.onSurface
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

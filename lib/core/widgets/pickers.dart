import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../extensions/context_x.dart';

/// Grid of every icon in the catalogue. Used by the category and account
/// editors.
class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({
    super.key,
    required this.selectedKey,
    required this.tint,
    required this.onSelected,
    this.height = 190,
  });

  final String selectedKey;
  final Color tint;
  final ValueChanged<String> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final List<String> keys = AppIcons.keys;
    return SizedBox(
      height: height,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 56,
          mainAxisSpacing: AppSizes.sm,
          crossAxisSpacing: AppSizes.sm,
        ),
        itemCount: keys.length,
        itemBuilder: (BuildContext context, int index) {
          final String key = keys[index];
          final bool selected = key == selectedKey;
          return InkWell(
            onTap: () => onSelected(key),
            borderRadius: AppSizes.brSm,
            child: AnimatedContainer(
              duration: AppSizes.fast,
              decoration: BoxDecoration(
                color: selected
                    ? tint.withValues(alpha: 0.18)
                    : context.colors.outlineVariant.withValues(alpha: 0.35),
                borderRadius: AppSizes.brSm,
                border: selected ? Border.all(color: tint, width: 2) : null,
              ),
              child: Icon(
                AppIcons.resolve(key),
                size: 22,
                color: selected ? tint : context.colors.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The 16 brand swatches.
class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selectedHex,
    required this.onSelected,
  });

  final String selectedHex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.md,
      children: <Widget>[
        for (final Color color in AppColors.swatches)
          _Swatch(
            color: color,
            selected:
                AppColors.toHex(color).toUpperCase() ==
                selectedHex.toUpperCase(),
            onTap: () => onSelected(AppColors.toHex(color)),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSizes.fast,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.colors.onSurface : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: selected
            ? const Icon(CupertinoIcons.checkmark, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

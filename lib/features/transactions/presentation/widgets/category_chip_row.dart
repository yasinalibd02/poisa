import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Horizontally scrolling category chips for the editor, with a trailing
/// "more" chip that opens the full grid.
class CategoryChipRow extends ConsumerWidget {
  const CategoryChipRow({
    super.key,
    required this.type,
    required this.selectedId,
    required this.onSelected,
    required this.onMore,
  });

  final CategoryType type;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CategoryModel> categories = ref.watch(
      categoriesByTypeProvider(type),
    );
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );

    if (categories.isEmpty) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: onMore,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.l10n.newCategory),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.category, style: context.texts.labelLarge),
        AppSizes.gapSm,
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (BuildContext context, int index) => AppSizes.hGapSm,
            itemBuilder: (BuildContext context, int index) {
              if (index == categories.length) {
                return _Chip(
                  label: context.l10n.actionSeeAll,
                  iconKey: 'more',
                  colorHex: AppColors.toHex(context.colors.primary),
                  selected: false,
                  onTap: onMore,
                );
              }
              final CategoryModel category = categories[index];
              return _Chip(
                label: category.displayName(language),
                iconKey: category.icon,
                colorHex: category.colorHex,
                selected: category.id == selectedId,
                onTap: () => onSelected(category.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.iconKey,
    required this.colorHex,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconKey;
  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.fromHex(colorHex);
    return Material(
      color: selected
          ? color.withValues(alpha: 0.16)
          : context.colors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(
              color: selected ? color : context.colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(AppIcons.resolve(iconKey), size: 17, color: color),
              AppSizes.hGapXs,
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelMedium?.copyWith(
                  color: selected ? color : context.colors.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

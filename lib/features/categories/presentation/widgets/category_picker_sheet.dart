import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/category_model.dart';
import '../providers/category_providers.dart';

/// Bottom-sheet grid of categories for one side of the ledger.
/// Returns the chosen category id, or `null` if dismissed.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required CategoryType type,
  String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryPickerSheet(type: type, selectedId: selectedId),
  );
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({required this.type, required this.selectedId});

  final CategoryType type;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CategoryModel> categories = ref.watch(
      categoriesByTypeProvider(type),
    );
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.sm,
                AppSizes.sm,
                AppSizes.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.selectCategory,
                      style: context.texts.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.categories);
                    },
                    icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 18),
                    label: Text(context.l10n.actionEdit),
                  ),
                ],
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.noCategoriesTitle,
                        style: context.texts.bodyMedium,
                      ),
                    )
                  : GridView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.lg,
                        0,
                        AppSizes.lg,
                        AppSizes.xxl,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 96,
                            mainAxisSpacing: AppSizes.md,
                            crossAxisSpacing: AppSizes.md,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (BuildContext context, int index) {
                        final CategoryModel category = categories[index];
                        return _CategoryCell(
                          category: category,
                          label: category.displayName(language),
                          selected: category.id == selectedId,
                          onTap: () =>
                              Navigator.of(context).pop(category.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSizes.brMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconBadge(
            iconKey: category.icon,
            colorHex: category.colorHex,
            size: 52,
            selected: selected,
          ),
          AppSizes.gapSm,
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(
                color: selected
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/category_model.dart';
import '../providers/category_providers.dart';
import '../widgets/category_editor_sheet.dart';
import '../widgets/move_target_sheet.dart';

/// Manage categories: two tabs, a grid with this month's totals, and a
/// reorder mode.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  CategoryType get _currentType =>
      _tabs.index == 0 ? CategoryType.expense : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CategoryModel>> categories = ref.watch(
      categoriesStreamProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.manageCategories),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.dragToReorder,
            isSelected: _reordering,
            onPressed: () => setState(() => _reordering = !_reordering),
            icon: const Icon(CupertinoIcons.arrow_up_arrow_down),
            selectedIcon: const Icon(CupertinoIcons.checkmark),
          ),
          AppSizes.hGapXs,
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            Tab(text: context.l10n.expense),
            Tab(text: context.l10n.income),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showCategoryEditor(context, type: _currentType),
        icon: const Icon(CupertinoIcons.add),
        label: Text(context.l10n.newCategory),
      ),
      body: categories.when(
        loading: () => const ListSkeleton(rows: 8),
        error: (Object error, _) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(categoriesStreamProvider),
        ),
        data: (_) => TabBarView(
          controller: _tabs,
          children: <Widget>[
            _CategoryTab(
              type: CategoryType.expense,
              reordering: _reordering,
              onDelete: _startDeleteFlow,
            ),
            _CategoryTab(
              type: CategoryType.income,
              reordering: _reordering,
              onDelete: _startDeleteFlow,
            ),
          ],
        ),
      ),
    );
  }

  /// Default categories are protected; anything else with history must have
  /// its transactions moved before it can go.
  Future<void> _startDeleteFlow(CategoryModel category) async {
    if (category.isDefault) {
      AppSnack.show(context, context.l10n.defaultCannotDelete);
      return;
    }

    final int count = await ref
        .read(transactionRepositoryProvider)
        .countForCategory(category.id);
    if (!mounted) return;

    if (count == 0) {
      final bool confirmed = await showConfirmDialog(
        context,
        title: context.l10n.deleteCategoryTitle,
        message: context.l10n.deleteCategoryBody(
          category.displayName(ref.read(settingsProvider).languageCode),
        ),
        confirmLabel: context.l10n.actionDelete,
      );
      if (!confirmed || !mounted) return;
      await _delete(category);
      return;
    }

    final List<CategoryModel> alternatives = ref
        .read(categoriesByTypeProvider(category.type))
        .where((CategoryModel c) => c.id != category.id)
        .toList(growable: false);

    if (alternatives.isEmpty) {
      AppSnack.show(context, context.l10n.categoryInUseBody(count));
      return;
    }

    final String? targetId = await showMoveTargetSheet(
      context,
      title: context.l10n.categoryInUseTitle,
      message: context.l10n.categoryInUseBody(count),
      pickerLabel: context.l10n.moveTransactionsTo,
      confirmLabel: context.l10n.moveAndDelete,
      options: alternatives
          .map(
            (CategoryModel c) => MoveTarget(
              id: c.id,
              label: c.displayName(ref.read(settingsProvider).languageCode),
              iconKey: c.icon,
              colorHex: c.colorHex,
            ),
          )
          .toList(growable: false),
    );
    if (targetId == null || !mounted) return;

    try {
      await ref
          .read(transactionRepositoryProvider)
          .reassignCategory(
            fromCategoryId: category.id,
            toCategoryId: targetId,
          );
      await _delete(category);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }

  Future<void> _delete(CategoryModel category) async {
    try {
      await ref.read(categoryRepositoryProvider).delete(category.id);
      if (!mounted) return;
      AppSnack.success(context, context.l10n.categoryDeleted);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({
    required this.type,
    required this.reordering,
    required this.onDelete,
  });

  final CategoryType type;
  final bool reordering;
  final ValueChanged<CategoryModel> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CategoryModel> categories = ref.watch(
      categoriesByTypeProvider(type),
    );
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final DateRange range = ref.watch(selectedMonthRangeProvider);
    final Map<String, double> totals = ref.watch(
      categoryTotalsProvider(CategoryTotalsQuery(range, type)),
    );

    if (categories.isEmpty) {
      return EmptyStateView(
        icon: CupertinoIcons.square_grid_2x2_fill,
        title: context.l10n.noCategoriesTitle,
        message: context.l10n.noCategoriesBody,
        actionLabel: context.l10n.newCategory,
        onAction: () => showCategoryEditor(context, type: type),
      );
    }

    if (reordering) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          96,
        ),
        itemCount: categories.length,
        // `onReorderItem` replaced this in Flutter 3.41; `onReorder` is the
        // only variant available on the 3.24 floor this project supports.
        // ignore: deprecated_member_use
        onReorder: (int oldIndex, int newIndex) {
          final List<CategoryModel> next = <CategoryModel>[...categories];
          if (newIndex > oldIndex) newIndex -= 1;
          next.insert(newIndex, next.removeAt(oldIndex));
          ref.read(categoryRepositoryProvider).reorder(next).ignore();
        },
        itemBuilder: (BuildContext context, int index) {
          final CategoryModel category = categories[index];
          return ListTile(
            key: ValueKey<String>(category.id),
            leading: IconBadge(
              iconKey: category.icon,
              colorHex: category.colorHex,
              size: 40,
            ),
            title: Text(
              category.displayName(language),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(CupertinoIcons.line_horizontal_3),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        96,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: AppSizes.md,
        crossAxisSpacing: AppSizes.md,
        mainAxisExtent: 132,
      ),
      itemCount: categories.length,
      itemBuilder: (BuildContext context, int index) {
        final CategoryModel category = categories[index];
        final double total = totals[category.id] ?? 0;
        return _CategoryCard(
          category: category,
          label: category.displayName(language),
          total: total > 0 ? money.format(total) : money.format(0),
          onTap: () => showCategoryEditor(
            context,
            type: type,
            existing: category,
          ),
          onDelete: () => onDelete(category),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.label,
    required this.total,
    required this.onTap,
    required this.onDelete,
  });

  final CategoryModel category;
  final String label;
  final String total;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return KoriCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconBadge(
                iconKey: category.icon,
                colorHex: category.colorHex,
                size: 38,
              ),
              const Spacer(),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  tooltip: context.l10n.actionDelete,
                  onPressed: onDelete,
                  icon: Icon(
                    CupertinoIcons.trash,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.texts.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            total,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall,
          ),
        ],
      ),
    );
  }
}

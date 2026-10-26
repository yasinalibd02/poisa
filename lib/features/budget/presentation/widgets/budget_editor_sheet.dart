import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/budget_model.dart';
import '../../data/budget_repository.dart';
import '../providers/budget_providers.dart';

/// Create or edit one monthly budget — either for a category, or the single
/// overall budget for the month.
Future<void> showBudgetEditor(
  BuildContext context, {
  BudgetModel? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BudgetEditorSheet(existing: existing),
  );
}

class _BudgetEditorSheet extends ConsumerStatefulWidget {
  const _BudgetEditorSheet({this.existing});

  final BudgetModel? existing;

  @override
  ConsumerState<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends ConsumerState<_BudgetEditorSheet> {
  late final TextEditingController _limitController = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.limitAmount.toStringAsFixed(
            widget.existing!.limitAmount ==
                    widget.existing!.limitAmount.roundToDouble()
                ? 0
                : 2,
          ),
  );

  late String? _categoryId = widget.existing?.categoryId;
  late bool _isOverall = widget.existing?.isOverall ?? false;
  bool _saving = false;
  String? _errorText;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final String? id = await showCategoryPicker(
      context,
      type: CategoryType.expense,
      selectedId: _categoryId,
    );
    if (id != null) {
      setState(() {
        _categoryId = id;
        _isOverall = false;
        _errorText = null;
      });
    }
  }

  Future<void> _save() async {
    final double? limit = Validators.parseAmount(_limitController.text);
    if (limit == null || limit <= 0) {
      setState(() => _errorText = context.l10n.errorLimitRequired);
      return;
    }
    if (!_isOverall && _categoryId == null) {
      setState(() => _errorText = context.l10n.errorCategoryRequired);
      return;
    }

    final DateRange range = ref.read(selectedMonthRangeProvider);
    final int year = range.start.year;
    final int month = range.start.month;
    final String? categoryId = _isOverall ? null : _categoryId;

    // One budget per category per month — a second one would silently split
    // the limit.
    final List<BudgetProgress> existingForMonth = ref.read(
      selectedMonthBudgetsProvider,
    );
    final bool clashes = existingForMonth.any(
      (BudgetProgress p) =>
          p.budget.categoryId == categoryId &&
          p.budget.id != widget.existing?.id,
    );
    if (clashes) {
      setState(() => _errorText = context.l10n.errorBudgetExists);
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final BudgetRepository repository = ref.read(budgetRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.update(
          widget.existing!.copyWith(
            categoryId: categoryId,
            clearCategory: categoryId == null,
            limitAmount: Validators.roundMoney(limit),
          ),
        );
      } else {
        await repository.create(
          BudgetModel(
            id: '',
            categoryId: categoryId,
            limitAmount: Validators.roundMoney(limit),
            period: 'monthly',
            year: year,
            month: month,
            createdAt: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnack.success(context, context.l10n.budgetSaved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );
    final Map<String, CategoryModel> categories = ref.watch(
      categoryMapProvider,
    );
    final CategoryModel? category = _categoryId == null
        ? null
        : categories[_categoryId];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.sm,
            AppSizes.lg,
            AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _isEditing ? context.l10n.editBudget : context.l10n.newBudget,
                style: context.texts.titleMedium,
              ),
              AppSizes.gapLg,
              SwitchListTile.adaptive(
                value: _isOverall,
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.overallBudget),
                onChanged: (bool value) => setState(() {
                  _isOverall = value;
                  _errorText = null;
                }),
              ),
              if (!_isOverall) ...<Widget>[
                AppSizes.gapSm,
                Material(
                  color: context.colors.surface,
                  borderRadius: AppSizes.brMd,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _pickCategory,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        borderRadius: AppSizes.brMd,
                        border: Border.all(color: context.colors.outlineVariant),
                      ),
                      child: Row(
                        children: <Widget>[
                          IconBadge(
                            iconKey: category?.icon ?? 'category',
                            colorHex: category?.colorHex ?? '#6B7A87',
                            size: 38,
                          ),
                          AppSizes.hGapMd,
                          Expanded(
                            child: Text(
                              category?.displayName(language) ??
                                  context.l10n.selectCategory,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.titleSmall,
                            ),
                          ),
                          const Icon(CupertinoIcons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              AppSizes.gapLg,
              TextField(
                controller: _limitController,
                autofocus: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.budgetLimit,
                  errorText: _errorText,
                  prefixIcon: const Icon(CupertinoIcons.flag),
                ),
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              AppSizes.gapXl,
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

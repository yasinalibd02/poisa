import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/pickers.dart';
import '../../data/category_model.dart';
import '../../data/category_repository.dart';
import '../providers/category_providers.dart';

/// Create or edit a category. Both names are captured so the label follows the
/// UI language later.
Future<void> showCategoryEditor(
  BuildContext context, {
  required CategoryType type,
  CategoryModel? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryEditorSheet(type: type, existing: existing),
  );
}

class _CategoryEditorSheet extends ConsumerStatefulWidget {
  const _CategoryEditorSheet({required this.type, this.existing});

  final CategoryType type;
  final CategoryModel? existing;

  @override
  ConsumerState<_CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final TextEditingController _enController = TextEditingController(
    text: widget.existing?.nameEn ?? '',
  );
  late final TextEditingController _bnController = TextEditingController(
    text: widget.existing?.nameBn ?? '',
  );

  late String _iconKey = widget.existing?.icon ?? 'category';
  late String _colorHex =
      widget.existing?.colorHex ?? AppColors.toHex(AppColors.swatches.first);
  bool _saving = false;
  bool _showNameError = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _enController.dispose();
    _bnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String nameEn = _enController.text.trim();
    final String nameBn = _bnController.text.trim();

    // One of the two names is enough; the model falls back to the other.
    if (!Validators.isNotBlank(nameEn) && !Validators.isNotBlank(nameBn)) {
      setState(() => _showNameError = true);
      return;
    }

    setState(() => _saving = true);
    final CategoryRepository repository = ref.read(categoryRepositoryProvider);

    try {
      if (_isEditing) {
        await repository.update(
          widget.existing!.copyWith(
            nameEn: nameEn,
            nameBn: nameBn,
            icon: _iconKey,
            colorHex: _colorHex,
          ),
        );
      } else {
        final List<CategoryModel> all =
            ref.read(categoriesStreamProvider).valueOrNull ??
            const <CategoryModel>[];
        await repository.create(
          CategoryModel(
            id: '',
            nameEn: nameEn,
            nameBn: nameBn,
            type: widget.type,
            icon: _iconKey,
            colorHex: _colorHex,
            isDefault: false,
            sortOrder: repository.nextSortOrder(all, widget.type),
            createdAt: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnack.success(context, context.l10n.categorySaved);
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
    final Color tint = AppColors.fromHex(_colorHex);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController controller) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.sm,
                  AppSizes.lg,
                  AppSizes.md,
                ),
                child: Row(
                  children: <Widget>[
                    IconBadge(
                      iconKey: _iconKey,
                      colorHex: _colorHex,
                      size: 40,
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Text(
                        _isEditing
                            ? context.l10n.editCategory
                            : context.l10n.newCategory,
                        style: context.texts.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    0,
                    AppSizes.lg,
                    AppSizes.lg,
                  ),
                  children: <Widget>[
                    TextField(
                      controller: _enController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: context.l10n.categoryNameEn,
                        errorText: _showNameError
                            ? context.l10n.errorNameRequired
                            : null,
                      ),
                      onChanged: (_) {
                        if (_showNameError) {
                          setState(() => _showNameError = false);
                        }
                      },
                    ),
                    AppSizes.gapMd,
                    TextField(
                      controller: _bnController,
                      decoration: InputDecoration(
                        labelText: context.l10n.categoryNameBn,
                      ),
                      onChanged: (_) {
                        if (_showNameError) {
                          setState(() => _showNameError = false);
                        }
                      },
                    ),
                    AppSizes.gapXl,
                    Text(context.l10n.color, style: context.texts.labelLarge),
                    AppSizes.gapMd,
                    ColorPickerRow(
                      selectedHex: _colorHex,
                      onSelected: (String hex) =>
                          setState(() => _colorHex = hex),
                    ),
                    AppSizes.gapXl,
                    Text(context.l10n.icon, style: context.texts.labelLarge),
                    AppSizes.gapMd,
                    IconPickerGrid(
                      selectedKey: _iconKey,
                      tint: tint,
                      onSelected: (String key) =>
                          setState(() => _iconKey = key),
                    ),
                  ],
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  0,
                  AppSizes.lg,
                  AppSizes.md,
                ),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.actionSave),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

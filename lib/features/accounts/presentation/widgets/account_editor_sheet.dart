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
import '../../data/account_model.dart';
import '../../data/account_repository.dart';
import '../providers/account_providers.dart';
import 'account_type_label.dart';

/// Create or edit an account, including its opening balance.
Future<void> showAccountEditor(
  BuildContext context, {
  AccountModel? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AccountEditorSheet(existing: existing),
  );
}

class _AccountEditorSheet extends ConsumerStatefulWidget {
  const _AccountEditorSheet({this.existing});

  final AccountModel? existing;

  @override
  ConsumerState<_AccountEditorSheet> createState() =>
      _AccountEditorSheetState();
}

class _AccountEditorSheetState extends ConsumerState<_AccountEditorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _openingController = TextEditingController(
    text: widget.existing == null
        ? ''
        : _plainAmount(widget.existing!.openingBalance),
  );

  late AccountType _type = widget.existing?.type ?? AccountType.cash;
  late String _iconKey =
      widget.existing?.icon ?? AccountType.cash.defaultIconKey;
  late String _colorHex =
      widget.existing?.colorHex ?? AppColors.toHex(AppColors.swatches.first);
  bool _saving = false;
  bool _showNameError = false;

  bool get _isEditing => widget.existing != null;

  static String _plainAmount(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  @override
  void dispose() {
    _nameController.dispose();
    _openingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (!Validators.isNotBlank(name)) {
      setState(() => _showNameError = true);
      return;
    }

    setState(() => _saving = true);
    final AccountRepository repository = ref.read(accountRepositoryProvider);
    final double opening =
        Validators.parseAmount(_openingController.text) ?? 0;

    try {
      if (_isEditing) {
        await repository.update(
          widget.existing!.copyWith(
            name: name,
            type: _type,
            icon: _iconKey,
            colorHex: _colorHex,
            openingBalance: Validators.roundMoney(opening),
          ),
        );
      } else {
        final List<AccountModel> all =
            ref.read(accountsStreamProvider).valueOrNull ??
            const <AccountModel>[];
        await repository.create(
          AccountModel(
            id: '',
            name: name,
            type: _type,
            icon: _iconKey,
            colorHex: _colorHex,
            openingBalance: Validators.roundMoney(opening),
            isArchived: false,
            sortOrder: repository.nextSortOrder(all),
            createdAt: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnack.success(context, context.l10n.accountSaved);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
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
                            ? context.l10n.editAccount
                            : context.l10n.newAccount,
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
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: context.l10n.accountName,
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
                      controller: _openingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.openingBalance,
                        prefixIcon: const Icon(Icons.savings_outlined),
                      ),
                    ),
                    AppSizes.gapXl,
                    Text(
                      context.l10n.accountType,
                      style: context.texts.labelLarge,
                    ),
                    AppSizes.gapSm,
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      children: <Widget>[
                        for (final AccountType type in AccountType.values)
                          ChoiceChip(
                            selected: _type == type,
                            label: Text(accountTypeLabel(context, type)),
                            onSelected: (_) => setState(() {
                              // Adopting the type's icon is only a suggestion;
                              // the user can still pick any icon below.
                              if (_iconKey == _type.defaultIconKey) {
                                _iconKey = type.defaultIconKey;
                              }
                              _type = type;
                            }),
                          ),
                      ],
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
                      tint: AppColors.fromHex(_colorHex),
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

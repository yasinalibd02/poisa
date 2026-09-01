import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/transaction_list_provider.dart';

/// Full filter sheet: date range, type, categories, accounts and amount
/// bounds. Edits are held locally and only applied on "Apply", so backing out
/// leaves the list untouched.
Future<void> showFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FiltersSheet(),
  );
}

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet();

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late TransactionFilters _draft = ref.read(transactionFiltersProvider);
  late final TextEditingController _minController = TextEditingController(
    text: _draft.minAmount?.toStringAsFixed(0) ?? '',
  );
  late final TextEditingController _maxController = TextEditingController(
    text: _draft.maxAmount?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final TransactionFilters filters = _draft.copyWith(
      minAmount: Validators.parseAmount(_minController.text),
      clearMin: Validators.parseAmount(_minController.text) == null,
      maxAmount: Validators.parseAmount(_maxController.text),
      clearMax: Validators.parseAmount(_maxController.text) == null,
    );
    ref.read(transactionFiltersProvider.notifier).apply(filters);
    Navigator.of(context).pop();
  }

  Future<void> _pickRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: _draft.range == null
          ? null
          : DateTimeRange(
              start: _draft.range!.start,
              end: _draft.range!.endInclusive,
            ),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        range: DateRange(
          PeriodUtils.dayStart(picked.start),
          PeriodUtils.dayStart(picked.end).add(const Duration(days: 1)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );
    final DateLabels dates = ref.watch(dateLabelsProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final List<CategoryModel> categories =
        ref.watch(categoriesStreamProvider).valueOrNull ??
        const <CategoryModel>[];
    final List<AccountModel> accounts = ref.watch(activeAccountsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.sm,
                AppSizes.sm,
                0,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.filters,
                      style: context.texts.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _draft = const TransactionFilters();
                      _minController.clear();
                      _maxController.clear();
                    }),
                    child: Text(context.l10n.actionReset),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.sm,
                  AppSizes.lg,
                  AppSizes.lg,
                ),
                children: <Widget>[
                  _Label(context.l10n.dateRange),
                  OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: Text(
                      _draft.range == null
                          ? context.l10n.labelAll
                          : money.localizeDigits(
                              dates.rangeLabel(_draft.range!),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_draft.range != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => setState(
                          () => _draft = _draft.copyWith(clearRange: true),
                        ),
                        child: Text(context.l10n.actionRemove),
                      ),
                    ),

                  _Label(context.l10n.type),
                  Wrap(
                    spacing: AppSizes.sm,
                    children: <Widget>[
                      for (final TransactionType type in TransactionType.values)
                        FilterChip(
                          selected: _draft.types.contains(type),
                          label: Text(_typeLabel(context, type)),
                          onSelected: (bool selected) => setState(() {
                            final Set<TransactionType> next =
                                <TransactionType>{..._draft.types};
                            selected ? next.add(type) : next.remove(type);
                            _draft = _draft.copyWith(types: next);
                          }),
                        ),
                    ],
                  ),

                  _Label(context.l10n.categories),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: <Widget>[
                      for (final CategoryModel category in categories)
                        FilterChip(
                          selected: _draft.categoryIds.contains(category.id),
                          avatar: CircleAvatar(
                            radius: 6,
                            backgroundColor: AppColors.fromHex(
                              category.colorHex,
                            ),
                          ),
                          label: Text(category.displayName(language)),
                          onSelected: (bool selected) => setState(() {
                            final Set<String> next = <String>{
                              ..._draft.categoryIds,
                            };
                            selected
                                ? next.add(category.id)
                                : next.remove(category.id);
                            _draft = _draft.copyWith(categoryIds: next);
                          }),
                        ),
                    ],
                  ),

                  _Label(context.l10n.accounts),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: <Widget>[
                      for (final AccountModel account in accounts)
                        FilterChip(
                          selected: _draft.accountIds.contains(account.id),
                          label: Text(account.name),
                          onSelected: (bool selected) => setState(() {
                            final Set<String> next = <String>{
                              ..._draft.accountIds,
                            };
                            selected
                                ? next.add(account.id)
                                : next.remove(account.id);
                            _draft = _draft.copyWith(accountIds: next);
                          }),
                        ),
                    ],
                  ),

                  _Label(context.l10n.amountRange),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _minController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.l10n.minAmount,
                          ),
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: TextField(
                          controller: _maxController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.l10n.maxAmount,
                          ),
                        ),
                      ),
                    ],
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
                onPressed: _apply,
                child: Text(context.l10n.actionApply),
              ),
            ),
          ],
        );
      },
    );
  }

  String _typeLabel(BuildContext context, TransactionType type) =>
      switch (type) {
        TransactionType.income => context.l10n.income,
        TransactionType.expense => context.l10n.expense,
        TransactionType.transfer => context.l10n.transfer,
      };
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSizes.lg, 0, AppSizes.sm),
      child: Text(text, style: context.texts.labelLarge),
    );
  }
}

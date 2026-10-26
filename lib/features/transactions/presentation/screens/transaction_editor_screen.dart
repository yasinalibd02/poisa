import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../accounts/presentation/widgets/account_picker_sheet.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/transaction_model.dart';
import '../providers/transaction_actions.dart';
import '../providers/transaction_editor_provider.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/category_chip_row.dart';
import '../widgets/editor_field_row.dart';

/// Add or edit a transaction. Amount is entered on a built-in calculator, so
/// "240 + 60" can be typed without leaving the form.
class TransactionEditorScreen extends ConsumerStatefulWidget {
  const TransactionEditorScreen({super.key, this.existing, this.initialType});

  final TransactionModel? existing;

  /// Type name (`income` / `expense` / `transfer`) for a blank form.
  final String? initialType;

  @override
  ConsumerState<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState
    extends ConsumerState<TransactionEditorScreen> with WidgetsBindingObserver {
  late final EditorArgs _args = (
    existing: widget.existing,
    initialType:
        widget.existing?.type ?? TransactionType.fromName(widget.initialType),
  );

  late final TextEditingController _noteController = TextEditingController(
    text: widget.existing?.note ?? '',
  );

  /// Watched so the amount keypad can step aside for the system keyboard: the
  /// two cannot share the bottom of the screen, and a note is typed with
  /// letters, not digits.
  final FocusNode _noteFocus = FocusNode();

  /// Share of the screen the keypad is allowed. A quarter leaves the category
  /// chips, the account/date row and the note field enough room to sit on one
  /// screen, which is what stops them needing a scroll.
  static const double _keypadHeightFraction = 0.25;

  /// Below this the keys stop being comfortably tappable, so a short screen
  /// gives the keypad more than its quarter rather than shrinking further.
  static const double _minKeypadHeight = 196;

  /// Whether the system keyboard is currently on screen. Tracked so a
  /// close can be told apart from an open — see [didChangeMetrics].
  bool _keyboardOpen = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noteFocus.addListener(_onNoteFocusChanged);
  }

  void _onNoteFocusChanged() => setState(() {});

  /// Dismissing the system keyboard does not take focus off the field that
  /// raised it — Android's back gesture and the swipe-down both leave the
  /// note focused. Without this, closing the keyboard that way left the
  /// keypad hidden and nothing in its place, with no way back to the digits.
  ///
  /// Focus is released on the keyboard's close, so "the note is being typed
  /// into" and "the keyboard is up" can never drift apart.
  @override
  void didChangeMetrics() {
    // The new inset is not readable until the frame the change lands in.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      final bool open = View.of(context).viewInsets.bottom > 0;
      // Only a genuine open → closed transition counts. Reacting to a bare
      // "inset is zero" would fire in the moment between the field taking
      // focus and the keyboard animating in, and close it again immediately.
      if (open == _keyboardOpen) return;
      _keyboardOpen = open;
      if (!open && _noteFocus.hasFocus) _noteFocus.unfocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteFocus
      ..removeListener(_onNoteFocusChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  TransactionEditorController get _controller =>
      ref.read(transactionEditorProvider(_args).notifier);

  @override
  Widget build(BuildContext context) {
    final TransactionEditorState state = ref.watch(
      transactionEditorProvider(_args),
    );
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? context.l10n.editTransaction
              : context.l10n.addTransaction,
        ),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              tooltip: context.l10n.actionDelete,
              onPressed: state.saving ? null : _confirmDelete,
              icon: Icon(
                CupertinoIcons.trash,
                color: context.colors.error,
              ),
            ),
        ],
      ),
      body: SafeArea(
        // A tap on any empty part of the form puts the note down and brings
        // the keypad back. The fields and chips have their own recognisers and
        // still win their own taps; this only catches what nothing else did.
        //
        // Belt and braces alongside [didChangeMetrics]: some keyboards — a
        // floating IME, a hardware one — never report a view inset, so their
        // dismissal is invisible to the framework. This works regardless.
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _noteFocus.unfocus,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.sm,
              AppSizes.screenPadding,
              AppSizes.sm,
            ),
            child: Column(
              children: <Widget>[
                SegmentedTabs<TransactionType>(
                  values: const <TransactionType>[
                    TransactionType.expense,
                    TransactionType.income,
                    TransactionType.transfer,
                  ],
                  labels: <String>[
                    context.l10n.expense,
                    context.l10n.income,
                    context.l10n.transfer,
                  ],
                  activeColors: const <Color>[
                    AppColors.expense,
                    AppColors.income,
                    AppColors.transfer,
                  ],
                  selected: state.type,
                  onChanged: _controller.setType,
                ),
                AppSizes.gapMd,
                // Tapping the amount dismisses the note's keyboard, which brings
                // the keypad back — the obvious way to return to editing the
                // figure after typing a note.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _noteFocus.unfocus,
                  child: _AmountDisplay(
                    state: state,
                    money: money,
                    heroTag: _isEditing ? null : AppShell.addTransactionHeroTag,
                  ),
                ),
                AppSizes.gapMd,
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) =>
                        _formAndKeypad(state, box.maxHeight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          0,
          AppSizes.screenPadding,
          AppSizes.md,
        ),
        child: FilledButton(
          onPressed: state.saving ? null : _save,
          child: state.saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.actionSave),
        ),
      ),
    );
  }

  /// A quarter of the screen, floored at [_minKeypadHeight] so the keys stay
  /// usable on a small device.
  double _keypadHeight(BuildContext context) {
    final double screen = MediaQuery.sizeOf(context).height;
    final double quarter = screen * _keypadHeightFraction;
    return quarter < _minKeypadHeight ? _minKeypadHeight : quarter;
  }

  /// The form takes only the height it needs and the keypad fills the rest,
  /// so tall screens get bigger keys instead of an empty gap between the note
  /// and the keypad. The keypad never drops below [_keypadHeight]; on short
  /// screens the form scrolls instead.
  Widget _formAndKeypad(TransactionEditorState state, double maxHeight) {
    final Widget form = SingleChildScrollView(
      child: Column(
        children: <Widget>[
          if (!state.type.isTransfer) ...<Widget>[
            CategoryChipRow(
              type: state.type.isIncome
                  ? CategoryType.income
                  : CategoryType.expense,
              selectedId: state.categoryId,
              onSelected: _controller.setCategory,
              onMore: _pickCategory,
            ),
            AppSizes.gapMd,
          ],
          _accountAndDateFields(state),
          AppSizes.gapMd,
          TextField(
            controller: _noteController,
            focusNode: _noteFocus,
            onChanged: _controller.setNote,
            // Done gives the keyboard its own way out, which puts the keypad
            // and the Save button back within reach without the user having
            // to guess where to tap.
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _noteFocus.unfocus(),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 140,
            decoration: InputDecoration(
              labelText: '${context.l10n.note} · ${context.l10n.labelOptional}',
              hintText: context.l10n.notePlaceholder,
              counterText: '',
              prefixIcon: const Icon(CupertinoIcons.square_pencil),
            ),
          ),
        ],
      ),
    );

    if (_noteFocus.hasFocus) return form;

    final double keypadMin = _keypadHeight(context);
    return Column(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (maxHeight - keypadMin - AppSizes.sm).clamp(
              0,
              double.infinity,
            ),
          ),
          child: form,
        ),
        AppSizes.gapSm,
        Expanded(
          child: CalculatorKeypad(
            onDigit: _controller.tapDigit,
            onDecimal: _controller.tapDecimal,
            onOperation: _controller.tapOperation,
            onEquals: _controller.tapEquals,
            onBackspace: _controller.tapBackspace,
            onClear: _controller.tapClear,
          ),
        ),
      ],
    );
  }

  Widget _accountAndDateFields(TransactionEditorState state) {
    final Map<String, AccountModel> accounts = ref.watch(accountMapProvider);
    final String? fromName = accounts[state.accountId]?.name;
    final String? toName = accounts[state.toAccountId]?.name;
    final DateLabels dates = ref.watch(dateLabelsProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);

    final DateTime now = DateTime.now();
    final bool isToday = state.date.year == now.year &&
        state.date.month == now.month &&
        state.date.day == now.day;
    final Widget dateField = EditorFieldRow(
      icon: CupertinoIcons.calendar,
      label: context.l10n.date,
      // The half-width row has no room for the full "Sep 5, 2026 · 1:17 PM"
      // string; today's date is the common case, so just the time is enough
      // to tell it's "now" — a picked past/future date still shows its day.
      value: money.localizeDigits(
        isToday ? dates.time(state.date) : dates.dateTime(state.date),
      ),
      emphasised: true,
      onTap: _pickDateTime,
    );

    if (!state.type.isTransfer) {
      return Row(
        children: <Widget>[
          Expanded(
            child: EditorFieldRow(
              icon: CupertinoIcons.creditcard_fill,
              label: context.l10n.account,
              value: fromName ?? context.l10n.selectAccount,
              emphasised: fromName != null,
              onTap: () => _pickAccount(isDestination: false),
            ),
          ),
          AppSizes.hGapSm,
          Expanded(child: dateField),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: EditorFieldRow(
                icon: CupertinoIcons.square_arrow_right,
                label: context.l10n.fromAccount,
                value: fromName ?? context.l10n.selectAccount,
                emphasised: fromName != null,
                onTap: () => _pickAccount(isDestination: false),
              ),
            ),
            AppSizes.hGapSm,
            Expanded(
              child: EditorFieldRow(
                icon: CupertinoIcons.arrow_turn_down_right,
                label: context.l10n.toAccount,
                value: toName ?? context.l10n.selectAccount,
                emphasised: toName != null,
                onTap: () => _pickAccount(isDestination: true),
              ),
            ),
          ],
        ),
        AppSizes.gapMd,
        dateField,
      ],
    );
  }

  Future<void> _pickCategory() async {
    final TransactionEditorState state = ref.read(
      transactionEditorProvider(_args),
    );
    final String? id = await showCategoryPicker(
      context,
      type: state.type.isIncome ? CategoryType.income : CategoryType.expense,
      selectedId: state.categoryId,
    );
    if (id != null) _controller.setCategory(id);
  }

  Future<void> _pickAccount({required bool isDestination}) async {
    final TransactionEditorState state = ref.read(
      transactionEditorProvider(_args),
    );
    final String? id = await showAccountPicker(
      context,
      title:
          isDestination ? context.l10n.toAccount : context.l10n.selectAccount,
      selectedId: isDestination ? state.toAccountId : state.accountId,
      excludeId: state.type.isTransfer
          ? (isDestination ? state.accountId : state.toAccountId)
          : null,
    );
    if (id == null) return;
    if (isDestination) {
      _controller.setToAccount(id);
    } else {
      _controller.setAccount(id);
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime current = ref.read(transactionEditorProvider(_args)).date;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date == null || !mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    _controller.setDate(
      DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? current.hour,
        time?.minute ?? current.minute,
      ),
    );
  }

  Future<void> _save() async {
    final AppFailure? failure = await _controller.save();
    if (!mounted) return;

    if (failure != null) {
      AppSnack.error(context, failure.localizedMessage(context.l10n));
      return;
    }

    final EditorError? error = ref.read(transactionEditorProvider(_args)).error;
    if (error != null) {
      AppSnack.error(context, _errorMessage(error));
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    AppSnack.success(context, context.l10n.transactionSaved);
    Navigator.of(context).pop();
  }

  String _errorMessage(EditorError error) => switch (error) {
        EditorError.amount => context.l10n.errorAmountRequired,
        EditorError.category => context.l10n.errorCategoryRequired,
        EditorError.account => context.l10n.errorAccountRequired,
        EditorError.sameAccount => context.l10n.errorSameAccount,
      };

  Future<void> _confirmDelete() async {
    final TransactionModel? existing = widget.existing;
    if (existing == null) return;

    final bool confirmed = await showConfirmDialog(
      context,
      title: context.l10n.deleteTransactionTitle,
      message: context.l10n.deleteTransactionBody,
      confirmLabel: context.l10n.actionDelete,
    );
    if (!confirmed || !mounted) return;

    final bool deleted = await ref
        .read(transactionActionsProvider)
        .deleteWithUndo(context, transaction: existing);
    if (deleted && mounted) Navigator.of(context).pop();
  }
}

/// The big amount readout, tinted by transaction type, with the pending
/// calculator step above it and any validation error below.
class _AmountDisplay extends ConsumerWidget {
  const _AmountDisplay({
    required this.state,
    required this.money,
    required this.heroTag,
  });

  final TransactionEditorState state;
  final MoneyFormatter money;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String language = ref.watch(
      settingsProvider.select((AppSettings s) => s.languageCode),
    );
    final Map<String, CategoryModel> categories =
        ref.watch(categoryMapProvider);
    final CategoryModel? category =
        state.categoryId == null ? null : categories[state.categoryId];

    final Color tint = AmountText.colorFor(state.type);
    final bool hasAmountError = state.error == EditorError.amount;

    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppSizes.brLg,
        color: tint.withValues(alpha: context.isDark ? 0.16 : 0.08),
        border: Border.all(
          color: hasAmountError
              ? context.colors.error
              : tint.withValues(alpha: 0.35),
          width: hasAmountError ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 18,
            child: Text(
              state.calculator.pendingLabel.isEmpty
                  ? (category?.displayName(language) ?? '')
                  : money.localizeDigits(state.calculator.pendingLabel),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelMedium?.copyWith(color: tint),
            ),
          ),
          AppSizes.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              money.format(state.calculator.value),
              maxLines: 1,
              style: context.texts.displaySmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (hasAmountError) ...<Widget>[
            AppSizes.gapSm,
            Text(
              context.l10n.errorAmountRequired,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
        ],
      ),
    );

    if (heroTag == null) return card;
    return Hero(
      tag: heroTag!,
      // The FAB flying into this card would otherwise carry its circular
      // Material shape through the flight.
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection direction,
        BuildContext fromContext,
        BuildContext toContext,
      ) =>
          FadeTransition(opacity: animation, child: card),
      child: Material(color: Colors.transparent, child: card),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/transaction_model.dart';
import 'transaction_providers.dart';

/// What the editor is being opened with: an existing row, or a blank form
/// pre-set to a type.
typedef EditorArgs = ({TransactionModel? existing, TransactionType initialType});

/// Validation problems, resolved to localised text by the screen.
enum EditorError { amount, category, account, sameAccount }

@immutable
class TransactionEditorState {
  const TransactionEditorState({
    required this.type,
    required this.calculator,
    required this.date,
    required this.note,
    this.id,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.error,
    this.saving = false,
  });

  final String? id;
  final TransactionType type;
  final CalculatorState calculator;
  final String? categoryId;
  final String? accountId;
  final String? toAccountId;
  final String note;
  final DateTime date;
  final EditorError? error;
  final bool saving;

  bool get isEditing => id != null;

  double get amount => Validators.roundMoney(
    calculator.hasPendingOperation
        ? calculator.equals().value
        : calculator.value,
  );

  TransactionEditorState copyWith({
    TransactionType? type,
    CalculatorState? calculator,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    String? toAccountId,
    bool clearToAccount = false,
    String? note,
    DateTime? date,
    EditorError? error,
    bool clearError = false,
    bool? saving,
  }) {
    return TransactionEditorState(
      id: id,
      type: type ?? this.type,
      calculator: calculator ?? this.calculator,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      accountId: accountId ?? this.accountId,
      toAccountId: clearToAccount ? null : (toAccountId ?? this.toAccountId),
      note: note ?? this.note,
      date: date ?? this.date,
      error: clearError ? null : (error ?? this.error),
      saving: saving ?? this.saving,
    );
  }
}

final AutoDisposeNotifierProviderFamily<
  TransactionEditorController,
  TransactionEditorState,
  EditorArgs
>
transactionEditorProvider =
    NotifierProvider.autoDispose
        .family<
          TransactionEditorController,
          TransactionEditorState,
          EditorArgs
        >(TransactionEditorController.new);

class TransactionEditorController
    extends AutoDisposeFamilyNotifier<TransactionEditorState, EditorArgs> {
  @override
  TransactionEditorState build(EditorArgs arg) {
    final TransactionModel? existing = arg.existing;
    if (existing != null) {
      return TransactionEditorState(
        id: existing.id,
        type: existing.type,
        calculator: CalculatorState.fromAmount(existing.amount),
        categoryId: existing.categoryId,
        accountId: existing.accountId,
        toAccountId: existing.toAccountId,
        note: existing.note,
        date: existing.date,
      );
    }

    // Defaults are read, not watched: a late-arriving accounts snapshot must
    // never reset a form the user has already started filling in.
    final List<AccountModel> accounts = ref.read(activeAccountsProvider);
    return TransactionEditorState(
      type: arg.initialType,
      calculator: const CalculatorState(),
      date: DateTime.now(),
      note: '',
      accountId: accounts.isEmpty ? null : accounts.first.id,
      categoryId: _defaultCategoryFor(arg.initialType),
    );
  }

  String? _defaultCategoryFor(TransactionType type) {
    if (type.isTransfer) return null;
    final CategoryType categoryType = type.isIncome
        ? CategoryType.income
        : CategoryType.expense;
    final List<CategoryModel> categories = ref.read(
      categoriesByTypeProvider(categoryType),
    );
    return categories.isEmpty ? null : categories.first.id;
  }

  void setType(TransactionType type) {
    if (type == state.type) return;
    // Switching sides invalidates the chosen category, which is type-specific.
    state = state.copyWith(
      type: type,
      clearError: true,
      categoryId: type.isTransfer ? null : _defaultCategoryFor(type),
      clearCategory: type.isTransfer,
      clearToAccount: !type.isTransfer,
    );
  }

  void tapDigit(String digit) =>
      state = state.copyWith(
        calculator: state.calculator.digit(digit),
        clearError: true,
      );

  void tapDecimal() =>
      state = state.copyWith(calculator: state.calculator.decimalPoint());

  void tapOperation(CalcOp op) =>
      state = state.copyWith(calculator: state.calculator.applyOperation(op));

  void tapEquals() =>
      state = state.copyWith(calculator: state.calculator.equals());

  void tapBackspace() =>
      state = state.copyWith(calculator: state.calculator.backspace());

  void tapClear() =>
      state = state.copyWith(calculator: state.calculator.clear());

  void setCategory(String id) =>
      state = state.copyWith(categoryId: id, clearError: true);

  void setAccount(String id) =>
      state = state.copyWith(accountId: id, clearError: true);

  void setToAccount(String id) =>
      state = state.copyWith(toAccountId: id, clearError: true);

  void setNote(String note) => state = state.copyWith(note: note);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  EditorError? _validate() {
    if (state.amount <= 0) return EditorError.amount;
    if (state.accountId == null || state.accountId!.isEmpty) {
      return EditorError.account;
    }
    if (state.type.isTransfer) {
      if (state.toAccountId == null || state.toAccountId!.isEmpty) {
        return EditorError.account;
      }
      if (state.toAccountId == state.accountId) return EditorError.sameAccount;
      return null;
    }
    if (state.categoryId == null || state.categoryId!.isEmpty) {
      return EditorError.category;
    }
    return null;
  }

  /// Saves the form. Returns `null` on success, or the [AppFailure] to show.
  /// Validation problems are reported through `state.error` instead.
  Future<AppFailure?> save() async {
    final EditorError? error = _validate();
    if (error != null) {
      state = state.copyWith(error: error);
      return null;
    }

    state = state.copyWith(saving: true, clearError: true);
    final DateTime now = DateTime.now();

    final TransactionModel model = TransactionModel(
      id: state.id ?? '',
      type: state.type,
      amount: state.amount,
      categoryId: state.type.isTransfer ? null : state.categoryId,
      accountId: state.accountId!,
      toAccountId: state.type.isTransfer ? state.toAccountId : null,
      note: state.note.trim(),
      date: state.date,
      createdAt: arg.existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (state.isEditing) {
        await ref.read(transactionRepositoryProvider).update(model);
      } else {
        await ref.read(transactionRepositoryProvider).create(model);
      }
      state = state.copyWith(saving: false);
      return null;
    } catch (caught) {
      state = state.copyWith(saving: false);
      return AppFailure.from(caught);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../data/transaction_model.dart';
import '../../data/transaction_repository.dart';
import 'transaction_providers.dart';

/// Delete/restore behaviour shared by the dashboard's recent list and the
/// transactions screen, so both offer the same confirm → delete → undo flow.
final Provider<TransactionActions> transactionActionsProvider =
    Provider<TransactionActions>(
      (Ref ref) => TransactionActions(ref.watch(transactionRepositoryProvider)),
    );

class TransactionActions {
  const TransactionActions(this._repository);

  final TransactionRepository _repository;

  /// Deletes [transaction] and shows an undo snackbar. Returns `false` when
  /// the delete failed, so callers can leave the row in place.
  Future<bool> deleteWithUndo(
    BuildContext context, {
    required TransactionModel transaction,
  }) async {
    try {
      await _repository.delete(transaction.id);
    } catch (error) {
      if (context.mounted) {
        AppSnack.error(
          context,
          AppFailure.from(error).localizedMessage(context.l10n),
        );
      }
      return false;
    }

    if (!context.mounted) return true;
    AppSnack.undoable(
      context,
      message: context.l10n.transactionDeleted,
      undoLabel: context.l10n.actionUndo,
      onUndo: () => _repository.restore(transaction).ignore(),
    );
    return true;
  }

  /// Bulk delete from the multi-select bar, also undoable.
  Future<bool> deleteManyWithUndo(
    BuildContext context, {
    required List<TransactionModel> transactions,
  }) async {
    if (transactions.isEmpty) return false;
    try {
      await _repository.deleteMany(
        transactions.map((TransactionModel t) => t.id),
      );
    } catch (error) {
      if (context.mounted) {
        AppSnack.error(
          context,
          AppFailure.from(error).localizedMessage(context.l10n),
        );
      }
      return false;
    }

    if (!context.mounted) return true;
    AppSnack.undoable(
      context,
      message: context.l10n.transactionDeleted,
      undoLabel: context.l10n.actionUndo,
      onUndo: () => _repository.restoreMany(transactions).ignore(),
    );
    return true;
  }
}

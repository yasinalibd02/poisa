import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../data/transaction_model.dart';
import '../providers/transaction_actions.dart';
import 'transaction_tile.dart';

/// A transaction row that can be swiped away: confirm dialog first, then the
/// delete, then an undo snackbar.
class DismissibleTransaction extends ConsumerWidget {
  const DismissibleTransaction({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    this.showTime = false,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;
  final bool showTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget tile = TransactionTile(
      transaction: transaction,
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      selectionMode: selectionMode,
      showTime: showTime,
    );

    // Swiping during multi-select would fight the selection gesture.
    if (selectionMode) return tile;

    return Dismissible(
      key: ValueKey<String>('dismiss-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      confirmDismiss: (_) async {
        final bool confirmed = await showConfirmDialog(
          context,
          title: context.l10n.deleteTransactionTitle,
          message: context.l10n.deleteTransactionBody,
          confirmLabel: context.l10n.actionDelete,
        );
        if (!confirmed || !context.mounted) return false;
        return ref
            .read(transactionActionsProvider)
            .deleteWithUndo(context, transaction: transaction);
      },
      child: tile,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.14),
        borderRadius: AppSizes.brMd,
      ),
      child: Icon(CupertinoIcons.trash, color: context.colors.error),
    );
  }
}

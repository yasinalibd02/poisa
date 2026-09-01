import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../extensions/context_x.dart';

/// Confirmation dialog used before every destructive action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = true,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? dialogContext.l10n.actionCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: dialogContext.colors.error,
                    foregroundColor: dialogContext.colors.onError,
                    minimumSize: const Size(88, 44),
                  )
                : FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel ?? dialogContext.l10n.actionConfirm),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Second-stage confirmation that requires typing a word — used for the
/// irreversible "delete account and all data" flow.
Future<bool> showTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String requiredWord,
  required String confirmLabel,
}) async {
  final TextEditingController controller = TextEditingController();
  try {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final bool matches = controller.text.trim() == requiredWord;
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(message),
                  AppSizes.gapLg,
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(hintText: requiredWord),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(dialogContext.l10n.actionCancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: dialogContext.colors.error,
                    foregroundColor: dialogContext.colors.onError,
                    minimumSize: const Size(88, 44),
                  ),
                  onPressed: matches
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  } finally {
    controller.dispose();
  }
}

/// Snackbar helpers. Every one of these also fires the matching haptic, so
/// save/delete feedback is consistent across the app.
abstract final class AppSnack {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void success(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    show(context, message);
  }

  static void error(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.colors.error,
        ),
      );
  }

  /// Destructive action with an undo affordance.
  static void undoable(
    BuildContext context, {
    required String message,
    required String undoLabel,
    required VoidCallback onUndo,
  }) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: undoLabel, onPressed: onUndo),
        ),
      );
  }
}

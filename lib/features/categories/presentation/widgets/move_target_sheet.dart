import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/common_widgets.dart';

/// One option in the "move transactions to…" list.
class MoveTarget {
  const MoveTarget({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.colorHex,
  });

  final String id;
  final String label;
  final String iconKey;
  final String colorHex;
}

/// Shown when a category or account still has transactions: the user picks a
/// destination, and only then can the original be deleted.
///
/// Returns the chosen target id, or `null` if the user backed out.
Future<String?> showMoveTargetSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String pickerLabel,
  required String confirmLabel,
  required List<MoveTarget> options,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MoveTargetSheet(
      title: title,
      message: message,
      pickerLabel: pickerLabel,
      confirmLabel: confirmLabel,
      options: options,
    ),
  );
}

class _MoveTargetSheet extends StatefulWidget {
  const _MoveTargetSheet({
    required this.title,
    required this.message,
    required this.pickerLabel,
    required this.confirmLabel,
    required this.options,
  });

  final String title;
  final String message;
  final String pickerLabel;
  final String confirmLabel;
  final List<MoveTarget> options;

  @override
  State<_MoveTargetSheet> createState() => _MoveTargetSheetState();
}

class _MoveTargetSheetState extends State<_MoveTargetSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.title, style: context.texts.titleMedium),
                  AppSizes.gapSm,
                  Text(
                    widget.message,
                    style: context.texts.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSizes.gapLg,
                  Text(widget.pickerLabel, style: context.texts.labelLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.only(bottom: AppSizes.lg),
                itemCount: widget.options.length,
                itemBuilder: (BuildContext context, int index) {
                  final MoveTarget option = widget.options[index];
                  final bool selected = option.id == _selectedId;
                  return ListTile(
                    leading: IconBadge(
                      iconKey: option.iconKey,
                      colorHex: option.colorHex,
                      size: 40,
                      selected: selected,
                    ),
                    title: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.primary,
                          )
                        : null,
                    onTap: () => setState(() => _selectedId = option.id),
                  );
                },
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
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                ),
                onPressed: _selectedId == null
                    ? null
                    : () => Navigator.of(context).pop(_selectedId),
                child: Text(widget.confirmLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}

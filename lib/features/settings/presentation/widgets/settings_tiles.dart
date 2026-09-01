import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// Grouped card of settings rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.xs,
            AppSizes.xl,
            AppSizes.xs,
            AppSizes.sm,
          ),
          child: Text(
            title,
            style: context.texts.labelLarge?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppSizes.brLg,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// A single settings row: icon, label, optional value, optional trailing.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.description,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? description;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color tint = destructive
        ? context.colors.error
        : context.colors.onSurfaceVariant;

    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(),
      leading: Icon(icon, color: tint, size: 22),
      title: Text(
        label,
        style: context.texts.bodyLarge?.copyWith(
          color: destructive ? context.colors.error : context.colors.onSurface,
        ),
      ),
      subtitle: description == null
          ? null
          : Text(description!, style: context.texts.bodySmall),
      trailing:
          trailing ??
          (value == null
              ? (onTap == null
                    ? null
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: context.colors.onSurfaceVariant,
                      ))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: context.screenWidth * 0.34,
                      ),
                      child: Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ],
                )),
    );
  }
}

/// Thin separator between rows in a [SettingsSection].
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 56, color: context.colors.outlineVariant);
}

/// Reusable single-choice bottom sheet used by language, theme, currency and
/// the first-day pickers.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<({T value, String label, String? subtitle})> options,
  required T selected,
  bool searchable = false,
  String? searchHint,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ChoiceSheet<T>(
      title: title,
      options: options,
      selected: selected,
      searchable: searchable,
      searchHint: searchHint,
    ),
  );
}

class _ChoiceSheet<T> extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
    required this.searchHint,
  });

  final String title;
  final List<({T value, String label, String? subtitle})> options;
  final T selected;
  final bool searchable;
  final String? searchHint;

  @override
  State<_ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<_ChoiceSheet<T>> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _query.trim().toLowerCase();
    final List<({T value, String label, String? subtitle})> visible = query
            .isEmpty
        ? widget.options
        : widget.options
              .where(
                (({T value, String label, String? subtitle}) option) =>
                    option.label.toLowerCase().contains(query) ||
                    (option.subtitle?.toLowerCase().contains(query) ?? false),
              )
              .toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.searchable ? 0.75 : 0.5,
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
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(widget.title, style: context.texts.titleMedium),
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  0,
                  AppSizes.lg,
                  AppSizes.md,
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (String value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.only(bottom: AppSizes.xl),
                itemCount: visible.length,
                itemBuilder: (BuildContext context, int index) {
                  final ({T value, String label, String? subtitle}) option =
                      visible[index];
                  final bool isSelected = option.value == widget.selected;
                  return ListTile(
                    title: Text(option.label),
                    subtitle: option.subtitle == null
                        ? null
                        : Text(option.subtitle!),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(option.value),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

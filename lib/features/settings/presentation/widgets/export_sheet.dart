import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../providers/export_actions.dart';

/// Where a finished export should go.
enum ExportDestination { share, save }

/// Asks for the file format, then for what to do with it. Two short sheets
/// rather than one four-way list, so neither question is buried in the other.
Future<ExportFormat?> showExportFormatSheet(BuildContext context) {
  return _showOptions<ExportFormat>(
    context,
    title: context.l10n.exportChooseFormat,
    options: <_Option<ExportFormat>>[
      _Option<ExportFormat>(
        value: ExportFormat.csv,
        icon: Icons.table_chart_rounded,
        label: context.l10n.exportFormatCsv,
        description: context.l10n.exportFormatCsvBody,
      ),
      _Option<ExportFormat>(
        value: ExportFormat.pdf,
        icon: Icons.picture_as_pdf_rounded,
        label: context.l10n.exportFormatPdf,
        description: context.l10n.exportFormatPdfBody,
      ),
    ],
  );
}

Future<ExportDestination?> showExportDestinationSheet(BuildContext context) {
  return _showOptions<ExportDestination>(
    context,
    title: context.l10n.exportData,
    options: <_Option<ExportDestination>>[
      _Option<ExportDestination>(
        value: ExportDestination.save,
        icon: Icons.download_rounded,
        label: context.l10n.exportActionSave,
        description: context.l10n.exportActionSaveBody,
      ),
      _Option<ExportDestination>(
        value: ExportDestination.share,
        icon: Icons.ios_share_rounded,
        label: context.l10n.exportActionShare,
        description: context.l10n.exportActionShareBody,
      ),
    ],
  );
}

class _Option<T> {
  const _Option({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
  });

  final T value;
  final IconData icon;
  final String label;
  final String description;
}

Future<T?> _showOptions<T>(
  BuildContext context, {
  required String title,
  required List<_Option<T>> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.xl,
              0,
              AppSizes.xl,
              AppSizes.md,
            ),
            child: Text(title, style: sheetContext.texts.titleMedium),
          ),
          for (final _Option<T> option in options)
            ListTile(
              leading: Icon(option.icon, color: sheetContext.colors.primary),
              title: Text(option.label),
              subtitle: Text(option.description),
              onTap: () => Navigator.of(sheetContext).pop(option.value),
            ),
          AppSizes.gapMd,
        ],
      ),
    ),
  );
}

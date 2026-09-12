import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/file_save_service.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/app_settings.dart';
import 'settings_actions.dart';
import 'settings_provider.dart';

/// What the export is written as.
enum ExportFormat {
  csv,
  pdf;

  String get extension => this == ExportFormat.csv ? 'csv' : 'pdf';

  String get mimeType =>
      this == ExportFormat.csv ? 'text/csv' : 'application/pdf';
}

/// A built export, held in memory until the user says where it should go.
@immutable
class ExportFile {
  const ExportFile({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

final Provider<PdfExportService> pdfExportServiceProvider =
    Provider<PdfExportService>((Ref ref) => const PdfExportService());

final Provider<FileSaveService> fileSaveServiceProvider =
    Provider<FileSaveService>((Ref ref) => const FileSaveService());

final Provider<ExportActions> exportActionsProvider = Provider<ExportActions>(
  ExportActions.new,
);

/// Builds the export, then either hands it to the share sheet or writes it
/// where the user can find it. Splitting "build" from "deliver" is what lets
/// one rendering answer both.
class ExportActions {
  const ExportActions(this._ref);

  final Ref _ref;

  static final DateFormat _stamp = DateFormat('yyyyMMdd-HHmm');

  /// Renders the whole ledger. Returns `null` when there is nothing to export.
  ///
  /// [pdfLabels] is only read for [ExportFormat.pdf]; the CSV is deliberately
  /// written with English headers in the invariant locale so it opens cleanly
  /// in any spreadsheet.
  Future<ExportFile?> build({
    required ExportFormat format,
    required PdfReportLabels pdfLabels,
  }) async {
    final List<TransactionModel> transactions = await _ref
        .read(transactionRepositoryProvider)
        .fetchAll();
    if (transactions.isEmpty) return null;

    final Map<String, CategoryModel> categories = _ref.read(
      categoryMapProvider,
    );
    final Map<String, AccountModel> accounts = _ref.read(accountMapProvider);
    final AppSettings settings = _ref.read(settingsProvider);
    final String fileName =
        'poisa-export-${_stamp.format(DateTime.now())}.${format.extension}';

    final Uint8List bytes = switch (format) {
      ExportFormat.csv => Uint8List.fromList(
        utf8.encode(
          _ref
              .read(csvExportServiceProvider)
              .buildCsv(
                transactions: transactions,
                categories: categories,
                accounts: accounts,
              ),
        ),
      ),
      ExportFormat.pdf => await _ref
          .read(pdfExportServiceProvider)
          .build(
            transactions: transactions,
            categories: categories,
            accounts: accounts,
            labels: pdfLabels,
            languageCode: settings.languageCode,
            currencySymbol: settings.currencySymbol,
          ),
    };

    return ExportFile(
      fileName: fileName,
      mimeType: format.mimeType,
      bytes: bytes,
    );
  }

  /// Hands [file] to the system share sheet.
  Future<void> share(ExportFile file, {required String subject}) async {
    try {
      final File written = await _ref
          .read(fileSaveServiceProvider)
          .writeTemporary(fileName: file.fileName, bytes: file.bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(written.path, mimeType: file.mimeType)],
          subject: subject,
        ),
      );
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Writes [file] to the device's downloads folder, returning the location to
  /// show the user.
  Future<String> saveToDevice(ExportFile file) {
    return _ref
        .read(fileSaveServiceProvider)
        .saveToDownloads(
          fileName: file.fileName,
          mimeType: file.mimeType,
          bytes: file.bytes,
        );
  }
}

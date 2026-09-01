import 'dart:io';
import 'dart:ui' show Rect;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/accounts/data/account_model.dart';
import '../../features/categories/data/category_model.dart';
import '../../features/transactions/data/transaction_model.dart';
import '../utils/app_failure.dart';

/// Writes the ledger to a CSV file and hands it to the system share sheet.
///
/// The export is deliberately plain, Excel-friendly CSV in the invariant
/// locale (ISO dates, `.` decimals, English headers) so it opens cleanly in
/// any spreadsheet regardless of the app's UI language.
class CsvExportService {
  const CsvExportService();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  static const List<String> _headers = <String>[
    'Date',
    'Type',
    'Amount',
    'Category (EN)',
    'Category (BN)',
    'Account',
    'To account',
    'Note',
  ];

  String buildCsv({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
    required Map<String, AccountModel> accounts,
  }) {
    final StringBuffer buffer = StringBuffer()
      // BOM so Excel opens Bangla category names as UTF-8 rather than mojibake.
      ..write('﻿')
      ..writeln(_headers.map(_escape).join(','));

    for (final TransactionModel transaction in transactions) {
      final CategoryModel? category = categories[transaction.categoryId];
      final AccountModel? account = accounts[transaction.accountId];
      final AccountModel? toAccount = accounts[transaction.toAccountId];

      buffer.writeln(
        <String>[
          _dateFormat.format(transaction.date),
          transaction.type.name,
          transaction.amount.toStringAsFixed(2),
          category?.nameEn ?? '',
          category?.nameBn ?? '',
          account?.name ?? '',
          toAccount?.name ?? '',
          transaction.note,
        ].map(_escape).join(','),
      );
    }

    return buffer.toString();
  }

  /// Escapes a CSV field: quotes it when it contains a delimiter, a quote or a
  /// newline, and doubles any embedded quotes.
  static String _escape(String value) {
    final bool needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  /// Writes [csv] to a temporary file and opens the share sheet.
  Future<void> share({
    required String csv,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final File file = File('${directory.path}/kori-export-$stamp.csv');
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'text/csv')],
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Shares plain text (the "share app" action).
  Future<void> shareText(String text, {Rect? sharePositionOrigin}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: sharePositionOrigin),
      );
    } catch (error) {
      throw AppFailure.from(error);
    }
  }
}

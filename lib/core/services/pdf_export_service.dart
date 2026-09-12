import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/accounts/data/account_model.dart';
import '../../features/categories/data/category_model.dart';
import '../../features/transactions/data/transaction_model.dart';
import '../constants/enums.dart';
import '../utils/app_failure.dart';

/// Labels the report needs, resolved by the caller so this service stays free
/// of any dependency on `BuildContext`.
@immutable
class PdfReportLabels {
  const PdfReportLabels({
    required this.title,
    required this.generated,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.countOf,
    required this.pageOf,
    required this.date,
    required this.type,
    required this.category,
    required this.account,
    required this.note,
    required this.amount,
  });

  final String title;
  final String generated;
  final String totalIncome;
  final String totalExpense;
  final String net;

  /// "128 transactions", built from the count the document actually holds.
  final String Function(int count) countOf;

  /// Already-formatted "Page 1 of 4".
  final String Function(int current, int total) pageOf;

  final String date;
  final String type;
  final String category;
  final String account;
  final String note;
  final String amount;
}

/// Renders the ledger as a printable statement.
///
/// The document embeds Hind Siliguri rather than relying on a built-in font:
/// the PDF standard fonts have no Bengali glyphs at all, so a Bangla category
/// name would otherwise come out as a row of empty boxes.
class PdfExportService {
  const PdfExportService();

  static final DateFormat _rowDate = DateFormat('yyyy-MM-dd');

  Future<Uint8List> build({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
    required Map<String, AccountModel> accounts,
    required PdfReportLabels labels,
    required String languageCode,
    required String currencySymbol,
  }) async {
    try {
      final pw.Font regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/HindSiliguri-400.ttf'),
      );
      final pw.Font bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/HindSiliguri-600.ttf'),
      );

      double income = 0;
      double expense = 0;
      for (final TransactionModel t in transactions) {
        if (t.type == TransactionType.income) income += t.amount;
        if (t.type == TransactionType.expense) expense += t.amount;
      }

      final pw.Document document = pw.Document(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
      );

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (pw.Context context) => context.pageNumber == 1
              ? _header(labels, transactions.length)
              : pw.SizedBox(),
          footer: (pw.Context context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              labels.pageOf(context.pageNumber, context.pagesCount),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          build: (pw.Context context) => <pw.Widget>[
            _summary(
              labels: labels,
              income: income,
              expense: expense,
              currencySymbol: currencySymbol,
            ),
            pw.SizedBox(height: 18),
            _table(
              transactions: transactions,
              categories: categories,
              accounts: accounts,
              labels: labels,
              languageCode: languageCode,
              currencySymbol: currencySymbol,
            ),
          ],
        ),
      );

      return document.save();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  pw.Widget _header(PdfReportLabels labels, int count) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.8),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'Poisa',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _brand,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(labels.title, style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                labels.generated,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                labels.countOf(count),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _summary({
    required PdfReportLabels labels,
    required double income,
    required double expense,
    required String currencySymbol,
  }) {
    return pw.Row(
      children: <pw.Widget>[
        _summaryTile(labels.totalIncome, income, currencySymbol, _income),
        pw.SizedBox(width: 10),
        _summaryTile(labels.totalExpense, expense, currencySymbol, _expense),
        pw.SizedBox(width: 10),
        _summaryTile(labels.net, income - expense, currencySymbol, _brand),
      ],
    );
  }

  pw.Widget _summaryTile(
    String label,
    double value,
    String currencySymbol,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              _money(value, currencySymbol),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _table({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
    required Map<String, AccountModel> accounts,
    required PdfReportLabels labels,
    required String languageCode,
    required String currencySymbol,
  }) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerHeight: 22,
      cellHeight: 20,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(2.1),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.6),
        3: const pw.FlexColumnWidth(2.2),
        4: const pw.FlexColumnWidth(3),
        5: const pw.FlexColumnWidth(2.2),
      },
      cellAlignments: <int, pw.Alignment>{
        5: pw.Alignment.centerRight,
      },
      headers: <String>[
        labels.date,
        labels.type,
        labels.category,
        labels.account,
        labels.note,
        labels.amount,
      ],
      data: <List<String>>[
        for (final TransactionModel t in transactions)
          <String>[
            _rowDate.format(t.date),
            t.type.name,
            categories[t.categoryId]?.displayName(languageCode) ?? '—',
            accounts[t.accountId]?.name ?? '—',
            t.note,
            _signed(t, currencySymbol),
          ],
      ],
    );
  }

  /// Amounts are written in the invariant locale — a statement someone may
  /// hand to a bank or an accountant should not change shape with the app's
  /// numeral preference.
  static String _money(double value, String symbol) {
    final String body = value.abs().toStringAsFixed(2);
    return '${value < 0 ? '-' : ''}$symbol$body';
  }

  static String _signed(TransactionModel t, String symbol) => switch (t.type) {
    TransactionType.income => '+${_money(t.amount, symbol)}',
    TransactionType.expense => '-${_money(t.amount, symbol)}',
    TransactionType.transfer => _money(t.amount, symbol),
  };

  static const PdfColor _brand = PdfColor.fromInt(0xFF1B7F6B);
  static const PdfColor _income = PdfColor.fromInt(0xFF2E9E5B);
  static const PdfColor _expense = PdfColor.fromInt(0xFFE0553C);
}

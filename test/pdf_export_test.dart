import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kori/core/constants/enums.dart';
import 'package:kori/core/services/pdf_export_service.dart';
import 'package:kori/features/accounts/data/account_model.dart';
import 'package:kori/features/categories/data/category_model.dart';
import 'package:kori/features/transactions/data/transaction_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a PDF with Bangla category names', () async {
    final DateTime now = DateTime(2026, 9, 12, 13, 5);
    final List<TransactionModel> rows = <TransactionModel>[
      for (int i = 0; i < 60; i++)
        TransactionModel(
          id: 'tx$i',
          type: i.isEven ? TransactionType.expense : TransactionType.income,
          amount: 120.5 + i,
          categoryId: 'seed_expense_food',
          accountId: 'seed_cash',
          toAccountId: null,
          note: 'নোট $i',
          date: now.subtract(Duration(days: i)),
          createdAt: now,
          updatedAt: now,
        ),
    ];

    final Uint8List bytes = await const PdfExportService().build(
      transactions: rows,
      categories: <String, CategoryModel>{
        'seed_expense_food': CategoryModel(
          id: 'seed_expense_food',
          nameEn: 'Food',
          nameBn: 'খাবার',
          type: CategoryType.expense,
          icon: 'restaurant',
          colorHex: '#E0553C',
          isDefault: true,
          sortOrder: 0,
          createdAt: now,
        ),
      },
      accounts: <String, AccountModel>{
        'seed_cash': AccountModel(
          id: 'seed_cash',
          name: 'নগদ',
          type: AccountType.cash,
          icon: 'cash',
          colorHex: '#1B7F6B',
          openingBalance: 0,
          isArchived: false,
          sortOrder: 0,
          createdAt: now,
        ),
      },
      labels: PdfReportLabels(
        title: 'লেনদেনের বিবরণী',
        generated: 'তৈরি হয়েছে ১২ সেপ্টেম্বর ২০২৬',
        totalIncome: 'মোট আয়',
        totalExpense: 'মোট খরচ',
        net: 'নিট',
        countOf: (int c) => '$c টি লেনদেন',
        pageOf: (int a, int b) => 'পৃষ্ঠা $a / $b',
        date: 'তারিখ',
        type: 'ধরন',
        category: 'ক্যাটাগরি',
        account: 'অ্যাকাউন্ট',
        note: 'নোট',
        amount: 'পরিমাণ',
      ),
      languageCode: 'bn',
      currencySymbol: '৳',
    );

    expect(bytes.length, greaterThan(2000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kori/core/constants/default_seed_data.dart';
import 'package:kori/core/constants/enums.dart';
import 'package:kori/features/loans/presentation/providers/loan_providers.dart';
import 'package:kori/features/transactions/data/transaction_model.dart';

TransactionModel _tx({
  required String id,
  required TransactionType type,
  required double amount,
  required String categoryId,
}) {
  final DateTime now = DateTime(2026, 9, 12);
  return TransactionModel(
    id: id,
    type: type,
    amount: amount,
    categoryId: categoryId,
    accountId: 'seed_cash',
    toAccountId: null,
    note: '',
    date: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('LoanLeg', () {
    test('maps each seeded lending category to its leg', () {
      expect(
        LoanLeg.forCategory(DefaultSeedData.loanGivenId),
        LoanLeg.given,
      );
      expect(
        LoanLeg.forCategory(DefaultSeedData.loanRecoveredId),
        LoanLeg.recovered,
      );
      expect(
        LoanLeg.forCategory(DefaultSeedData.loanTakenId),
        LoanLeg.taken,
      );
      expect(
        LoanLeg.forCategory(DefaultSeedData.loanRepaidId),
        LoanLeg.repaid,
      );
    });

    test('ignores ordinary and missing categories', () {
      expect(LoanLeg.forCategory('seed_expense_food'), isNull);
      expect(LoanLeg.forCategory(null), isNull);
    });
  });

  group('LoanLedger', () {
    test('nets each side down to what is still outstanding', () {
      const LoanLedger ledger = LoanLedger(
        given: 5000,
        recovered: 1500,
        taken: 2000,
        repaid: 500,
        transactions: <TransactionModel>[],
      );

      expect(ledger.receivable, 3500);
      expect(ledger.payable, 1500);
      expect(ledger.net, 2000);
    });

    test('reports a negative net when more is owed than is due back', () {
      const LoanLedger ledger = LoanLedger(
        given: 1000,
        recovered: 0,
        taken: 4000,
        repaid: 250,
        transactions: <TransactionModel>[],
      );

      expect(ledger.receivable, 1000);
      expect(ledger.payable, 3750);
      expect(ledger.net, -2750);
    });

    test('forLeg selects only that leg\'s rows', () {
      final TransactionModel lent = _tx(
        id: 'a',
        type: TransactionType.expense,
        amount: 800,
        categoryId: DefaultSeedData.loanGivenId,
      );
      final TransactionModel borrowed = _tx(
        id: 'b',
        type: TransactionType.income,
        amount: 300,
        categoryId: DefaultSeedData.loanTakenId,
      );

      final LoanLedger ledger = LoanLedger(
        given: 800,
        recovered: 0,
        taken: 300,
        repaid: 0,
        transactions: <TransactionModel>[lent, borrowed],
      );

      expect(ledger.forLeg(LoanLeg.given), <TransactionModel>[lent]);
      expect(ledger.forLeg(LoanLeg.taken), <TransactionModel>[borrowed]);
      expect(ledger.forLeg(LoanLeg.repaid), isEmpty);
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/default_seed_data.dart';
import '../../../../core/utils/validators.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// Which side of the lending ledger a transaction sits on.
enum LoanLeg {
  /// Money out, to be paid back to you.
  given,

  /// Money in, settling something you lent out.
  recovered,

  /// Money in, to be paid back by you.
  taken,

  /// Money out, settling something you borrowed.
  repaid;

  /// The seeded category this leg is recorded under. A transaction belongs to
  /// the lending ledger purely by category, so nothing had to be added to
  /// [TransactionModel] and existing rows are picked up automatically.
  String get categoryId => switch (this) {
    LoanLeg.given => DefaultSeedData.loanGivenId,
    LoanLeg.recovered => DefaultSeedData.loanRecoveredId,
    LoanLeg.taken => DefaultSeedData.loanTakenId,
    LoanLeg.repaid => DefaultSeedData.loanRepaidId,
  };

  static LoanLeg? forCategory(String? categoryId) {
    if (categoryId == null) return null;
    for (final LoanLeg leg in LoanLeg.values) {
      if (leg.categoryId == categoryId) return leg;
    }
    return null;
  }
}

/// The whole lending position, split the two ways that matter: what is still
/// owed *to* you and what you still owe.
@immutable
class LoanLedger {
  const LoanLedger({
    required this.given,
    required this.recovered,
    required this.taken,
    required this.repaid,
    required this.transactions,
  });

  static const LoanLedger empty = LoanLedger(
    given: 0,
    recovered: 0,
    taken: 0,
    repaid: 0,
    transactions: <TransactionModel>[],
  );

  /// Total ever lent out.
  final double given;

  /// Of that, how much has come back.
  final double recovered;

  /// Total ever borrowed.
  final double taken;

  /// Of that, how much has been paid back.
  final double repaid;

  /// Every lending transaction, newest first.
  final List<TransactionModel> transactions;

  /// Still owed to you — "কত পাবো".
  double get receivable => Validators.roundMoney(given - recovered);

  /// Still owed by you — "কত দিবো".
  double get payable => Validators.roundMoney(taken - repaid);

  /// Positive when more is owed to you than by you.
  double get net => Validators.roundMoney(receivable - payable);

  bool get isEmpty => transactions.isEmpty;

  List<TransactionModel> forLeg(LoanLeg leg) => transactions
      .where((TransactionModel t) => t.categoryId == leg.categoryId)
      .toList(growable: false);
}

/// Derived from the one ledger listener, so it is exact, live and correct
/// offline like every other figure in the app.
final Provider<LoanLedger> loanLedgerProvider = Provider<LoanLedger>((Ref ref) {
  final List<TransactionModel> all =
      ref.watch(allTransactionsProvider).valueOrNull ??
      const <TransactionModel>[];

  double given = 0;
  double recovered = 0;
  double taken = 0;
  double repaid = 0;
  final List<TransactionModel> rows = <TransactionModel>[];

  for (final TransactionModel transaction in all) {
    final LoanLeg? leg = LoanLeg.forCategory(transaction.categoryId);
    if (leg == null) continue;
    rows.add(transaction);
    switch (leg) {
      case LoanLeg.given:
        given += transaction.amount;
      case LoanLeg.recovered:
        recovered += transaction.amount;
      case LoanLeg.taken:
        taken += transaction.amount;
      case LoanLeg.repaid:
        repaid += transaction.amount;
    }
  }

  return LoanLedger(
    given: Validators.roundMoney(given),
    recovered: Validators.roundMoney(recovered),
    taken: Validators.roundMoney(taken),
    repaid: Validators.roundMoney(repaid),
    transactions: List<TransactionModel>.unmodifiable(rows),
  );
});

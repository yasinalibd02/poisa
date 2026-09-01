import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/account_model.dart';
import '../../data/account_repository.dart';

final Provider<AccountRepository> accountRepositoryProvider =
    Provider<AccountRepository>(
      (Ref ref) => AccountRepository(ref.watch(firestoreRefsProvider)),
    );

final StreamProvider<List<AccountModel>> accountsStreamProvider =
    StreamProvider<List<AccountModel>>((Ref ref) {
      if (ref.watch(uidProvider) == null) {
        return Stream<List<AccountModel>>.value(const <AccountModel>[]);
      }
      return ref.watch(accountRepositoryProvider).watchAll();
    });

/// Non-archived accounts — what the pickers and dashboard show.
final Provider<List<AccountModel>> activeAccountsProvider =
    Provider<List<AccountModel>>((Ref ref) {
      final List<AccountModel> all =
          ref.watch(accountsStreamProvider).valueOrNull ??
          const <AccountModel>[];
      return all
          .where((AccountModel a) => !a.isArchived)
          .toList(growable: false);
    });

final Provider<Map<String, AccountModel>> accountMapProvider =
    Provider<Map<String, AccountModel>>((Ref ref) {
      final List<AccountModel> all =
          ref.watch(accountsStreamProvider).valueOrNull ??
          const <AccountModel>[];
      return <String, AccountModel>{
        for (final AccountModel account in all) account.id: account,
      };
    });

/// Live per-account balance: opening balance ± every transaction that touches
/// the account. Derived rather than stored, so edits and deletes can never
/// leave a balance out of step with the ledger.
final Provider<Map<String, double>> accountBalancesProvider =
    Provider<Map<String, double>>((Ref ref) {
      final List<AccountModel> accounts =
          ref.watch(accountsStreamProvider).valueOrNull ??
          const <AccountModel>[];
      final List<TransactionModel> transactions =
          ref.watch(allTransactionsProvider).valueOrNull ??
          const <TransactionModel>[];

      final Map<String, double> balances = <String, double>{
        for (final AccountModel account in accounts)
          account.id: account.openingBalance,
      };

      for (final TransactionModel transaction in transactions) {
        final String source = transaction.accountId;
        if (balances.containsKey(source)) {
          balances[source] = balances[source]! + transaction.effectOn(source);
        }
        final String? destination = transaction.toAccountId;
        if (destination != null && balances.containsKey(destination)) {
          balances[destination] =
              balances[destination]! + transaction.effectOn(destination);
        }
      }

      return balances.map(
        (String id, double value) =>
            MapEntry<String, double>(id, Validators.roundMoney(value)),
      );
    });

/// Sum of every non-archived account balance.
final Provider<double> netWorthProvider = Provider<double>((Ref ref) {
  final Map<String, double> balances = ref.watch(accountBalancesProvider);
  final List<AccountModel> active = ref.watch(activeAccountsProvider);
  double total = 0;
  for (final AccountModel account in active) {
    total += balances[account.id] ?? account.openingBalance;
  }
  return Validators.roundMoney(total);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/csv_export_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import 'settings_provider.dart';

final Provider<CsvExportService> csvExportServiceProvider =
    Provider<CsvExportService>((Ref ref) => const CsvExportService());

/// Long-running Settings operations that touch several repositories.
final Provider<SettingsActions> settingsActionsProvider =
    Provider<SettingsActions>(SettingsActions.new);

class SettingsActions {
  const SettingsActions(this._ref);

  final Ref _ref;

  /// Builds the CSV for every transaction. Returns `null` when there is
  /// nothing to export.
  Future<String?> buildExportCsv() async {
    final List<TransactionModel> transactions = await _ref
        .read(transactionRepositoryProvider)
        .fetchAll();
    if (transactions.isEmpty) return null;

    final Map<String, CategoryModel> categories = _ref.read(
      categoryMapProvider,
    );
    final Map<String, AccountModel> accounts = _ref.read(accountMapProvider);

    return _ref
        .read(csvExportServiceProvider)
        .buildCsv(
          transactions: transactions,
          categories: categories,
          accounts: accounts,
        );
  }

  /// Wipes the user's Firestore subtree, then deletes the auth account.
  ///
  /// Order matters: the security rules only allow the delete while a session
  /// still exists, so the data has to go first.
  Future<void> deleteAccountAndData() async {
    try {
      await _ref.read(userRepositoryProvider).deleteAllData();
      await _ref.read(authRepositoryProvider).deleteAuthAccount();
      await _ref.read(settingsProvider.notifier).resetAfterAccountDeletion();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }
}

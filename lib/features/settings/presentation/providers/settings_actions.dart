import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/csv_export_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_providers.dart';
import 'settings_provider.dart';

final Provider<CsvExportService> csvExportServiceProvider =
    Provider<CsvExportService>((Ref ref) => const CsvExportService());

/// Long-running Settings operations that touch several repositories. The
/// CSV/PDF export lives in `ExportActions` next door.
final Provider<SettingsActions> settingsActionsProvider =
    Provider<SettingsActions>(SettingsActions.new);

class SettingsActions {
  const SettingsActions(this._ref);

  final Ref _ref;

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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/home_widget_service.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// Keeps the home-screen widget in step with the ledger and the user's
/// formatting preferences. Watched once from the app root so it stays alive
/// for the whole session — including after sign-out, when the ledger empties
/// and the widget drops back to zero rather than showing the last user's
/// spending.
final Provider<void> homeWidgetSyncProvider = Provider<void>((Ref ref) {
  // Skip the empty first frame while Firestore is still loading, which would
  // otherwise flash zeros onto the widget on every launch.
  if (!ref.watch(allTransactionsProvider).hasValue) return;

  final AppSettings settings = ref.watch(settingsProvider);
  final MoneyFormatter money = ref.watch(moneyFormatterProvider);
  final AppL10n l10n = lookupAppL10n(Locale(settings.languageCode));

  final DateTime now = DateTime.now();
  final DateRange month = PeriodUtils.monthRange(
    now,
    firstDayOfMonth: settings.firstDayOfMonth,
  );
  final MoneySummary today = ref.watch(
    summaryForRangeProvider(PeriodUtils.dayRange(now)),
  );
  final MoneySummary thisMonth = ref.watch(summaryForRangeProvider(month));

  unawaited(
    HomeWidgetService.update(
      HomeWidgetSnapshot(
        todayLabel: l10n.widgetTodaySpent,
        todayAmount: money.format(today.expense),
        monthLabel: l10n.widgetThisMonth,
        monthAmount: money.format(thisMonth.expense),
        expenseLabel: l10n.expense,
        incomeLabel: l10n.income,
        zeroAmount: money.format(0),
        monthEnd: month.endExclusive,
      ),
    ),
  );
});

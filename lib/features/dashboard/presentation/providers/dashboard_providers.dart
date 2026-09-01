import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/period_utils.dart';
import '../../../settings/data/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// The month the dashboard, budget and month-scoped views are showing.
/// Shared across those screens so stepping a month in one place is remembered.
final NotifierProvider<SelectedMonthController, DateTime> selectedMonthProvider =
    NotifierProvider<SelectedMonthController, DateTime>(
      SelectedMonthController.new,
    );

class SelectedMonthController extends Notifier<DateTime> {
  @override
  DateTime build() => PeriodUtils.dayStart(DateTime.now());

  void next() => state = PeriodUtils.addMonths(state, 1);

  void previous() => state = PeriodUtils.addMonths(state, -1);

  void reset() => state = PeriodUtils.dayStart(DateTime.now());

  void set(DateTime anchor) => state = PeriodUtils.dayStart(anchor);

  /// True when the selected month contains today — used to disable "next".
  bool get isCurrentMonth {
    final DateTime now = DateTime.now();
    return state.year == now.year && state.month == now.month;
  }
}

/// The selected month expressed as a date range, honouring the user's
/// salary-cycle start day.
final Provider<DateRange> selectedMonthRangeProvider = Provider<DateRange>((
  Ref ref,
) {
  final DateTime anchor = ref.watch(selectedMonthProvider);
  final int firstDay = ref.watch(
    settingsProvider.select((AppSettings s) => s.firstDayOfMonth),
  );
  return PeriodUtils.monthRange(anchor, firstDayOfMonth: firstDay);
});

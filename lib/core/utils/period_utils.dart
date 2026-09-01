import 'package:intl/intl.dart';

/// A half-open date range: `start` inclusive, `endExclusive` exclusive.
/// Half-open ranges make Firestore `where` clauses and day bucketing exact.
class DateRange {
  const DateRange(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  /// Last instant that still belongs to the range — for display only.
  DateTime get endInclusive =>
      endExclusive.subtract(const Duration(milliseconds: 1));

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  int get dayCount => endExclusive.difference(start).inDays;

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      other.start == start &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(start, endExclusive);
}

/// The period selector used by Reports.
enum ReportPeriod { week, month, year, custom }

abstract final class PeriodUtils {
  /// Midnight at the start of [date].
  static DateTime dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateRange dayRange(DateTime date) {
    final DateTime start = dayStart(date);
    return DateRange(start, start.add(const Duration(days: 1)));
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Adds [months] to [anchor], clamping the day to the target month's length
  /// so 31 January + 1 month lands on 28/29 February rather than 3 March.
  static DateTime addMonths(DateTime anchor, int months) {
    final int totalMonths = anchor.month - 1 + months;
    final int year = anchor.year + (totalMonths ~/ 12);
    final int month = (totalMonths % 12) + 1;
    final int day = anchor.day.clamp(1, daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// The financial month containing [anchor].
  ///
  /// [firstDayOfMonth] supports salary cycles: with a value of 25, the "month"
  /// of 3 September runs 25 August → 25 September.
  static DateRange monthRange(DateTime anchor, {int firstDayOfMonth = 1}) {
    final int cycleDay = firstDayOfMonth.clamp(1, 28);
    if (cycleDay == 1) {
      final DateTime start = DateTime(anchor.year, anchor.month);
      return DateRange(start, DateTime(anchor.year, anchor.month + 1));
    }
    final DateTime start = anchor.day >= cycleDay
        ? DateTime(anchor.year, anchor.month, cycleDay)
        : DateTime(anchor.year, anchor.month - 1, cycleDay);
    return DateRange(start, addMonths(start, 1));
  }

  /// The week containing [anchor]. [firstDayOfWeek] uses `DateTime` weekday
  /// numbering (1 = Monday … 7 = Sunday).
  static DateRange weekRange(DateTime anchor, {int firstDayOfWeek = 1}) {
    final DateTime day = dayStart(anchor);
    final int diff = (day.weekday - firstDayOfWeek + 7) % 7;
    final DateTime start = day.subtract(Duration(days: diff));
    return DateRange(start, start.add(const Duration(days: 7)));
  }

  static DateRange yearRange(DateTime anchor) =>
      DateRange(DateTime(anchor.year), DateTime(anchor.year + 1));

  /// Builds the range for a report period selection.
  static DateRange rangeFor(
    ReportPeriod period,
    DateTime anchor, {
    int firstDayOfWeek = 1,
    int firstDayOfMonth = 1,
    DateRange? custom,
  }) {
    switch (period) {
      case ReportPeriod.week:
        return weekRange(anchor, firstDayOfWeek: firstDayOfWeek);
      case ReportPeriod.month:
        return monthRange(anchor, firstDayOfMonth: firstDayOfMonth);
      case ReportPeriod.year:
        return yearRange(anchor);
      case ReportPeriod.custom:
        return custom ?? monthRange(anchor, firstDayOfMonth: firstDayOfMonth);
    }
  }

  /// Whole months, oldest first, ending with the month containing [anchor].
  static List<DateRange> lastMonths(
    DateTime anchor,
    int count, {
    int firstDayOfMonth = 1,
  }) {
    return List<DateRange>.generate(count, (int i) {
      final DateTime month = addMonths(anchor, i - (count - 1));
      return monthRange(month, firstDayOfMonth: firstDayOfMonth);
    });
  }

  /// Days remaining in the range from today (never negative).
  static int daysRemaining(DateRange range, DateTime now) {
    final int days = range.endExclusive.difference(dayStart(now)).inDays;
    return days < 0 ? 0 : days;
  }
}

/// Locale-aware date labels. Digit localisation is applied by the caller
/// through `MoneyFormatter.localizeDigits`.
class DateLabels {
  DateLabels(this.localeName);

  final String localeName;

  String monthYear(DateTime date) =>
      DateFormat.yMMMM(localeName).format(date);

  String monthShort(DateTime date) => DateFormat.MMM(localeName).format(date);

  String dayMonth(DateTime date) => DateFormat.MMMd(localeName).format(date);

  String fullDate(DateTime date) => DateFormat.yMMMMd(localeName).format(date);

  String dayWithWeekday(DateTime date) =>
      DateFormat.MMMEd(localeName).format(date);

  String time(DateTime date) => DateFormat.jm(localeName).format(date);

  String dateTime(DateTime date) =>
      '${DateFormat.yMMMd(localeName).format(date)} · ${time(date)}';

  String rangeLabel(DateRange range) {
    final String start = DateFormat.yMMMd(localeName).format(range.start);
    final String end = DateFormat.yMMMd(localeName).format(range.endInclusive);
    return '$start – $end';
  }
}

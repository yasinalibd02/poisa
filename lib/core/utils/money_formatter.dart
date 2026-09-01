import 'package:intl/intl.dart';

import 'number_localizer.dart';

/// Formats money and plain numbers for the active locale, currency and
/// numeral preference. Built once per settings change and handed to widgets
/// through a provider, so no widget ever calls `NumberFormat` directly.
class MoneyFormatter {
  MoneyFormatter({
    required this.localeName,
    required this.currencySymbol,
    required this.useBanglaNumerals,
  }) : _decimal = NumberFormat.decimalPattern(localeName),
       _compact = NumberFormat.compactCurrency(
         locale: localeName,
         symbol: currencySymbol,
       );

  final String localeName;
  final String currencySymbol;
  final bool useBanglaNumerals;

  final NumberFormat _decimal;
  final NumberFormat _compact;

  String _digits(String value) =>
      NumberLocalizer.apply(value, bengali: useBanglaNumerals);

  /// `1234.5` → `৳1,234.50`; `1200` → `৳1,200`.
  /// Decimals are shown only when the amount actually has them, which keeps
  /// whole-taka amounts (the common case) uncluttered.
  String format(double amount, {bool forceDecimals = false}) {
    final double value = amount.abs();
    final bool hasFraction = (value * 100).round() % 100 != 0;
    _decimal
      ..minimumFractionDigits = (forceDecimals || hasFraction) ? 2 : 0
      ..maximumFractionDigits = 2;
    final String body = _digits(_decimal.format(value));
    final String sign = amount < 0 ? '−' : '';
    return '$sign$currencySymbol$body';
  }

  /// Always-signed form used in transaction rows: `+৳1,200` / `−৳350`.
  String formatSigned(double amount) {
    if (amount == 0) return format(0);
    final String sign = amount > 0 ? '+' : '−';
    return '$sign${format(amount.abs())}';
  }

  /// Short form for chart axes and dense cards: `৳12K`.
  String compact(double amount) => _digits(_compact.format(amount));

  /// A bare number with no currency symbol (percentages, counts, keypad).
  String number(num value, {int? decimals}) {
    _decimal
      ..minimumFractionDigits = decimals ?? 0
      ..maximumFractionDigits = decimals ?? 2;
    return _digits(_decimal.format(value));
  }

  /// `0.4213` → `42%`.
  String percent(double fraction) => '${number((fraction * 100).round())}%';

  /// Localises the digits of an already-formatted string (dates, day counts).
  String localizeDigits(String value) => _digits(value);
}

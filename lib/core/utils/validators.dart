import 'number_localizer.dart';

/// Shared parsing/validation helpers. Screens map the `null`/`false` results
/// onto localised messages from the ARB files.
abstract final class Validators {
  /// Parses an amount that may contain Bengali digits, grouping separators or
  /// stray whitespace. Returns `null` when the text is not a usable amount.
  static double? parseAmount(String? raw) {
    if (raw == null) return null;
    final String cleaned = NumberLocalizer.normalizeInput(raw)
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('−', '-')
        .trim();
    if (cleaned.isEmpty) return null;
    final double? value = double.tryParse(cleaned);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return value;
  }

  static bool isPositiveAmount(String? raw) {
    final double? value = parseAmount(raw);
    return value != null && value > 0;
  }

  static bool isNotBlank(String? raw) => raw?.trim().isNotEmpty ?? false;

  /// Money is stored to 2 decimal places; rounding here keeps arithmetic from
  /// accumulating binary floating-point drift across many transactions.
  static double roundMoney(double value) => (value * 100).roundToDouble() / 100;
}

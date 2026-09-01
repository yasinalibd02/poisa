/// Converts digits between Western (0-9) and Bengali (০-৯) numerals.
///
/// `intl` already emits Bengali digits for the `bn` locale, so the app formats
/// with the active locale first (which also gives the correct lakh/crore
/// grouping) and then forces the digit set the user asked for in Settings.
abstract final class NumberLocalizer {
  static const List<String> _bengali = <String>[
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯',
  ];

  static String toBengali(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(_bengali[rune - 0x30]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static String toWestern(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x09E6 && rune <= 0x09EF) {
        buffer.writeCharCode(0x30 + (rune - 0x09E6));
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Normalises user keyboard input (which may contain Bengali digits) so it
  /// can be parsed by [double.tryParse].
  static String normalizeInput(String input) => toWestern(input);

  static String apply(String input, {required bool bengali}) =>
      bengali ? toBengali(input) : toWestern(input);
}

import 'package:flutter/material.dart';

/// Brand palette for Kori. Every colour used by the app resolves from here or
/// from the [ColorScheme] built in `app/theme.dart` — never from literals in
/// widget code.
abstract final class AppColors {
  /// Deep teal — primary brand colour.
  static const Color primary = Color(0xFF1B7F6B);
  static const Color primaryDark = Color(0xFF14624F);
  static const Color primaryLight = Color(0xFF3FA98F);

  /// Amber — secondary / accent.
  static const Color accent = Color(0xFFF2A93B);
  static const Color accentDark = Color(0xFFC7841F);

  /// Semantic money colours.
  static const Color income = Color(0xFF2E9E5B);
  static const Color expense = Color(0xFFE0553C);
  static const Color transfer = Color(0xFF5B7DB1);

  /// Light surfaces.
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F7F6);
  static const Color outlineLight = Color(0xFFDDE3E1);
  static const Color textLight = Color(0xFF15201D);
  static const Color textMutedLight = Color(0xFF667772);

  /// Dark surfaces.
  static const Color surfaceDark = Color(0xFF1A1D1C);
  static const Color backgroundDark = Color(0xFF111413);
  static const Color outlineDark = Color(0xFF2E3634);
  static const Color textDark = Color(0xFFE8EDEB);
  static const Color textMutedDark = Color(0xFF95A5A1);

  /// Budget progress thresholds.
  static const Color budgetSafe = Color(0xFF2E9E5B);
  static const Color budgetWarning = Color(0xFFF2A93B);
  static const Color budgetDanger = Color(0xFFE0553C);

  /// The 16 swatches offered by the category / account colour picker.
  static const List<Color> swatches = <Color>[
    Color(0xFF1B7F6B),
    Color(0xFF2E9E5B),
    Color(0xFF6FBF4B),
    Color(0xFFF2A93B),
    Color(0xFFEF8B3C),
    Color(0xFFE0553C),
    Color(0xFFD94F6E),
    Color(0xFFB6478F),
    Color(0xFF8055C9),
    Color(0xFF5B6CD9),
    Color(0xFF3D8FD9),
    Color(0xFF29A9BF),
    Color(0xFF3FA98F),
    Color(0xFF8D6E4F),
    Color(0xFF6B7A87),
    Color(0xFF44514F),
  ];

  /// Parses a stored `#RRGGBB` / `RRGGBB` hex string, falling back to
  /// [AppColors.primary] when the value is missing or malformed.
  static Color fromHex(String? hex) {
    if (hex == null) return primary;
    final String cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6 && cleaned.length != 8) return primary;
    final int? value = int.tryParse(cleaned, radix: 16);
    if (value == null) return primary;
    return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
  }

  /// Serialises a colour back to the `#RRGGBB` form stored in Firestore.
  static String toHex(Color color) {
    final int argb =
        ((color.a * 255).round() << 24) |
        ((color.r * 255).round() << 16) |
        ((color.g * 255).round() << 8) |
        (color.b * 255).round();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

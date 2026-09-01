import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

/// Builds Kori's light and dark Material 3 themes.
///
/// The primary font follows the UI language (Inter for English, Hind Siliguri
/// for Bangla) but each always falls back to the other, so a Bangla note typed
/// while the UI is in English still renders with real glyphs instead of tofu.
abstract final class AppTheme {
  static const String _latinFont = 'Inter';
  static const String _bengaliFont = 'HindSiliguri';

  static String fontFor(String languageCode) =>
      languageCode == 'bn' ? _bengaliFont : _latinFont;

  static List<String> fallbackFor(String languageCode) =>
      languageCode == 'bn'
      ? const <String>[_latinFont]
      : const <String>[_bengaliFont];

  static ThemeData light(String languageCode) =>
      _build(Brightness.light, languageCode);

  static ThemeData dark(String languageCode) =>
      _build(Brightness.dark, languageCode);

  static ThemeData _build(Brightness brightness, String languageCode) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.primaryLight : AppColors.primary,
          onPrimary: isDark ? const Color(0xFF06231C) : Colors.white,
          secondary: AppColors.accent,
          onSecondary: const Color(0xFF3A2601),
          error: AppColors.expense,
          surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          onSurface: isDark ? AppColors.textDark : AppColors.textLight,
          onSurfaceVariant: isDark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
          outlineVariant: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        );

    final String family = fontFor(languageCode);
    final List<String> fallback = fallbackFor(languageCode);
    final TextTheme text = _textTheme(scheme, family, fallback);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      fontFamily: family,
      fontFamilyFallback: fallback,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.brLg,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppSizes.brMd),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: scheme.outlineVariant),
          shape: const RoundedRectangleBorder(borderRadius: AppSizes.brMd),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSizes.brMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSizes.brMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSizes.brMd,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSizes.brMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSizes.brMd,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppSizes.brLg),
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF2C3331)
            : const Color(0xFF20302C),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.accent,
        shape: const RoundedRectangleBorder(borderRadius: AppSizes.brSm),
        insetPadding: const EdgeInsets.all(AppSizes.lg),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          text.labelSmall ?? const TextStyle(fontSize: 11),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppSizes.brMd),
      ),

      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppSizes.brMd),
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: text.titleSmall,
      ),
    );
  }

  static TextTheme _textTheme(
    ColorScheme scheme,
    String family,
    List<String> fallback,
  ) {
    TextStyle style(double size, FontWeight weight, {double height = 1.35}) =>
        TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: scheme.onSurface,
        );

    return TextTheme(
      displaySmall: style(34, FontWeight.w700, height: 1.2),
      headlineLarge: style(30, FontWeight.w700, height: 1.25),
      headlineMedium: style(26, FontWeight.w700, height: 1.25),
      headlineSmall: style(22, FontWeight.w600, height: 1.3),
      titleLarge: style(20, FontWeight.w600),
      titleMedium: style(17, FontWeight.w600),
      titleSmall: style(15, FontWeight.w600),
      bodyLarge: style(16, FontWeight.w400, height: 1.45),
      bodyMedium: style(14, FontWeight.w400, height: 1.45),
      bodySmall: style(
        12.5,
        FontWeight.w400,
        height: 1.4,
      ).copyWith(color: scheme.onSurfaceVariant),
      labelLarge: style(14, FontWeight.w500),
      labelMedium: style(12.5, FontWeight.w500),
      labelSmall: style(11.5, FontWeight.w500),
    );
  }
}

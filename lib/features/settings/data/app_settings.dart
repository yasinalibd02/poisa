import 'package:flutter/material.dart';

import '../../../core/constants/currencies.dart';

/// User-facing preferences. Held locally in `SharedPreferences` (instant,
/// offline) and mirrored to `users/{uid}` so a new device picks them up.
@immutable
class AppSettings {
  const AppSettings({
    required this.languageCode,
    required this.themeMode,
    required this.currencyCode,
    required this.useBanglaNumerals,
    required this.firstDayOfWeek,
    required this.firstDayOfMonth,
    required this.onboardingDone,
  });

  /// `en` or `bn`.
  final String languageCode;
  final ThemeMode themeMode;
  final String currencyCode;
  final bool useBanglaNumerals;

  /// `DateTime` weekday numbering: 1 = Monday … 7 = Sunday.
  final int firstDayOfWeek;

  /// 1–28. Anything above 28 would skip months in February.
  final int firstDayOfMonth;

  final bool onboardingDone;

  static const List<String> supportedLanguages = <String>['en', 'bn'];

  factory AppSettings.defaults() => const AppSettings(
    languageCode: 'en',
    themeMode: ThemeMode.system,
    currencyCode: Currencies.defaultCode,
    useBanglaNumerals: false,
    firstDayOfWeek: DateTime.monday,
    firstDayOfMonth: 1,
    onboardingDone: false,
  );

  Locale get locale => Locale(languageCode);

  bool get isBangla => languageCode == 'bn';

  String get currencySymbol => Currencies.symbolFor(currencyCode);

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    String? currencyCode,
    bool? useBanglaNumerals,
    int? firstDayOfWeek,
    int? firstDayOfMonth,
    bool? onboardingDone,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      currencyCode: currencyCode ?? this.currencyCode,
      useBanglaNumerals: useBanglaNumerals ?? this.useBanglaNumerals,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      firstDayOfMonth: firstDayOfMonth ?? this.firstDayOfMonth,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  /// The subset mirrored into the Firestore user document.
  Map<String, Object?> toMap() => <String, Object?>{
    'languageCode': languageCode,
    'themeMode': themeModeToName(themeMode),
    'currencyCode': currencyCode,
    'useBanglaNumerals': useBanglaNumerals,
    'firstDayOfWeek': firstDayOfWeek,
    'firstDayOfMonth': firstDayOfMonth,
  };

  static String themeModeToName(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode themeModeFromName(String? name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.languageCode == languageCode &&
      other.themeMode == themeMode &&
      other.currencyCode == currencyCode &&
      other.useBanglaNumerals == useBanglaNumerals &&
      other.firstDayOfWeek == firstDayOfWeek &&
      other.firstDayOfMonth == firstDayOfMonth &&
      other.onboardingDone == onboardingDone;

  @override
  int get hashCode => Object.hash(
    languageCode,
    themeMode,
    currencyCode,
    useBanglaNumerals,
    firstDayOfWeek,
    firstDayOfMonth,
    onboardingDone,
  );
}

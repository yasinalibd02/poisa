import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper over [SharedPreferences]. Local preferences are the source of
/// truth for rendering (they are available synchronously and work offline);
/// they are mirrored into the user's Firestore document for cross-device sync.
class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kOnboardingDone = 'onboarding_done';
  static const String _kLanguage = 'language_code';
  static const String _kThemeMode = 'theme_mode';
  static const String _kCurrency = 'currency_code';
  static const String _kBanglaNumerals = 'use_bangla_numerals';
  static const String _kFirstDayOfWeek = 'first_day_of_week';
  static const String _kFirstDayOfMonth = 'first_day_of_month';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_kOnboardingDone, value);

  String? get languageCode => _prefs.getString(_kLanguage);
  Future<void> setLanguageCode(String value) =>
      _prefs.setString(_kLanguage, value);

  String? get themeMode => _prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String value) => _prefs.setString(_kThemeMode, value);

  String? get currencyCode => _prefs.getString(_kCurrency);
  Future<void> setCurrencyCode(String value) =>
      _prefs.setString(_kCurrency, value);

  bool? get useBanglaNumerals => _prefs.getBool(_kBanglaNumerals);
  Future<void> setUseBanglaNumerals(bool value) =>
      _prefs.setBool(_kBanglaNumerals, value);

  int? get firstDayOfWeek => _prefs.getInt(_kFirstDayOfWeek);
  Future<void> setFirstDayOfWeek(int value) =>
      _prefs.setInt(_kFirstDayOfWeek, value);

  int? get firstDayOfMonth => _prefs.getInt(_kFirstDayOfMonth);
  Future<void> setFirstDayOfMonth(int value) =>
      _prefs.setInt(_kFirstDayOfMonth, value);

  /// Clears everything except the onboarding flag — used when the user deletes
  /// their account but stays on the device.
  Future<void> clearUserPreferences() async {
    await Future.wait<void>(<Future<void>>[
      _prefs.remove(_kCurrency),
      _prefs.remove(_kBanglaNumerals),
      _prefs.remove(_kFirstDayOfWeek),
      _prefs.remove(_kFirstDayOfMonth),
    ]);
  }
}

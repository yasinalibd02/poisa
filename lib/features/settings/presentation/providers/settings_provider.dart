import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/overlay_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/app_settings.dart';

/// Overridden in `main()` once [SharedPreferences] has loaded, so the whole
/// tree can read preferences synchronously and the first frame is already
/// themed and localised correctly.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError(
        'sharedPreferencesProvider must be overridden in main()',
      ),
    );

final Provider<PreferencesService> preferencesServiceProvider =
    Provider<PreferencesService>(
      (Ref ref) => PreferencesService(ref.watch(sharedPreferencesProvider)),
    );

final NotifierProvider<SettingsController, AppSettings> settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Formats every amount in the app for the current locale, currency and
/// numeral preference.
final Provider<MoneyFormatter> moneyFormatterProvider = Provider<MoneyFormatter>(
  (Ref ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    return MoneyFormatter(
      localeName: settings.languageCode,
      currencySymbol: settings.currencySymbol,
      useBanglaNumerals: settings.useBanglaNumerals,
    );
  },
);

final Provider<DateLabels> dateLabelsProvider = Provider<DateLabels>((Ref ref) {
  return DateLabels(ref.watch(settingsProvider).languageCode);
});

class SettingsController extends Notifier<AppSettings> {
  late final PreferencesService _prefs = ref.read(preferencesServiceProvider);

  @override
  AppSettings build() {
    final AppSettings settings = _load();
    // Re-arms the OS schedule on every launch: cheap, idempotent, and picks
    // up a timezone change or a reinstall that wiped pending notifications.
    Future<void>.microtask(() => _syncReminder(settings));
    return settings;
  }

  AppSettings _load() {
    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    final AppSettings defaults = AppSettings.defaults();
    final String language = prefs.languageCode ?? _systemLanguage();
    return defaults.copyWith(
      languageCode: language,
      themeMode: AppSettings.themeModeFromName(prefs.themeMode),
      currencyCode: prefs.currencyCode ?? Currencies.defaultCode,
      // Bangla speakers get Bangla numerals by default, but the explicit
      // toggle always wins once it has been touched.
      useBanglaNumerals: prefs.useBanglaNumerals ?? (language == 'bn'),
      firstDayOfWeek: prefs.firstDayOfWeek ?? DateTime.monday,
      firstDayOfMonth: prefs.firstDayOfMonth ?? 1,
      onboardingDone: prefs.onboardingDone,
      reminderEnabled: prefs.reminderEnabled ?? false,
      overlayEnabled: prefs.overlayEnabled,
      reminderTime: prefs.reminderMinutes == null
          ? AppSettings.defaultReminderTime
          : TimeOfDay(
              hour: prefs.reminderMinutes! ~/ 60,
              minute: prefs.reminderMinutes! % 60,
            ),
    );
  }

  static String _systemLanguage() {
    final String code = PlatformDispatcher.instance.locale.languageCode;
    return AppSettings.supportedLanguages.contains(code) ? code : 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    if (!AppSettings.supportedLanguages.contains(languageCode)) return;
    final bool numeralsUntouched = _prefs.useBanglaNumerals == null;
    await _prefs.setLanguageCode(languageCode);
    state = state.copyWith(
      languageCode: languageCode,
      useBanglaNumerals: numeralsUntouched
          ? languageCode == 'bn'
          : state.useBanglaNumerals,
    );
    // The scheduled notification carries its text, so it must be rebuilt in
    // the new language.
    unawaited(_syncReminder(state));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(AppSettings.themeModeToName(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setCurrency(String code) async {
    await _prefs.setCurrencyCode(code);
    state = state.copyWith(currencyCode: code);
  }

  Future<void> setBanglaNumerals(bool value) async {
    await _prefs.setUseBanglaNumerals(value);
    state = state.copyWith(useBanglaNumerals: value);
  }

  Future<void> setFirstDayOfWeek(int weekday) async {
    await _prefs.setFirstDayOfWeek(weekday);
    state = state.copyWith(firstDayOfWeek: weekday);
  }

  Future<void> setFirstDayOfMonth(int day) async {
    final int clamped = day.clamp(1, 28);
    await _prefs.setFirstDayOfMonth(clamped);
    state = state.copyWith(firstDayOfMonth: clamped);
  }

  /// Turns the daily reminder on or off. Returns false when the OS refused
  /// notification permission, in which case the switch stays off.
  Future<bool> setReminderEnabled(bool value) async {
    if (value && !await NotificationService.requestPermission()) return false;
    await _prefs.setReminderEnabled(value);
    state = state.copyWith(reminderEnabled: value);
    await _syncReminder(state);
    return true;
  }

  /// Turns the floating overlay bubble on or off (Android only).
  /// Returns false when the OS refused overlay permission.
  Future<bool> setOverlayEnabled(bool value) async {
    if (value) {
      final bool granted = await OverlayService.isPermissionGranted();
      if (!granted) {
        final bool requested = await OverlayService.requestPermission();
        if (!requested) return false;
      }
      final bool shown = await OverlayService.showFloatingBubble();
      if (!shown) return false;
    } else {
      await OverlayService.closeBubble();
    }
    await _prefs.setOverlayEnabled(value);
    state = state.copyWith(overlayEnabled: value);
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await _prefs.setReminderMinutes(time.hour * 60 + time.minute);
    state = state.copyWith(reminderTime: time);
    await _syncReminder(state);
  }

  /// Mirrors [settings] into the OS notification schedule. Until the user
  /// first touches the switch they stay on the server-sent FCM reminder;
  /// after that the local one is the only reminder, on or off.
  Future<void> _syncReminder(AppSettings settings) async {
    try {
      await NotificationService.syncTopic(
        subscribed: _prefs.reminderEnabled == null,
      );
      if (!settings.reminderEnabled) {
        await NotificationService.cancelDailyReminder();
        return;
      }
      final AppL10n l10n = lookupAppL10n(settings.locale);
      await NotificationService.scheduleDailyReminder(
        time: settings.reminderTime,
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBody,
      );
    } catch (error) {
      debugPrint('SettingsController: reminder sync failed: $error');
    }
  }

  Future<void> completeOnboarding() async {
    await _prefs.setOnboardingDone(true);
    state = state.copyWith(onboardingDone: true);
  }

  /// Applies preferences pulled from the user's Firestore document on a fresh
  /// device. Local values that the user has already set are left alone.
  Future<void> hydrateFromRemote(Map<String, Object?> data) async {
    final PreferencesService prefs = _prefs;
    AppSettings next = state;

    if (prefs.languageCode == null && data['languageCode'] is String) {
      final String code = data['languageCode']! as String;
      if (AppSettings.supportedLanguages.contains(code)) {
        await prefs.setLanguageCode(code);
        next = next.copyWith(languageCode: code);
      }
    }
    if (prefs.themeMode == null && data['themeMode'] is String) {
      final ThemeMode mode = AppSettings.themeModeFromName(
        data['themeMode'] as String?,
      );
      await prefs.setThemeMode(AppSettings.themeModeToName(mode));
      next = next.copyWith(themeMode: mode);
    }
    if (prefs.currencyCode == null && data['currencyCode'] is String) {
      final String code = data['currencyCode']! as String;
      await prefs.setCurrencyCode(code);
      next = next.copyWith(currencyCode: code);
    }
    if (prefs.useBanglaNumerals == null && data['useBanglaNumerals'] is bool) {
      final bool value = data['useBanglaNumerals']! as bool;
      await prefs.setUseBanglaNumerals(value);
      next = next.copyWith(useBanglaNumerals: value);
    }
    if (prefs.firstDayOfWeek == null && data['firstDayOfWeek'] is int) {
      final int value = (data['firstDayOfWeek']! as int).clamp(1, 7);
      await prefs.setFirstDayOfWeek(value);
      next = next.copyWith(firstDayOfWeek: value);
    }
    if (prefs.firstDayOfMonth == null && data['firstDayOfMonth'] is int) {
      final int value = (data['firstDayOfMonth']! as int).clamp(1, 28);
      await prefs.setFirstDayOfMonth(value);
      next = next.copyWith(firstDayOfMonth: value);
    }

    if (next != state) state = next;
  }

  /// Called after account deletion so the next sign-in starts clean.
  Future<void> resetAfterAccountDeletion() async {
    await _prefs.clearUserPreferences();
    state = _load();
  }
}

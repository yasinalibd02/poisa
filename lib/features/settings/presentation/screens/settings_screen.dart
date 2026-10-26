import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/services/link_service.dart';
import '../../../../core/services/overlay_service.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_providers.dart';
import '../../data/app_settings.dart';
import '../providers/export_actions.dart';
import '../providers/settings_actions.dart';
import '../providers/settings_provider.dart';
import '../widgets/export_sheet.dart';
import '../widgets/settings_tiles.dart';

/// Profile, preferences, data export and the two account-level destructive
/// actions.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    final UserModel? user = ref.watch(userDocProvider).valueOrNull;
    final bool isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          0,
          AppSizes.screenPadding,
          96,
        ),
        children: <Widget>[
          _ProfileHeader(user: user, isGuest: isGuest),

          SettingsSection(
            title: context.l10n.preferences,
            children: <Widget>[
              SettingsTile(
                icon: CupertinoIcons.globe,
                label: context.l10n.language,
                value: settings.isBangla ? 'বাংলা' : 'English',
                onTap: _pickLanguage,
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.textformat_123,
                label: context.l10n.banglaNumerals,
                description: context.l10n.banglaNumeralsBody,
                trailing: Switch.adaptive(
                  value: settings.useBanglaNumerals,
                  onChanged: ref
                      .read(settingsProvider.notifier)
                      .setBanglaNumerals,
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.circle_lefthalf_fill,
                label: context.l10n.theme,
                value: _themeLabel(settings.themeMode),
                onTap: _pickTheme,
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.money_dollar_circle,
                label: context.l10n.currency,
                value:
                    '${settings.currencySymbol}  ${settings.currencyCode}',
                onTap: _pickCurrency,
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.calendar,
                label: context.l10n.firstDayOfWeek,
                value: _weekdayLabel(settings.firstDayOfWeek),
                onTap: _pickFirstDayOfWeek,
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.calendar_today,
                label: context.l10n.firstDayOfMonth,
                description: context.l10n.firstDayOfMonthBody,
                value: context.l10n.dayOfMonth(settings.firstDayOfMonth),
                onTap: _pickFirstDayOfMonth,
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.dailyReminder,
            children: <Widget>[
              SettingsTile(
                icon: CupertinoIcons.bell,
                label: context.l10n.dailyReminder,
                description: context.l10n.dailyReminderBody,
                trailing: Switch.adaptive(
                  value: settings.reminderEnabled,
                  onChanged: _toggleReminder,
                ),
              ),
              if (settings.reminderEnabled) ...<Widget>[
                const SettingsDivider(),
                SettingsTile(
                  icon: CupertinoIcons.clock,
                  label: context.l10n.reminderTime,
                  value: _timeLabel(settings.reminderTime),
                  onTap: _pickReminderTime,
                ),
              ],
            ],
          ),

          if (OverlayService.isSupported)
            SettingsSection(
              title: context.l10n.displayOverlay,
              children: <Widget>[
                SettingsTile(
                  icon: CupertinoIcons.app_badge,
                  label: context.l10n.displayOverlay,
                  description: context.l10n.displayOverlayBody,
                  trailing: Switch.adaptive(
                    value: settings.overlayEnabled,
                    onChanged: _toggleOverlay,
                  ),
                ),
              ],
            ),

          SettingsSection(
            title: context.l10n.dataAndPrivacy,
            children: <Widget>[
              SettingsTile(
                icon: CupertinoIcons.square_grid_2x2_fill,
                label: context.l10n.manageCategories,
                onTap: () => context.push(AppRoutes.categories),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.creditcard_fill,
                label: context.l10n.manageAccounts,
                onTap: () => context.push(AppRoutes.accounts),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.flag_fill,
                label: context.l10n.budgets,
                onTap: () => context.push(AppRoutes.budget),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.arrow_right_arrow_left_circle,
                label: context.l10n.loans,
                description: context.l10n.loansSubtitle,
                onTap: () => context.push(AppRoutes.loans),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.tray_arrow_down,
                label: context.l10n.exportData,
                description: context.l10n.exportDataBody,
                onTap: _busy ? null : _export,
                trailing: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),

          SettingsSection(
            title: context.l10n.about,
            children: <Widget>[
              SettingsTile(
                icon: CupertinoIcons.info_circle,
                label: context.l10n.about,
                description: context.l10n.aboutBody,
                value: context.l10n.version(AppConfig.appVersion),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.lock_shield,
                label: context.l10n.privacyPolicy,
                onTap: () => LinkService.open(AppConfig.privacyPolicyUrl),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.star,
                label: context.l10n.rateApp,
                onTap: () => LinkService.open(
                  LinkService.storeUrl(
                    androidUrl: AppConfig.androidStoreUrl,
                    iosUrl: AppConfig.iosStoreUrl,
                  ),
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: CupertinoIcons.share,
                label: context.l10n.shareApp,
                onTap: _shareApp,
              ),
            ],
          ),

          AppSizes.gapXl,
          SettingsSection(
            title: context.l10n.profile,
            children: isGuest
                ? <Widget>[
                    SettingsTile(
                      icon: CupertinoIcons.square_arrow_right,
                      label: context.l10n.guestExit,
                      description: context.l10n.guestModeCaption,
                      destructive: true,
                      onTap: _busy ? null : _exitGuest,
                    ),
                  ]
                : <Widget>[
                    SettingsTile(
                      icon: CupertinoIcons.square_arrow_right,
                      label: context.l10n.signOut,
                      onTap: _signOut,
                    ),
                    const SettingsDivider(),
                    SettingsTile(
                      icon: CupertinoIcons.trash_fill,
                      label: context.l10n.deleteAccountAndData,
                      destructive: true,
                      onTap: _busy ? null : _deleteAccount,
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => context.l10n.themeLight,
    ThemeMode.dark => context.l10n.themeDark,
    ThemeMode.system => context.l10n.themeSystem,
  };

  String _weekdayLabel(int weekday) => switch (weekday) {
    DateTime.saturday => context.l10n.saturday,
    DateTime.sunday => context.l10n.sunday,
    _ => context.l10n.monday,
  };

  String _timeLabel(TimeOfDay time) {
    final DateTime asDate = DateTime(2000, 1, 1, time.hour, time.minute);
    return ref
        .read(moneyFormatterProvider)
        .localizeDigits(ref.read(dateLabelsProvider).time(asDate));
  }

  Future<void> _toggleReminder(bool value) async {
    final bool applied = await ref
        .read(settingsProvider.notifier)
        .setReminderEnabled(value);
    if (!applied && mounted) {
      AppSnack.error(context, context.l10n.reminderPermissionDenied);
    }
  }

  Future<void> _toggleOverlay(bool value) async {
    final bool applied = await ref
        .read(settingsProvider.notifier)
        .setOverlayEnabled(value);
    if (!applied && mounted) {
      AppSnack.error(context, context.l10n.displayOverlayPermissionDenied);
    }
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? time = await showTimeWheelSheet(
      context,
      title: context.l10n.reminderTime,
      initial: ref.read(settingsProvider).reminderTime,
    );
    if (time != null) {
      await ref.read(settingsProvider.notifier).setReminderTime(time);
    }
  }

  Future<void> _pickLanguage() async {
    final String? code = await showChoiceSheet<String>(
      context,
      title: context.l10n.language,
      selected: ref.read(settingsProvider).languageCode,
      options: const <({String value, String label, String? subtitle})>[
        (value: 'en', label: 'English', subtitle: 'English'),
        (value: 'bn', label: 'বাংলা', subtitle: 'Bangla'),
      ],
    );
    if (code != null) {
      await ref.read(settingsProvider.notifier).setLanguage(code);
    }
  }

  Future<void> _pickTheme() async {
    final ThemeMode? mode = await showChoiceSheet<ThemeMode>(
      context,
      title: context.l10n.theme,
      selected: ref.read(settingsProvider).themeMode,
      options: <({ThemeMode value, String label, String? subtitle})>[
        (
          value: ThemeMode.system,
          label: context.l10n.themeSystem,
          subtitle: null,
        ),
        (
          value: ThemeMode.light,
          label: context.l10n.themeLight,
          subtitle: null,
        ),
        (value: ThemeMode.dark, label: context.l10n.themeDark, subtitle: null),
      ],
    );
    if (mode != null) {
      await ref.read(settingsProvider.notifier).setThemeMode(mode);
    }
  }

  Future<void> _pickCurrency() async {
    final String? code = await showChoiceSheet<String>(
      context,
      title: context.l10n.selectCurrency,
      searchable: true,
      searchHint: context.l10n.actionSearch,
      selected: ref.read(settingsProvider).currencyCode,
      options: Currencies.all
          .map(
            (CurrencyOption c) => (
              value: c.code,
              label: '${c.symbol}  ${c.code}',
              subtitle: c.name,
            ),
          )
          .toList(growable: false),
    );
    if (code != null) {
      await ref.read(settingsProvider.notifier).setCurrency(code);
    }
  }

  Future<void> _pickFirstDayOfWeek() async {
    final int? weekday = await showChoiceSheet<int>(
      context,
      title: context.l10n.firstDayOfWeek,
      selected: ref.read(settingsProvider).firstDayOfWeek,
      options: <({int value, String label, String? subtitle})>[
        (value: DateTime.monday, label: context.l10n.monday, subtitle: null),
        (
          value: DateTime.saturday,
          label: context.l10n.saturday,
          subtitle: null,
        ),
        (value: DateTime.sunday, label: context.l10n.sunday, subtitle: null),
      ],
    );
    if (weekday != null) {
      await ref.read(settingsProvider.notifier).setFirstDayOfWeek(weekday);
    }
  }

  Future<void> _pickFirstDayOfMonth() async {
    final int? day = await showChoiceSheet<int>(
      context,
      title: context.l10n.firstDayOfMonth,
      selected: ref.read(settingsProvider).firstDayOfMonth,
      options: <({int value, String label, String? subtitle})>[
        // Capped at 28 so no month is ever skipped in February.
        for (int day = 1; day <= 28; day++)
          (
            value: day,
            label: context.l10n.dayOfMonth(day),
            subtitle: null,
          ),
      ],
    );
    if (day != null) {
      await ref.read(settingsProvider.notifier).setFirstDayOfMonth(day);
    }
  }

  /// Format, then destination, then one build. The export is rendered once
  /// and either shared or written to the device, so choosing "save" never
  /// costs a second pass over the ledger.
  Future<void> _export() async {
    final ExportFormat? format = await showExportFormatSheet(context);
    if (format == null || !mounted) return;

    final ExportDestination? destination = await showExportDestinationSheet(
      context,
    );
    if (destination == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final ExportActions actions = ref.read(exportActionsProvider);
      final ExportFile? file = await actions.build(
        format: format,
        pdfLabels: _pdfLabels(),
      );
      if (!mounted) return;

      if (file == null) {
        AppSnack.show(context, context.l10n.nothingToExport);
        return;
      }

      switch (destination) {
        case ExportDestination.share:
          await actions.share(file, subject: context.l10n.exportData);
          if (!mounted) return;
          AppSnack.success(context, context.l10n.exportSuccess);
        case ExportDestination.save:
          final String location = await actions.saveToDevice(file);
          if (!mounted) return;
          AppSnack.success(context, context.l10n.exportSaved(location));
      }
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The PDF is built off the widget tree, so every string it prints is
  /// resolved here while a [BuildContext] is still in hand.
  PdfReportLabels _pdfLabels() {
    final AppL10n l10n = context.l10n;
    final MoneyFormatter money = ref.read(moneyFormatterProvider);
    final DateLabels dates = ref.read(dateLabelsProvider);

    return PdfReportLabels(
      title: l10n.exportPdfTitle,
      generated: l10n.exportPdfGenerated(dates.dateTime(DateTime.now())),
      totalIncome: l10n.exportPdfTotalIncome,
      totalExpense: l10n.exportPdfTotalExpense,
      net: l10n.exportPdfNet,
      countOf: (int count) => l10n.exportPdfCount(money.number(count)),
      pageOf: (int current, int total) =>
          l10n.exportPdfPage(money.number(current), money.number(total)),
      date: l10n.date,
      type: l10n.type,
      category: l10n.category,
      account: l10n.account,
      note: l10n.note,
      amount: l10n.amount,
    );
  }

  Future<void> _shareApp() async {
    try {
      await ref
          .read(csvExportServiceProvider)
          .shareText(
            '${context.l10n.shareAppMessage}\n${AppConfig.androidStoreUrl}',
          );
    } catch (_) {
      // Share sheet failures are not worth interrupting the user for.
    }
  }

  Future<void> _signOut() async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: context.l10n.signOutTitle,
      message: context.l10n.signOutBody,
      confirmLabel: context.l10n.signOut,
      destructive: false,
    );
    if (!confirmed) return;
    await ref.read(signInControllerProvider.notifier).signOut();
  }

  /// Guest sessions own no recoverable data, so leaving one wipes the whole
  /// subtree and deletes the anonymous user — the same path as a full account
  /// deletion, minus the typed confirmation.
  Future<void> _exitGuest() async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: context.l10n.guestExitTitle,
      message: context.l10n.guestExitBody,
      confirmLabel: context.l10n.guestExit,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(settingsActionsProvider).deleteAccountAndData();
      if (!mounted) return;
      AppSnack.success(context, context.l10n.guestExitDone);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        AppFailure.from(error).localizedMessage(context.l10n),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Two confirmations: a plain dialog, then a typed "DELETE".
  Future<void> _deleteAccount() async {
    final bool first = await showConfirmDialog(
      context,
      title: context.l10n.deleteAccountStep1Title,
      message: context.l10n.deleteAccountStep1Body,
      confirmLabel: context.l10n.actionDelete,
    );
    if (!first || !mounted) return;

    final bool second = await showTypedConfirmDialog(
      context,
      title: context.l10n.deleteAccountStep2Title,
      message: context.l10n.deleteAccountStep2Body,
      requiredWord: context.l10n.deleteConfirmationWord,
      confirmLabel: context.l10n.deleteAccountAndData,
    );
    if (!second || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(settingsActionsProvider).deleteAccountAndData();
      if (!mounted) return;
      AppSnack.success(context, context.l10n.deleteAccountDone);
    } catch (error) {
      if (!mounted) return;
      final AppFailure failure = AppFailure.from(error);
      AppSnack.error(context, failure.localizedMessage(context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, this.isGuest = false});

  final UserModel? user;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final String? photo = user?.photoUrl;
    final bool hasName = user?.displayName.trim().isNotEmpty ?? false;
    final String name = isGuest
        ? context.l10n.guestBadge
        : (hasName ? user!.displayName : context.l10n.profile);
    final String secondary = isGuest
        ? context.l10n.guestModeCaption
        : (user?.email ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 30,
            backgroundColor: context.colors.primary.withValues(alpha: 0.14),
            foregroundImage: (!isGuest && photo != null && photo.isNotEmpty)
                ? NetworkImage(photo)
                : null,
            child: isGuest
                ? Icon(CupertinoIcons.person, color: context.colors.primary)
                : Text(
                    user?.initials ?? '',
                    style: context.texts.titleMedium?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
          ),
          AppSizes.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

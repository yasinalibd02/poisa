import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/providers/home_widget_sync.dart';
import '../features/settings/data/app_settings.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget. Rebuilds on any settings change, which is what makes a
/// language or theme switch take effect instantly without a restart.
class KoriApp extends ConsumerWidget {
  const KoriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final GoRouter router = ref.watch(routerProvider);
    ref.watch(homeWidgetSyncProvider);

    return MaterialApp.router(
      title: 'Kori',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      locale: settings.locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: settings.themeMode,
      theme: AppTheme.light(settings.languageCode),
      darkTheme: AppTheme.dark(settings.languageCode),

      builder: (BuildContext context, Widget? child) {
        // Clamp text scaling: Bangla is a tall script and the app's dense
        // money rows start clipping past ~1.3x.
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Small readability helpers so widgets say `context.l10n.income` instead of
/// `AppL10n.of(context).income`.
extension ContextX on BuildContext {
  AppL10n get l10n => AppL10n.of(this);

  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  MediaQueryData get media => MediaQuery.of(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// True on narrow handsets (360dp class), where dense layouts need to relax.
  bool get isCompact => MediaQuery.sizeOf(this).width < 380;
}

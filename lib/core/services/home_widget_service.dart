import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'launch_actions.dart';

/// What the home-screen widget shows. Every string arrives pre-formatted in
/// the user's language, currency and numerals — the native side only lays it
/// out.
@immutable
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.todayLabel,
    required this.todayAmount,
    required this.monthLabel,
    required this.monthAmount,
    required this.expenseLabel,
    required this.incomeLabel,
    required this.zeroAmount,
    required this.monthEnd,
  });

  final String todayLabel;
  final String todayAmount;
  final String monthLabel;
  final String monthAmount;
  final String expenseLabel;
  final String incomeLabel;

  /// Shown instead of a stale figure once the day (or month) has rolled over
  /// without the app being opened.
  final String zeroAmount;
  final DateTime monthEnd;

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetSnapshot &&
      other.todayLabel == todayLabel &&
      other.todayAmount == todayAmount &&
      other.monthLabel == monthLabel &&
      other.monthAmount == monthAmount &&
      other.expenseLabel == expenseLabel &&
      other.incomeLabel == incomeLabel &&
      other.zeroAmount == zeroAmount &&
      other.monthEnd == monthEnd;

  @override
  int get hashCode => Object.hash(
        todayLabel,
        todayAmount,
        monthLabel,
        monthAmount,
        expenseLabel,
        incomeLabel,
        zeroAmount,
        monthEnd,
      );
}

/// Bridges the app and the native home-screen widget (Android
/// `PoisaWidgetProvider`, iOS `PoisaWidget`). Widget buttons open the app with
/// a `poisa://add/<type>` link, which is turned into a [LaunchActions] request.
abstract final class HomeWidgetService {
  static const String _androidProvider = 'PoisaWidgetProvider';
  static const String _iosKind = 'PoisaWidget';

  /// Must match the App Group shared by the Runner and the widget extension.
  static const String iosAppGroupId = 'group.com.kori.moneytracker';

  static HomeWidgetSnapshot? _last;
  static String? _lastDay;

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(iosAppGroupId);
      _handleLaunch(await HomeWidget.initiallyLaunchedFromHomeWidget());
      HomeWidget.widgetClicked.listen(_handleLaunch);
    } catch (error) {
      // No widget extension configured (e.g. iOS before the Xcode target is
      // added): the app simply runs without a widget.
      debugPrint('HomeWidgetService: init failed: $error');
    }
  }

  static void _handleLaunch(Uri? uri) {
    if (uri == null || uri.host != 'add' || uri.pathSegments.isEmpty) return;
    LaunchActions.requestNewTransaction(uri.pathSegments.first);
  }

  /// Pushes [snapshot] to the widget. Identical consecutive snapshots on the
  /// same day are skipped, so this is cheap to call on every ledger change.
  static Future<void> update(HomeWidgetSnapshot snapshot) async {
    final String day = DateFormat('yyyy-MM-dd', 'en').format(DateTime.now());
    if (snapshot == _last && day == _lastDay) return;
    _last = snapshot;
    _lastDay = day;
    try {
      await Future.wait<Object?>(<Future<Object?>>[
        HomeWidget.saveWidgetData<String>('today_label', snapshot.todayLabel),
        HomeWidget.saveWidgetData<String>('today_amount', snapshot.todayAmount),
        HomeWidget.saveWidgetData<String>('month_label', snapshot.monthLabel),
        HomeWidget.saveWidgetData<String>('month_amount', snapshot.monthAmount),
        HomeWidget.saveWidgetData<String>(
          'expense_label',
          snapshot.expenseLabel,
        ),
        HomeWidget.saveWidgetData<String>('income_label', snapshot.incomeLabel),
        HomeWidget.saveWidgetData<String>('zero_amount', snapshot.zeroAmount),
        HomeWidget.saveWidgetData<String>('snapshot_day', day),
        HomeWidget.saveWidgetData<String>(
          'month_end_ms',
          snapshot.monthEnd.millisecondsSinceEpoch.toString(),
        ),
      ]);
      await HomeWidget.updateWidget(
        androidName: _androidProvider,
        iOSName: _iosKind,
      );
    } catch (error) {
      _last = null;
      debugPrint('HomeWidgetService: update failed: $error');
    }
  }
}

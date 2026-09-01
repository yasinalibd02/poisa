import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kori/app/theme.dart';
import 'package:kori/core/extensions/context_x.dart';
import 'package:kori/l10n/app_localizations.dart';

/// Pumps a tiny widget under the app's real delegates and theme, so a missing
/// translation or a broken plural shows up as a test failure.
Future<void> _pump(
  WidgetTester tester,
  Locale locale,
  Widget Function(BuildContext) builder,
) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(locale.languageCode),
      home: Scaffold(body: Builder(builder: builder)),
    ),
  );
}

void main() {
  testWidgets('supports English and Bangla', (WidgetTester tester) async {
    expect(
      AppL10n.supportedLocales.map((Locale l) => l.languageCode),
      containsAll(<String>['en', 'bn']),
    );
  });

  testWidgets('resolves core labels in English', (WidgetTester tester) async {
    await _pump(
      tester,
      const Locale('en'),
      (BuildContext context) => Column(
        children: <Widget>[
          Text(context.l10n.income),
          Text(context.l10n.expense),
          Text(context.l10n.settings),
        ],
      ),
    );

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('resolves core labels in Bangla', (WidgetTester tester) async {
    await _pump(
      tester,
      const Locale('bn'),
      (BuildContext context) => Column(
        children: <Widget>[
          Text(context.l10n.income),
          Text(context.l10n.expense),
          Text(context.l10n.settings),
          Text(context.l10n.dashboard),
          Text(context.l10n.budget),
        ],
      ),
    );

    expect(find.text('আয়'), findsOneWidget);
    expect(find.text('খরচ'), findsOneWidget);
    expect(find.text('সেটিংস'), findsOneWidget);
    expect(find.text('ড্যাশবোর্ড'), findsOneWidget);
    expect(find.text('বাজেট'), findsOneWidget);
  });

  testWidgets('formats plurals and placeholders in both languages', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const Locale('en'),
      (BuildContext context) => Column(
        children: <Widget>[
          Text(context.l10n.daysLeft(1)),
          Text(context.l10n.daysLeft(12)),
          Text(context.l10n.greetingMorning('Rafi')),
          Text(context.l10n.spentOfLimit('100', '500')),
        ],
      ),
    );
    expect(find.text('1 day left'), findsOneWidget);
    expect(find.text('12 days left'), findsOneWidget);
    expect(find.text('Good morning, Rafi'), findsOneWidget);
    expect(find.text('100 of 500'), findsOneWidget);

    await _pump(
      tester,
      const Locale('bn'),
      (BuildContext context) => Column(
        children: <Widget>[
          Text(context.l10n.daysLeft(12)),
          Text(context.l10n.greetingMorning('রাফি')),
          // Bangla reorders the two placeholders; the generated method keeps
          // the template's (spent, limit) argument order.
          Text(context.l10n.spentOfLimit('100', '500')),
        ],
      ),
    );
    expect(find.text('12 দিন বাকি'), findsOneWidget);
    expect(find.text('শুভ সকাল, রাফি'), findsOneWidget);
    expect(find.text('500-এর মধ্যে 100'), findsOneWidget);
  });
}

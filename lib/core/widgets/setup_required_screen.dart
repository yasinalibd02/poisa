import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'kori_logo.dart';

/// Shown when `firebase_options.dart` still contains its placeholder values.
///
/// Failing here with instructions beats letting `Firebase.initializeApp` throw
/// an opaque platform error on first run.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});

  static const List<String> _steps = <String>[
    'Create a Firebase project and enable Google as the only sign-in provider.',
    'Add an Android app (com.kori.moneytracker) with your debug SHA-1 and SHA-256, and an iOS app with the same bundle id.',
    'Run: dart pub global activate flutterfire_cli',
    'Run: flutterfire configure --project=<your-project-id>',
    'Copy the Web client ID from Authentication → Google → Web SDK configuration.',
    'Run: flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B7F6B),
        fontFamily: 'Inter',
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Center(child: KoriLogo(size: 72)),
                    AppSizes.gapXl,
                    Text(
                      'Firebase setup required',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    AppSizes.gapSm,
                    Text(
                      'lib/firebase_options.dart still has placeholder values. '
                      'Finish these steps, then run the app again.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppSizes.gapXl,
                    for (int i = 0; i < _steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 12,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            AppSizes.hGapMd,
                            Expanded(
                              child: Text(
                                _steps[i],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

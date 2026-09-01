import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/firebase_service.dart';
import 'core/widgets/setup_required_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Loaded before the first frame so the app opens already themed and in the
  // right language, with no flash of English.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!FirebaseService.isConfigured) {
    // `firebase_options.dart` still holds its placeholder values. Show the
    // setup instructions rather than crashing inside Firebase.initializeApp.
    runApp(const SetupRequiredApp());
    return;
  }

  await FirebaseService.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KoriApp(),
    ),
  );
}

// Placeholder generated-file stand-in.
//
// Run `flutterfire configure --project=<your-firebase-project>` to overwrite
// this file with your real project's values. Until then `isConfigured` stays
// false and `main()` shows a setup screen instead of crashing on startup.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const String _placeholder = 'REPLACE_ME';

  /// False until `flutterfire configure` has written real values here.
  static bool get isConfigured =>
      !android.apiKey.contains(_placeholder) &&
      !ios.apiKey.contains(_placeholder);

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Kori targets Android and iOS only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Kori targets Android and iOS only; '
          '$defaultTargetPlatform is not configured.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMom8JSQZOKHQ6S5Yw99q0xPrfPdycEdE',
    appId: '1:495721871472:android:205d9fa103e6a503421cb5',
    messagingSenderId: '495721871472',
    projectId: 'poisapotro-app',
    storageBucket: 'poisapotro-app.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAd9-AZTX9VKisVgNL1v_39EfAe4uDlSAs',
    appId: '1:495721871472:ios:461641495c94ce28421cb5',
    messagingSenderId: '495721871472',
    projectId: 'poisapotro-app',
    storageBucket: 'poisapotro-app.firebasestorage.app',
    androidClientId: '495721871472-kjuu5chm0crqofct3p7066lhcbgvap2v.apps.googleusercontent.com',
    iosClientId: '495721871472-o012hs1cum4vjr39c7dd91kv0c4201us.apps.googleusercontent.com',
    iosBundleId: 'com.kori.moneytracker',
  );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// One-time Firebase bootstrap.
///
/// Offline persistence is switched on with an unlimited cache before any read
/// happens, which is what lets every screen keep working with no connection.
abstract final class FirebaseService {
  static bool _initialised = false;

  static bool get isConfigured => DefaultFirebaseOptions.isConfigured;

  static Future<void> initialize() async {
    if (_initialised) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    _initialised = true;
  }
}

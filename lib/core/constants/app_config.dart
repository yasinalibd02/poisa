/// Build-time configuration that is not part of `firebase_options.dart`.
///
/// [googleServerClientId] is the **Web client ID** from
/// Firebase console → Authentication → Sign-in method → Google → Web SDK
/// configuration. Android's Credential Manager needs it to mint the ID token
/// that Firebase exchanges for a session; iOS reads its client ID from
/// `Info.plist`. It can also be supplied without editing this file:
///
/// ```sh
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
/// ```
abstract final class AppConfig {
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String? get serverClientIdOrNull =>
      googleServerClientId.isEmpty ? null : googleServerClientId;

  /// Public links surfaced in Settings.
  static const String privacyPolicyUrl =
      'https://poisapotro-app.web.app/privacy';
  static const String termsUrl = 'https://poisapotro-app.web.app/terms';
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.kori.moneytracker';
  static const String iosStoreUrl = 'https://apps.apple.com/app/id000000000';

  static const String appVersion = '1.0.0';
}

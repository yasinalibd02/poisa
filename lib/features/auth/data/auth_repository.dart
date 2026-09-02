import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/utils/app_failure.dart';

/// Google-only authentication. The rest of the app never touches
/// `FirebaseAuth` or `GoogleSignIn` directly.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  Future<void>? _initialisation;

  /// `GoogleSignIn.initialize` must run exactly once before any other call.
  Future<void> _ensureInitialized() {
    return _initialisation ??= _google.initialize(
      serverClientId: AppConfig.serverClientIdOrNull,
    );
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  /// True while the session is an anonymous "guest" one.
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  /// Opens an anonymous session so the app is usable without a Google
  /// account. Nothing is tied to a real identity; leaving guest mode wipes
  /// the whole subtree and deletes this user (see
  /// `SettingsActions.deleteAccountAndData`).
  Future<UserCredential> continueAsGuest() async {
    try {
      return await _auth.signInAnonymously();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Runs the Google account chooser and exchanges the resulting ID token for
  /// a Firebase session.
  ///
  /// Throws [AppFailure] with [FailureKind.cancelled] when the user dismisses
  /// the sheet — callers treat that as a no-op, not an error to shout about.
  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      if (!_google.supportsAuthenticate()) {
        throw const AppFailure(
          FailureKind.unknown,
          debugMessage: 'Google sign-in is not supported on this platform.',
        );
      }

      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppFailure(
          FailureKind.unknown,
          debugMessage:
              'Google returned no ID token. Check that the server client ID '
              '(GOOGLE_SERVER_CLIENT_ID) matches the Firebase web client.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _google.signOut();
    } catch (_) {
      // A failure to clear the Google session must not block the Firebase
      // sign-out below — the user asked to leave.
    }
    try {
      await _auth.signOut();
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Re-runs the Google flow to satisfy Firebase's recent-login requirement
  /// before deleting the account.
  Future<void> reauthenticate() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    try {
      await _ensureInitialized();
      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppFailure(FailureKind.unknown);
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } catch (error) {
      throw AppFailure.from(error);
    }
  }

  /// Deletes the Firebase auth account. The Firestore subtree is wiped first
  /// by `UserRepository.deleteAllData`, because the security rules require an
  /// authenticated session to do it.
  Future<void> deleteAuthAccount() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } catch (error) {
      final AppFailure failure = AppFailure.from(error);
      if (failure.kind == FailureKind.reauthRequired) {
        await reauthenticate();
        await _auth.currentUser?.delete();
        return;
      }
      throw failure;
    }
    try {
      await _google.signOut();
    } catch (_) {
      // Non-fatal.
    }
  }
}

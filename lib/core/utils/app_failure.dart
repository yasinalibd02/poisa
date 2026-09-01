import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../l10n/app_localizations.dart';

enum FailureKind {
  /// No usable connection. Cached data may still be shown.
  network,

  /// Firestore rules rejected the operation.
  permissionDenied,

  /// The user backed out of a flow (e.g. the Google account chooser).
  cancelled,

  /// Firebase wants a fresh sign-in before a sensitive operation.
  reauthRequired,

  unknown,
}

/// A normalised error every repository throws, so the UI never has to know
/// about `FirebaseException`, `GoogleSignInException` or platform channels.
@immutable
class AppFailure implements Exception {
  const AppFailure(this.kind, {this.debugMessage});

  final FailureKind kind;
  final String? debugMessage;

  bool get isCancelled => kind == FailureKind.cancelled;

  /// Maps any thrown object onto a [AppFailure].
  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;

    if (error is GoogleSignInException) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable => AppFailure(
          FailureKind.cancelled,
          debugMessage: error.description,
        ),
        _ => AppFailure(FailureKind.unknown, debugMessage: error.description),
      };
    }

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'requires-recent-login' => AppFailure(
          FailureKind.reauthRequired,
          debugMessage: error.message,
        ),
        'network-request-failed' => AppFailure(
          FailureKind.network,
          debugMessage: error.message,
        ),
        'web-context-canceled' ||
        'user-cancelled' => AppFailure(
          FailureKind.cancelled,
          debugMessage: error.message,
        ),
        _ => AppFailure(FailureKind.unknown, debugMessage: error.message),
      };
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => AppFailure(
          FailureKind.permissionDenied,
          debugMessage: error.message,
        ),
        'unavailable' ||
        'deadline-exceeded' => AppFailure(
          FailureKind.network,
          debugMessage: error.message,
        ),
        _ => AppFailure(FailureKind.unknown, debugMessage: error.message),
      };
    }

    return AppFailure(FailureKind.unknown, debugMessage: error.toString());
  }

  String localizedMessage(AppL10n l10n) => switch (kind) {
    FailureKind.network => l10n.offlineBanner,
    FailureKind.permissionDenied => l10n.errorPermissionDenied,
    FailureKind.cancelled => l10n.signInCancelled,
    FailureKind.reauthRequired => l10n.reauthRequired,
    FailureKind.unknown => l10n.errorBody,
  };

  @override
  String toString() => 'AppFailure(${kind.name}: $debugMessage)';
}

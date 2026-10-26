import 'package:flutter/foundation.dart';

/// "Start adding a transaction" requests that arrive from outside the widget
/// tree — a reminder notification tap or a home-screen widget button. They
/// can land before the router exists (cold start), so they are parked here and
/// the app shell consumes them once a signed-in user is on screen.
abstract final class LaunchActions {
  /// A `TransactionType` name (`expense`, `income`, `transfer`), or null.
  static final ValueNotifier<String?> pendingTransactionType =
      ValueNotifier<String?>(null);

  static void requestNewTransaction(String type) {
    pendingTransactionType.value = type;
  }

  /// Returns the pending request, if any, and clears it so it runs once.
  static String? take() {
    final String? type = pendingTransactionType.value;
    pendingTransactionType.value = null;
    return type;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Bridges the app and the system-wide floating overlay window (Android only).
///
/// Shows a draggable chat-head style bubble that users can tap over other
/// apps (e.g. bKash, Nagad, SMS) to quickly log an expense or income. Bubble
/// taps reopen the app through MainActivity, landing in [HomeWidgetService].
abstract final class OverlayService {
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks if the system "Display over other apps" permission is granted.
  static Future<bool> isPermissionGranted() async {
    if (!isSupported) return false;
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      debugPrint('OverlayService: checkPermission failed: $e');
      return false;
    }
  }

  /// Opens the Android system settings to request overlay permission.
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final bool? granted = await FlutterOverlayWindow.requestPermission();
      return granted ?? await isPermissionGranted();
    } catch (e) {
      debugPrint('OverlayService: requestPermission failed: $e');
      return false;
    }
  }

  /// Checks if the overlay window is currently active/visible on screen.
  static Future<bool> isActive() async {
    if (!isSupported) return false;
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (e) {
      return false;
    }
  }

  /// Shows the floating quick entry bubble.
  static Future<bool> showFloatingBubble() async {
    if (!isSupported) return false;

    final bool granted = await isPermissionGranted();
    if (!granted) {
      final bool requested = await requestPermission();
      if (!requested) return false;
    }

    try {
      final bool active = await FlutterOverlayWindow.isActive();
      if (!active) {
        await FlutterOverlayWindow.showOverlay(
          height: 72,
          width: 72,
          alignment: OverlayAlignment.centerRight,
          visibility: NotificationVisibility.visibilitySecret,
          positionGravity: PositionGravity.auto,
          flag: OverlayFlag.defaultFlag,
          overlayTitle: 'Poisa Quick Add',
          overlayContent: 'সহজ হিসাব · Tap to add expense',
          enableDrag: true,
          dismissConfig: const OverlayDismissConfig(
            size: 56,
            bottomMargin: 48,
            shape: OverlayDismissShape.circle,
            backgroundColor: Color(0xCC1E293B),
            activeBackgroundColor: Color(0xFFDC2626),
            iconColor: Colors.white,
            iconSize: 22,
            hapticFeedback: true,
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('OverlayService: showOverlay failed: $e');
      return false;
    }
  }

  /// Closes the floating overlay window.
  static Future<void> closeBubble() async {
    if (!isSupported) return;
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      debugPrint('OverlayService: closeOverlay failed: $e');
    }
  }

  /// Synchronizes the overlay state with user preference on app startup.
  static Future<void> syncOverlayState(bool enabled) async {
    if (!isSupported) return;
    if (enabled) {
      if (await isPermissionGranted()) {
        await showFloatingBubble();
      }
    } else {
      await closeBubble();
    }
  }
}

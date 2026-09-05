import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../constants/app_colors.dart';

/// Runs in a separate isolate when a data/notification message arrives while
/// the app is backgrounded or terminated, so Firebase needs its own init.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// Push notifications via FCM: every install subscribes to [dailyReminderTopic]
/// so a single daily Cloud Function send reaches every user, with no
/// per-device token storage to manage.
abstract final class NotificationService {
  static const String dailyReminderTopic = 'daily_reminder';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'daily_reminder_channel',
    'Daily reminders',
    description: 'Daily reminder to log today\'s income and expenses.',
    importance: Importance.high,
  );

  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialised = false;

  static Future<void> initialize() async {
    if (_initialised) return;
    _initialised = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _localPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // A notification-only message is displayed by the OS automatically when
    // backgrounded; in the foreground FCM stays silent, so it's surfaced here
    // through a local notification instead.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    try {
      await FirebaseMessaging.instance.subscribeToTopic(dailyReminderTopic);
    } catch (error, stackTrace) {
      // Subscription can fail offline; the app still works, it just won't
      // receive the daily push until the next successful attempt.
      debugPrint('NotificationService: topic subscribe failed: $error\n$stackTrace');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _localPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: AppColors.primary,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

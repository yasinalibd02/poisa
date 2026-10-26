import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../firebase_options.dart';
import '../constants/app_colors.dart';
import 'launch_actions.dart';

/// Runs in a separate isolate when a data/notification message arrives while
/// the app is backgrounded or terminated, so Firebase needs its own init.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// Two kinds of notification:
///
/// * A **local daily reminder** at a time the user picks in Settings, scheduled
///   on-device so it fires offline and in the user's own timezone.
/// * **FCM pushes** via [dailyReminderTopic], kept only for installs whose user
///   has never touched the reminder switch, so nobody gets both.
abstract final class NotificationService {
  static const String dailyReminderTopic = 'daily_reminder';

  static const int _dailyReminderId = 1001;

  /// Payload of the daily reminder: tapping it opens a new expense.
  static const String _reminderPayload = 'expense';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'daily_reminder_channel',
    'Daily reminders',
    description: 'Daily reminder to log today\'s income and expenses.',
    importance: Importance.high,
  );

  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void>? _initialising;

  /// Safe to call repeatedly; every scheduling call awaits it first.
  static Future<void> initialize() => _initialising ??= _initialize();

  static Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (error) {
      // Falls back to UTC; the reminder would drift by the UTC offset, which
      // is still better than not scheduling it at all.
      debugPrint('NotificationService: timezone lookup failed: $error');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Cold start from a reminder tap: the tap callback never fires for the
    // notification that launched the process.
    final NotificationAppLaunchDetails? launch =
        await _localPlugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final NotificationResponse? response = launch!.notificationResponse;
      if (response != null) _onTap(response);
    }

    // A notification-only message is displayed by the OS automatically when
    // backgrounded; in the foreground FCM stays silent, so it's surfaced here
    // through a local notification instead.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  static void _onTap(NotificationResponse response) {
    if (response.payload == _reminderPayload) {
      LaunchActions.requestNewTransaction(_reminderPayload);
    }
  }

  /// Schedules (or reschedules) the daily reminder at [time] local time.
  static Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _localPlugin.cancel(id: _dailyReminderId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    // Exact alarms are granted by default up to Android 13 and opt-in from
    // 14; without one the OS may shift the reminder by a few minutes, which
    // is fine for a "log your day" nudge and not worth a settings detour.
    final bool canExact = await _localPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.canScheduleExactNotifications() ??
        true;

    await _localPlugin.zonedSchedule(
      id: _dailyReminderId,
      title: title,
      body: body,
      scheduledDate: next,
      payload: _reminderPayload,
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
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

  static Future<void> cancelDailyReminder() async {
    await initialize();
    await _localPlugin.cancel(id: _dailyReminderId);
  }

  /// Asks for notification permission where the OS requires a runtime grant
  /// (Android 13+, iOS). Returns whether notifications can be shown.
  static Future<bool> requestPermission() async {
    await initialize();
    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Subscribes to the server-sent daily push, or leaves it.
  static Future<void> syncTopic({required bool subscribed}) async {
    await initialize();
    try {
      if (subscribed) {
        await FirebaseMessaging.instance.subscribeToTopic(dailyReminderTopic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          dailyReminderTopic,
        );
      }
    } catch (error, stackTrace) {
      // Can fail offline; the next launch retries.
      debugPrint('NotificationService: topic sync failed: $error\n$stackTrace');
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

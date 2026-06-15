import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart' as tz;

const int _weeklyNotificationId = 401;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> _configureLocalTimeZone() async {
    try {
      initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('NotificationService: timezone config failed, using UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> init({
    void Function(NotificationResponse response)? onTap,
  }) async {
    if (_initialized) return;
    await _configureLocalTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedule (or re-schedule) the weekly weigh-in reminder.
  /// Returns `true` on success, `false` on failure.
  Future<bool> scheduleWeeklyWeighIn({
    required CalTrackRepository repo,
  }) async {
    try {
      final profile = await repo.requireProfile();
      if (!profile.onboardingCompleted) return false;

      await _plugin.cancel(_weeklyNotificationId);

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        profile.reminderHour,
        profile.reminderMinute,
      );

      while (scheduled.weekday != profile.reminderWeekday ||
          !scheduled.isAfter(now)) {
        scheduled = tz.TZDateTime(
          tz.local,
          scheduled.year,
          scheduled.month,
          scheduled.day + 1,
          profile.reminderHour,
          profile.reminderMinute,
        );
      }

      const android = AndroidNotificationDetails(
        'caltrack_weekly',
        'Weekly weigh-in',
        channelDescription: 'Reminder to log your weight and review progress.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const details = NotificationDetails(android: android);

      await _plugin.zonedSchedule(
        _weeklyNotificationId,
        'CalTrack',
        'Time to log your weight and check if your plan is working.',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '/log-weight',
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService.scheduleWeeklyWeighIn failed: $e');
      return false;
    }
  }

  /// Re-schedule the weekly reminder using the currently stored profile.
  /// Useful for [AppLifecycleListener] or boot receivers.
  Future<bool> rescheduleFromRepo({
    required CalTrackRepository repo,
  }) async {
    if (!_initialized) return false;
    return scheduleWeeklyWeighIn(repo: repo);
  }

  Future<void> cancelWeekly() async {
    await _plugin.cancel(_weeklyNotificationId);
  }

  /// Triggers a test notification immediately for debugging purposes.
  Future<void> showTestNotification() async {
    if (!_initialized) return;

    const android = AndroidNotificationDetails(
      'caltrack_test',
      'Test Notifications',
      channelDescription: 'Developer test notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);

    await _plugin.show(
      999, // test ID
      'CalTrack Test',
      'This is a test notification triggered from Dev Options.',
      details,
      payload: '/log-weight',
    );
  }
}

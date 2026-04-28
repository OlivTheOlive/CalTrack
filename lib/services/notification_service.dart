import 'package:caltrack/data/caltrack_repository.dart';
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
    initializeTimeZones();
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
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

  Future<void> scheduleWeeklyWeighIn({
    required CalTrackRepository repo,
  }) async {
    final profile = await repo.requireProfile();
    if (!profile.onboardingCompleted) return;

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
      scheduled = scheduled.add(const Duration(days: 1));
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
  }

  Future<void> cancelWeekly() async {
    await _plugin.cancel(_weeklyNotificationId);
  }
}

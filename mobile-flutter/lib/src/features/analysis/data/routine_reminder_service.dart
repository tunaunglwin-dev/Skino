import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class RoutineReminderSettings {
  const RoutineReminderSettings({
    required this.enabled,
    required this.morningHour,
    required this.morningMinute,
    required this.nightHour,
    required this.nightMinute,
  });

  final bool enabled;
  final int morningHour;
  final int morningMinute;
  final int nightHour;
  final int nightMinute;

  RoutineReminderSettings copyWith({
    bool? enabled,
    int? morningHour,
    int? morningMinute,
    int? nightHour,
    int? nightMinute,
  }) {
    return RoutineReminderSettings(
      enabled: enabled ?? this.enabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      nightHour: nightHour ?? this.nightHour,
      nightMinute: nightMinute ?? this.nightMinute,
    );
  }

  String get morningLabel => _formatTime(morningHour, morningMinute);
  String get nightLabel => _formatTime(nightHour, nightMinute);

  static const defaults = RoutineReminderSettings(
    enabled: false,
    morningHour: 8,
    morningMinute: 0,
    nightHour: 21,
    nightMinute: 0,
  );

  static String _formatTime(int hour, int minute) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

class RoutineReminderService {
  const RoutineReminderService();

  static const _enabledKey = 'skino.routine_reminders.enabled';
  static const _morningHourKey = 'skino.routine_reminders.morning_hour';
  static const _morningMinuteKey = 'skino.routine_reminders.morning_minute';
  static const _nightHourKey = 'skino.routine_reminders.night_hour';
  static const _nightMinuteKey = 'skino.routine_reminders.night_minute';
  static const _morningId = 7101;
  static const _nightId = 7102;
  static const _followUpScanId = 7103;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Yangon'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(settings: initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<RoutineReminderSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    return RoutineReminderSettings(
      enabled:
          prefs.getBool(_enabledKey) ??
          RoutineReminderSettings.defaults.enabled,
      morningHour:
          prefs.getInt(_morningHourKey) ??
          RoutineReminderSettings.defaults.morningHour,
      morningMinute:
          prefs.getInt(_morningMinuteKey) ??
          RoutineReminderSettings.defaults.morningMinute,
      nightHour:
          prefs.getInt(_nightHourKey) ??
          RoutineReminderSettings.defaults.nightHour,
      nightMinute:
          prefs.getInt(_nightMinuteKey) ??
          RoutineReminderSettings.defaults.nightMinute,
    );
  }

  Future<void> save(RoutineReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_morningHourKey, settings.morningHour);
    await prefs.setInt(_morningMinuteKey, settings.morningMinute);
    await prefs.setInt(_nightHourKey, settings.nightHour);
    await prefs.setInt(_nightMinuteKey, settings.nightMinute);

    if (settings.enabled) {
      await schedule(settings);
    } else {
      await cancel();
    }
  }

  Future<void> schedule(RoutineReminderSettings settings) async {
    await initialize();
    await cancel();
    await _scheduleDaily(
      id: _morningId,
      hour: settings.morningHour,
      minute: settings.morningMinute,
      title: 'Skino morning routine',
      body: 'Start gentle cleansing, moisturizer, and sunscreen.',
    );
    await _scheduleDaily(
      id: _nightId,
      hour: settings.nightHour,
      minute: settings.nightMinute,
      title: 'Skino night routine',
      body: 'Time for your calm night care and routine check-in.',
    );
  }

  Future<void> cancel() async {
    await initialize();
    await _notifications.cancel(id: _morningId);
    await _notifications.cancel(id: _nightId);
  }

  Future<void> scheduleFollowUpScan({
    required DateTime? startedAt,
    required int followUpDays,
  }) async {
    await initialize();
    await _notifications.cancel(id: _followUpScanId);

    final base = startedAt ?? DateTime.now();
    final target = base.add(Duration(days: followUpDays));
    var scheduled = tz.TZDateTime(
      tz.local,
      target.year,
      target.month,
      target.day,
      19,
      30,
    );
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(now)) {
      scheduled = now.add(const Duration(minutes: 3));
    }

    const androidDetails = AndroidNotificationDetails(
      'skino_scan_follow_up',
      'Scan follow-up',
      channelDescription: 'Skino routine progress scan reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: _followUpScanId,
      title: 'Skino follow-up scan',
      body: 'Time to compare your routine progress with a fresh scan.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'skino_routine_reminders',
      'Routine reminders',
      channelDescription: 'Morning and night Skino routine reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextDailyTime(hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:rxdart/rxdart.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final _onNotifications = BehaviorSubject<String?>();

  static Future<void> initialize() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Settings for both platforms
    const settings = InitializationSettings(
      android: android,
      iOS: iOS,
    );

    // Initialize plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        _onNotifications.add(details.payload);
      },
    );
  }

  static Future<NotificationDetails> _notificationDetails() async {
    // Android notification details
    const android = AndroidNotificationDetails(
      'medtrack_channel',
      'Medication Reminders',
      channelDescription: 'Channel for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // Enable sound
      enableVibration: true,
      enableLights: true,
      colorized: true,
      color: Color(0xFF6C63FF), // Updated color
    );

    // iOS notification details
    const iOS = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true, // Enable default iOS sound
    );

    return const NotificationDetails(
      android: android,
      iOS: iOS,
    );
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required List<int> days, // 1-7 where 1=Monday, 7=Sunday
    String? payload,
  }) async {
    final details = await _notificationDetails();
    
    for (final day in days) {
      // Find next matching weekday
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = _nextInstanceOfTime(time, now);
      
      // Adjust to the correct day of week
      while (scheduledDate.weekday != day) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id + day, // Unique ID for each day
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    String? payload,
  }) async {
    final details = await _notificationDetails();
    final tzDate = tz.TZDateTime.from(date, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      payload: payload,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time, tz.TZDateTime now) {
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;
  }

  static Stream<String?> get onNotifications => _onNotifications.stream;

  // Test notification method (optional)
  static Future<void> showTestNotification() async {
    await _notifications.zonedSchedule(
      9999, // Special ID for test notifications
      'Test Notification',
      'This is a test notification from MedTrack',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
      await _notificationDetails(),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
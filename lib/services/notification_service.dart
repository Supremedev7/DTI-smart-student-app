import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/app_quotes.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit, 
      iOS: iosInit
    );
    
    // FIX 1: v19+ requires 'settings' as a strictly named parameter
    await _notificationsPlugin.initialize(settings: initSettings);

    // FIX 2: Without this, Android 13+ devices will silently block all notifications!
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleDailyReminder() async {
    await _notificationsPlugin.cancelAll();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_reminders', 
      'Daily Study Reminders',
      channelDescription: 'Reminds you to keep your study streak alive',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails, 
      iOS: DarwinNotificationDetails()
    );

    // Calculate local target time accurately 
    DateTime now = DateTime.now();
    DateTime target = DateTime(now.year, now.month, now.day, 18, 0); // 6:00 PM
    
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(target, tz.local);

    // FIX 3: v19+ requires absolutely ALL arguments to be strictly named
    // FIX 4: uiLocalNotificationDateInterpretation is completely removed
    await _notificationsPlugin.zonedSchedule(
      id: 0, 
      title: 'Keep your streak alive! 🔥', 
      body: AppQuotes.getRandomQuote(), 
      scheduledDate: scheduledDate, 
      notificationDetails: platformDetails, 
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // --- ADDED FOR DEBUGGING: Lets you test the notifications instantly ---
  static Future<void> testNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel', 
      'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails, 
      iOS: DarwinNotificationDetails()
    );

    await _notificationsPlugin.show(
      id: 999, 
      title: 'StudyMate is Working! 🚀', 
      body: 'Your local notification system is perfectly configured.', 
      notificationDetails: platformDetails,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
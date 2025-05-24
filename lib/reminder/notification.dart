import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

 Future<void> init() async {
    // Initialize timezones (must be done before any scheduling)
    tz.initializeTimeZones();
    final dhaka = tz.getLocation('Asia/Dhaka');
    tz.setLocalLocation(dhaka);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped!');
      },
    );

    // Create notification channel (critical for Android 8+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medicine_reminder_channel',
      'Medicine Reminders',
      description: 'Channel for medicine reminders',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions (Android 13+)
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestPermission();
  }

  Future<void> scheduleNotificationFromFirestore(String userId, String reminderId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('user_info')
        .doc(userId)
        .collection('medicine_reminders')
        .doc(reminderId)
        .get();

    if (!doc.exists) {
      debugPrint('Reminder document not found');
      return;
    }

    final data = doc.data()!;
    final medicineName = data['name'] ?? 'Medicine';
    final dosage = data['dosage'] ?? '';
    final int timeInHour = data['timeInHour'] ?? 0;

    final DateTime initialTime = (data['time'] as Timestamp).toDate();
    final scheduledTime = tz.TZDateTime.from(initialTime, tz.local);

    debugPrint('📅 Scheduling starting from $scheduledTime');
    debugPrint('🔁 Repeats every $timeInHour hour(s)');

    await flutterLocalNotificationsPlugin.zonedSchedule(
  reminderId.hashCode,
  '💊 $medicineName Reminder',
  'Dosage: $dosage',
  scheduledTime,
  NotificationDetails(
    android: AndroidNotificationDetails(
      'medicine_reminder_channel', 
      'Medicine Reminders',
      channelDescription: 'Get notified when it\'s time to take your meds',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('medicine_reminder'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]), // More pronounced pattern
      fullScreenIntent: true, // Shows even on locked screen
      additionalFlags: Int32List.fromList([4]), // Makes sound repeat
      color: Colors.deepPurple,
      ledColor: Colors.purple,
      ledOnMs: 1000,
      ledOffMs: 500,
    ),
    iOS: DarwinNotificationDetails(
      sound: 'medicine_reminder.wav',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  ),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation: 
      UILocalNotificationDateInterpretation.absoluteTime,
  matchDateTimeComponents: DateTimeComponents.time,
);

    debugPrint('✅ Notification scheduled successfully');
  } catch (e, stack) {
    debugPrint('❌ Error scheduling notification: $e');
    debugPrint(stack.toString());
  }
}

  Future<void> showInstantNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Test Notification',
        'This is an immediate test notification',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminder_channel',
            'Medicine Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  requestPermission() {}
}

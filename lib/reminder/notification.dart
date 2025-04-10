import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Initialize the notification plugin
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
    onDidReceiveNotificationResponse: (response) {
      // Handle notification taps (you can navigate or perform actions)
      debugPrint('Notification tapped: ${response.payload}');
    },
  );

  // Create a notification channel with a matching ID
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'medicine_reminder_channel', // Must match the ID used in the schedule
    'Medicine Reminders',
    description: 'Channel for medicine reminders',
    importance: Importance.max, // Important for visibility and behavior
    enableVibration: true, // Enable vibration for reminders
  );

  // Ensure the notification channel is created only on Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  debugPrint('🔔 Notification channel created');
}


  Future<void> scheduleFromFirestore(String userId) async {
    try {
      print('Fetching reminders for user: $userId');
      final reminders =
          await FirebaseFirestore.instance
              .collection('user_info')
              .doc(userId)
              .collection('medicine_reminders')
              .where('isCompleted', isEqualTo: false)
              .get();

      print('Found ${reminders.docs.length} reminders to schedule');

      for (var doc in reminders.docs) {
        final data = doc.data();
        final reminderId = data['reminderId'] ?? doc.id;
        final name = data['name'];
        final dosage = data['dosage'];
        final time = (data['time'] as Timestamp).toDate();

        print('Processing reminder: $name at $time');

        if (time.isAfter(DateTime.now())) {
          await scheduleMedicineReminder(
            reminderId: reminderId,
            medicineName: name,
            dosage: dosage,
            reminderTime: time,
          );
        } else {
          print('Reminder time $time is in the past - skipping');
        }
      }
    } catch (e) {
      print('Error scheduling from Firestore: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final bool? granted =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestPermission();

      print('Notification permission granted: $granted');
    }
  }

  Future<void> scheduleMedicineReminder({
    required String reminderId,
    required String medicineName,
    required String dosage,
    required DateTime reminderTime,
  }) async {
    try {
      // 1. Generate consistent notification ID
      int notificationId = reminderId.hashCode.abs();

      // 2. Convert to local timezone (Asia/Dhaka)
      final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);

      debugPrint('⌚ Scheduling: $medicineName at ${scheduledTime.toLocal()}');

      // 3. Notification details (updated for v19)
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'medicine_reminder_channel', // Must match channel ID
            'Medicine Reminders',
            channelDescription: 'Channel for medicine reminders',
            importance: Importance.max, // Changed from high to max
            priority: Priority.high,
            enableVibration: true,
            showWhen: true,
            // Added for better reliability
            channelShowBadge: true,
            autoCancel: false,
          );

      // 4. Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Time to take $medicineName',
        'Dosage: $dosage',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exact,
        // uiLocalNotificationDateInterpretation:
        //     UILocalNotificationDateInterpretation
        //         .absoluteTime, // optional, safe
      );

      debugPrint('✅ Scheduled successfully for ${scheduledTime.toLocal()}');

      // Debug: Print all pending notifications
      final pending =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('ℹ️ Total pending notifications: ${pending.length}');
    } catch (e, stackTrace) {
      debugPrint('❌ Scheduling failed: $e');
      debugPrint(stackTrace.toString());

      // Additional error diagnostics
      if (e.toString().contains('channel')) {
        debugPrint('⚠️ Please verify notification channel exists');
      }
    }
  }

  static Future<void> testNotification() async {
    await _instance.flutterLocalNotificationsPlugin.show(
      99999,
      'Test Notification',
      'This should appear immediately',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminder_channel',
          'Medicine Reminders',
          importance: Importance.high,
        ),
      ),
    );
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  requestPermission() {}
}

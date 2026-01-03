import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // You can navigate to a specific screen here if needed
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // User denied permission
      return false;
    } else if (status.isPermanentlyDenied) {
      // User permanently denied, open settings
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Schedule daily notification at specific time
  Future<void> scheduleDailyNotification({
    required TimeOfDay time,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Request permissions first
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Notification permission not granted');
    }

    // Cancel any existing notifications
    await _notifications.cancel(0);

    // Create notification time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the scheduled time is before now, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      '일일 알림',
      channelDescription: '목표 기록을 위한 일일 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      0, // notification id
      '목표 기록 시간입니다! 🎯',
      '오늘의 성취를 기록해보세요!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    debugPrint('Daily notification scheduled at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  /// Check if notifications are enabled for this app
  Future<bool> areNotificationsEnabled() async {
    return await Permission.notification.isGranted;
  }

  /// Show immediate test notification
  Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      '테스트 알림',
      channelDescription: '테스트용 알림 채널',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '테스트 알림 🔔',
      '알림이 정상적으로 작동합니다!',
      details,
      payload: 'test',
    );
  }
}

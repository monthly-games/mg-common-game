import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;

  NotificationManager._();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  final StreamController<NotificationEvent> _controller = StreamController.broadcast();

  Stream<NotificationEvent> get onNotification => _controller.stream;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = IOSInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    await _notificationsPlugin!.initialize(initSettings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails('channel_id', 'channel_name', importance: Importance.max);
    const iosDetails = IOSNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin!.show(0, title, body, details: details, payload: payload);
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails('channel_id', 'channel_name');
    const iosDetails = IOSNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin!.zonedSchedule(0, title, body, scheduledTime, details, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  void dispose() {
    _controller.close();
  }
}

class NotificationEvent {
  final String title;
  final String body;
  final String? payload;

  const NotificationEvent({required this.title, required this.body, this.payload});
}

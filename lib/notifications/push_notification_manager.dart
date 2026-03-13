import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 푸시 알림 타입
enum PushNotificationType {
  questReminder,
  eventStart,
  rewardReady,
  friendInvite,
  dailyBonus,
  maintenance,
  update,
  custom,
}

/// 푸시 알림 데이터
class PushNotificationData {
  final String id;
  final PushNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final DateTime? scheduledTime;
  final String? channelId;
  final String? channelName;
  final String? channelDescription;

  const PushNotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    this.scheduledTime,
    this.channelId,
    this.channelName,
    this.channelDescription,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'payload': payload,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'channelId': channelId,
        'channelName': channelName,
        'channelDescription': channelDescription,
      };
}

/// 푸시 알림 매니저
class PushNotificationManager {
  static final PushNotificationManager _instance =
      PushNotificationManager._();
  static PushNotificationManager get instance => _instance;

  PushNotificationManager._();

  // ============================================
  // 상태
  // ============================================
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<PushNotificationData> _notificationController =
      StreamController<PushNotificationData>.broadcast();
  final StreamController<Map<String, dynamic>> _tapController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  String? _fcmToken;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPermissionGranted => _isPermissionGranted;
  String? get fcmToken => _fcmToken;
  Stream<PushNotificationData> get onNotification =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get onNotificationTap => _tapController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    // FCM 초기화
    await _setupFCM();

    _isInitialized = true;

    debugPrint('[PushNotification] Initialized');
  }

  /// FCM 설정
  Future<void> _setupFCM() async {
    // 권한 요청
    final settings = await _messaging.requestPermission();

    _isPermissionGranted = settings.authorizationStatus ==
        AuthorizationStatus.authorized;

    if (_isPermissionGranted) {
      // FCM 토큰获取
      _fcmToken = await _messaging.getToken();
      debugPrint('[PushNotification] FCM Token: $_fcmToken');

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('[PushNotification] FCM Token refreshed: $token');
      });

      // 포그라운드 메시지 핸들링
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드 메시지 핸들링
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[PushNotification] Foreground message: ${message.notification}');

    final notification = PushNotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseNotificationType(message.data['type']),
      title: message.notification?.title ?? '알림',
      body: message.notification?.body ?? '',
      payload: message.data,
    );

    _notificationController.add(notification);

    // 로컬 알림으로 표시
    showLocalNotification(notification);
  }

  /// 백그라운드 메시지 처리
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('[PushNotification] Background message: ${message.data}');

    final notification = PushNotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseNotificationType(message.data['type']),
      title: message.notification?.title ?? '알림',
      body: message.notification?.body ?? '',
      payload: message.data,
    );

    _tapController.add(message.data);
  }

  /// 알림 탭 처리
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      debugPrint('[PushNotification] Notification tapped: $payload');
      _tapController.add({'payload': payload});
    }
  }

  PushNotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == null) return PushNotificationType.custom;

    return PushNotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => PushNotificationType.custom,
    );
  }

  // ============================================
  // 알림 표시
  // ============================================

  /// 로컬 알림 표시
  Future<void> showLocalNotification(PushNotificationData notification) async {
    if (!_isPermissionGranted) {
      debugPrint('[PushNotification] Permission not granted');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'mg_games_channel',
      'MG Games',
      channelDescription: 'MG Games 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: notification.payload?.toString(),
    );
  }

  /// 즉시 알림 표시
  Future<void> showNotification({
    required String title,
    required String body,
    PushNotificationType type = PushNotificationType.custom,
    Map<String, dynamic>? payload,
  }) async {
    final notification = PushNotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      body: body,
      payload: payload,
    );

    await showLocalNotification(notification);
  }

  // ============================================
  // 알림 스케줄링
  // ============================================

  /// 스케줄된 알림 등록
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    PushNotificationType type = PushNotificationType.custom,
    Map<String, dynamic>? payload,
  }) async {
    if (!_isPermissionGranted) return;

    final notification = PushNotificationData(
      id: id,
      type: type,
      title: title,
      body: body,
      payload: payload,
      scheduledTime: scheduledTime,
    );

    const androidDetails = AndroidNotificationDetails(
      'mg_games_channel',
      'MG Games',
      channelDescription: 'MG Games 알림',
      importance: Importance.high,
      priority: Priority.high,
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

    final tzScheduledTime = notification.scheduledTime!;

    await _localNotifications.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      tzScheduledTime,
      details,
      payload: notification.payload?.toString(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[PushNotification] Scheduled: $title at $scheduledTime');
  }

  /// 주기적 알림 등록
  Future<void> schedulePeriodicNotification({
    required String id,
    required String title,
    required String body,
    required Duration interval,
    PushNotificationType type = PushNotificationType.custom,
    Map<String, dynamic>? payload,
  }) async {
    if (!_isPermissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      'mg_games_channel',
      'MG Games',
      channelDescription: 'MG Games 알림',
      importance: Importance.high,
      priority: Priority.high,
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

    await _localNotifications.periodicallyShow(
      id.hashCode,
      title,
      body,
      interval,
      details,
      payload: payload?.toString(),
    );

    debugPrint('[PushNotification] Periodic scheduled: $title every $interval');
  }

  /// 스케줄된 알림 취소
  Future<void> cancelNotification(String id) async {
    await _localNotifications.cancel(id.hashCode);
    debugPrint('[PushNotification] Cancelled: $id');
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('[PushNotification] All notifications cancelled');
  }

  // ============================================
  // 토픽 구독
  // ============================================

  /// 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[PushNotification] Subscribed to: $topic');
  }

  /// 토픽 구독 취소
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[PushNotification] Unsubscribed from: $topic');
  }

  // ============================================
  // 프리셋 알림
  // ============================================

  /// 일일 퀘스트 리마인더
  Future<void> scheduleQuestReminder() async {
    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      20, // 오후 8시
      0,
    );

    if (reminderTime.isBefore(now)) {
      reminderTime.add(const Duration(days: 1));
    }

    await schedulePeriodicNotification(
      id: 'quest_reminder',
      title: '일일 퀘스트',
      body: '아직 완료하지 않은 퀘스트가 있습니다!',
      interval: const Duration(days: 1),
      type: PushNotificationType.questReminder,
    );
  }

  /// 이벤트 시작 알림
  Future<void> scheduleEventStart({
    required String eventId,
    required String eventName,
    required DateTime startTime,
  }) async {
    await scheduleNotification(
      id: 'event_start_$eventId',
      title: '이벤트 시작',
      body: '$eventName 이벤트가 곧 시작됩니다!',
      scheduledTime: startTime.subtract(const Duration(hours: 1)),
      type: PushNotificationType.eventStart,
      payload: {'eventId': eventId},
    );
  }

  /// 보상 준비 알림
  Future<void> notifyRewardReady({
    required String rewardType,
    required int amount,
  }) async {
    await showNotification(
      title: '보상 도착!',
      body: '$amount $rewardType을(를) 받았습니다',
      type: PushNotificationType.rewardReady,
    );
  }

  /// 친구 초대 알림
  Future<void> notifyFriendInvite({
    required String friendName,
  }) async {
    await showNotification(
      title: '친구 초대',
      body: '$friendName님이 게임에 초대했습니다',
      type: PushNotificationType.friendInvite,
    );
  }

  /// 일일 보너스 알림
  Future<void> scheduleDailyBonus() async {
    final now = DateTime.now();
    final bonusTime = DateTime(
      now.year,
      now.month,
      now.day,
      12, // 정오
      0,
    );

    if (bonusTime.isBefore(now)) {
      bonusTime.add(const Duration(days: 1));
    }

    await schedulePeriodicNotification(
      id: 'daily_bonus',
      title: '일일 보너스',
      body: '일일 보너스를 받으세요!',
      interval: const Duration(days: 1),
      type: PushNotificationType.dailyBonus,
    );
  }

  /// 점검 알림
  Future<void> notifyMaintenance({
    required DateTime startTime,
    required Duration duration,
  }) async {
    await scheduleNotification(
      id: 'maintenance',
      title: '서버 점검',
      body: '${duration.inHours}시간 동안 점검이 예정되어 있습니다',
      scheduledTime: startTime.subtract(const Duration(minutes: 30)),
      type: PushNotificationType.maintenance,
    );
  }

  /// 업데이트 알림
  Future<void> notifyUpdate({
    required String version,
    required String updateUrl,
  }) async {
    await showNotification(
      title: '새로운 업데이트',
      body: '버전 $version이(가) 출시되었습니다',
      type: PushNotificationType.update,
      payload: {'updateUrl': updateUrl},
    );
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _notificationController.close();
    _tapController.close();
  }
}

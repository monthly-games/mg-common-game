import 'dart:async';
import 'package:flutter/material.dart';

/// 푸시 알림 타입
enum PushNotificationType {
  promotional,
  transactional,
  social,
  system,
  reminder,
}

/// 알림 우선순위
enum NotificationPriority {
  min,
  low,
  default,
  high,
  max,
}

/// 알림 채널
class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final Importance importance;
  final bool showBadge;
  final bool enableVibration;
  final bool enableSound;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    this.importance = Importance.default,
    this.showBadge = true,
    this.enableVibration = true,
    this.enableSound = true,
  });
}

/// 중요도
enum Importance {
  none,
  min,
  low,
  default,
  high,
  max,
}

/// 푸시 알림 메시지
class PushNotification {
  final String id;
  final String title;
  final String body;
  final PushNotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? bigTextStyle;
  final DateTime scheduledTime;
  bool read;

  PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.default,
    this.data,
    this.imageUrl,
    this.bigTextStyle,
    required this.scheduledTime,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'priority': priority.name,
        'data': data,
        'imageUrl': imageUrl,
        'bigTextStyle': bigTextStyle,
        'scheduledTime': scheduledTime.toIso8601String(),
        'read': read,
      };
}

/// 예약된 알림
class ScheduledNotification {
  final String id;
  final PushNotification notification;
  final DateTime scheduledTime;

  ScheduledNotification({
    required this.id,
    required this.notification,
    required this.scheduledTime,
  });
}

/// 푸시 알림 매니저
class PushNotificationManager {
  static final PushNotificationManager _instance = PushNotificationManager._();
  static PushNotificationManager get instance => _instance;

  PushNotificationManager._();

  final List<NotificationChannel> _channels = [];
  final List<PushNotification> _notifications = [];
  final List<ScheduledNotification> _scheduledNotifications = [];

  final StreamController<PushNotification> _notificationController =
      StreamController<PushNotification>.broadcast();

  Stream<PushNotification> get onNotification => _notificationController.stream;

  bool _initialized = false;
  String? _fcmToken;
  bool _permissionsGranted = false;

  /// 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    // 기본 채널 생성
    _createDefaultChannels();

    // FCM 초기화 (실제로는 firebase_messaging 사용)
    await _initializeFCM();

    // 권한 요청
    await _requestPermissions();

    _initialized = true;

    debugPrint('[PushNotification] Initialized');
  }

  void _createDefaultChannels() {
    _channels.addAll([
      const NotificationChannel(
        id: 'promotions',
        name: '프로모션',
        description: '할인, 이벤트 등 프로모션 알림',
        importance: Importance.high,
      ),
      const NotificationChannel(
        id: 'social',
        name: '소셜',
        description: '친구, 길드 등 소셜 알림',
        importance: Importance.default,
      ),
      const NotificationChannel(
        id: 'game',
        name: '게임',
        description: '퀘스트, 리워드 등 게임 알림',
        importance: Importance.high,
      ),
      const NotificationChannel(
        id: 'system',
        name: '시스템',
        description: '앱 업데이트, 점검 등 시스템 알림',
        importance: Importance.max,
      ),
    ]);
  }

  Future<void> _initializeFCM() async {
    // 실제 구현에서는 firebase_messaging 사용
    // FirebaseMessaging.instance.getToken();
    debugPrint('[PushNotification] FCM initialized');
  }

  Future<void> _requestPermissions() async {
    // 실제 구현에서는 권한 요청
    _permissionsGranted = true;
    debugPrint('[PushNotification] Permissions granted');
  }

  /// 채널 추가
  void addChannel(NotificationChannel channel) {
    _channels.add(channel);
    debugPrint('[PushNotification] Channel added: ${channel.id}');
  }

  /// 알림 표시
  Future<void> showNotification(PushNotification notification) async {
    if (!_permissionsGranted) {
      debugPrint('[PushNotification] Permissions not granted');
      return;
    }

    _notifications.add(notification);
    _notificationController.add(notification);

    debugPrint('[PushNotification] Shown: ${notification.title}');

    // 실제 구현에서는 flutter_local_notifications 사용
    // await _localNotifications.show(
    //   notification.id.hashCode,
    //   notification.title,
    //   notification.body,
    //   NotificationDetails(...),
    // );
  }

  /// 로컬 알림 예약
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    PushNotificationType type = PushNotificationType.reminder,
    NotificationPriority priority = NotificationPriority.default,
    Map<String, dynamic>? data,
    String? channelId,
  }) async {
    final notification = PushNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      priority: priority,
      data: data,
      scheduledTime: scheduledTime,
    );

    final scheduled = ScheduledNotification(
      id: id,
      notification: notification,
      scheduledTime: scheduledTime,
    );

    _scheduledNotifications.add(scheduled);

    // 타이머 설정
    final delay = scheduledTime.difference(DateTime.now());
    if (delay > Duration.zero) {
      Timer(delay, () {
        showNotification(notification);
        _scheduledNotifications.remove(scheduled);
      });
    }

    debugPrint('[PushNotification] Scheduled: $title at $scheduledTime');
  }

  /// 주기적 알림 예약
  Future<void> schedulePeriodicNotification({
    required String id,
    required String title,
    required String body,
    required Duration interval,
    String? channelId,
  }) async {
    // 실제 구현에서는 주기적 알림 설정
    debugPrint('[PushNotification] Periodic scheduled: $title every $interval');
  }

  /// 알림 취소
  Future<void> cancelNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _scheduledNotifications.removeWhere((n) => n.id == id);

    debugPrint('[PushNotification] Cancelled: $id');
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    _notifications.clear();
    _scheduledNotifications.clear();

    debugPrint('[PushNotification] All notifications cancelled');
  }

  /// 알림 읽음 표시
  void markAsRead(String id) {
    final notification = _notifications.firstWhere((n) => n.id == id);
    notification.read = true;
  }

  /// 알림 목록 조회
  List<PushNotification> getNotifications({bool unreadOnly = false}) {
    var notifications = _notifications.toList();
    notifications.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    if (unreadOnly) {
      notifications = notifications.where((n) => !n.read).toList();
    }

    return notifications;
  }

  /// 예약된 알림 조회
  List<ScheduledNotification> getScheduledNotifications() {
    return _scheduledNotifications.toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// FCM 토큰 설정
  void setFCMToken(String token) {
    _fcmToken = token;
    debugPrint('[PushNotification] FCM Token updated');
  }

  /// FCM 토큰 갱신
  Future<void> refreshFCMToken() async {
    // 실제 구현에서는 토큰 갱신
    debugPrint('[PushNotification] FCM Token refreshed');
  }

  /// 주제 구독
  Future<void> subscribeToTopic(String topic) async {
    // FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[PushNotification] Subscribed to: $topic');
  }

  /// 주제 구독 취소
  Future<void> unsubscribeFromTopic(String topic) async {
    // FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('[PushNotification] Unsubscribed from: $topic');
  }

  /// 알림 설정
  NotificationSettings _settings = NotificationSettings(
    promotionalEnabled: true,
    socialEnabled: true,
    gameEnabled: true,
    systemEnabled: true,
    soundEnabled: true,
    vibrationEnabled: true,
    quietHoursStart: const TimeOfDay(hour: 22, minute: 0),
    quietHoursEnd: const TimeOfDay(hour: 8, minute: 0),
    quietHoursEnabled: false,
  );

  NotificationSettings get settings => _settings;

  void updateSettings(NotificationSettings settings) {
    _settings = settings;
    debugPrint('[PushNotification] Settings updated');
  }

  /// 조용한 시간 확인
  bool isQuietHours() {
    if (!_settings.quietHoursEnabled) return false;

    final now = TimeOfDay.now();
    final start = _settings.quietHoursStart;
    final end = _settings.quietHoursEnd;

    if (start.hour < end.hour) {
      // 같은 날
      return now.hour >= start.hour && now.hour < end.hour;
    } else {
      // 자정을 넘어가는 경우
      return now.hour >= start.hour || now.hour < end.hour;
    }
  }

  /// 알림 전송 (서버에서)
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // 실제 구현에서는 FCM Admin SDK 또는 HTTP API 사용
    debugPrint('[PushNotification] Sent to $token: $title');
  }

  /// 토픽별 전송
  Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    debugPrint('[PushNotification] Sent to topic $topic: $title');
  }

  /// 다중 전송
  Future<void> sendMulticast({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    debugPrint('[PushNotification] Sent to ${tokens.length} devices');
  }

  void dispose() {
    _notificationController.close();
  }
}

/// 알림 설정
class NotificationSettings {
  final bool promotionalEnabled;
  final bool socialEnabled;
  final bool gameEnabled;
  final bool systemEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final bool quietHoursEnabled;

  const NotificationSettings({
    this.promotionalEnabled = true,
    this.socialEnabled = true,
    this.gameEnabled = true,
    this.systemEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 8, minute: 0),
    this.quietHoursEnabled = false,
  });

  NotificationSettings copyWith({
    bool? promotionalEnabled,
    bool? socialEnabled,
    bool? gameEnabled,
    bool? systemEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? quietHoursEnabled,
  }) {
    return NotificationSettings(
      promotionalEnabled: promotionalEnabled ?? this.promotionalEnabled,
      socialEnabled: socialEnabled ?? this.socialEnabled,
      gameEnabled: gameEnabled ?? this.gameEnabled,
      systemEnabled: systemEnabled ?? this.systemEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }
}

/// 알림 템플릿
class NotificationTemplate {
  final String id;
  final String name;
  final String titleTemplate;
  final String bodyTemplate;
  final PushNotificationType type;
  final Map<String, dynamic> defaultData;

  const NotificationTemplate({
    required this.id,
    required this.name,
    required this.titleTemplate,
    required this.bodyTemplate,
    required this.type,
    this.defaultData = const {},
  });

  /// 템플릿으로 알림 생성
  PushNotification create({
    required Map<String, dynamic> variables,
    String? id,
    NotificationPriority? priority,
    String? imageUrl,
  }) {
    String title = titleTemplate;
    String body = bodyTemplate;

    variables.forEach((key, value) {
      title = title.replaceAll('{$key}', value.toString());
      body = body.replaceAll('{$key}', value.toString());
    });

    return PushNotification(
      id: id ?? '${this.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      priority: priority ?? NotificationPriority.default,
      data: {...defaultData, ...variables},
      imageUrl: imageUrl,
      scheduledTime: DateTime.now(),
    );
  }
}

/// 알림 템플릿 관리자
class NotificationTemplateManager {
  final Map<String, NotificationTemplate> _templates = {};

  void registerTemplate(NotificationTemplate template) {
    _templates[template.id] = template;
  }

  NotificationTemplate? getTemplate(String id) {
    return _templates[id];
  }

  PushNotification? createFromTemplate(
    String templateId, {
    required Map<String, dynamic> variables,
    String? id,
    NotificationPriority? priority,
    String? imageUrl,
  }) {
    final template = getTemplate(templateId);
    if (template == null) return null;

    return template.create(
      variables: variables,
      id: id,
      priority: priority,
      imageUrl: imageUrl,
    );
  }

  /// 기본 템플릿 등록
  void registerDefaultTemplates() {
    registerTemplate(const NotificationTemplate(
      id: 'daily_reward',
      name: '일일 보상',
      titleTemplate: '일일 보상 도착!',
      bodyTemplate: '{userName}님, 오늘의 보상을 받으세요!',
      type: PushNotificationType.reminder,
      defaultData: {'action': 'claim_daily_reward'},
    ));

    registerTemplate(const NotificationTemplate(
      id: 'guild_war',
      name: '길드 전 알림',
      titleTemplate: '길드 전 시작!',
      bodyTemplate: '{guildName} 길드 전이 {minutes}분 후 시작됩니다.',
      type: PushNotificationType.social,
      defaultData: {'action': 'guild_war'},
    ));

    registerTemplate(const NotificationTemplate(
      id: 'quest_complete',
      name: '퀘스트 완료',
      titleTemplate: '퀘스트 완료!',
      bodyTemplate: '{questName} 퀘스트를 완료했습니다.',
      type: PushNotificationType.transactional,
      defaultData: {'action': 'claim_quest_reward'},
    ));
  }
}

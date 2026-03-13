import 'dart:async';
import 'package:flutter/material.dart';

enum NotificationType {
  alert,
  promo,
  reward,
  social,
  system,
  update,
  event,
  reminder,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationStatus {
  scheduled,
  sent,
  delivered,
  opened,
  failed,
  cancelled,
}

enum DeliveryMethod {
  push,
  inApp,
  email,
  sms,
}

class PushNotification {
  final String notificationId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final String? userId;
  final List<String>? userIds;
  final String? segmentId;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? deepLink;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final NotificationStatus status;
  final DeliveryMethod method;
  final int ttl;

  const PushNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.userId,
    this.userIds,
    this.segmentId,
    this.data,
    this.imageUrl,
    this.deepLink,
    this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.openedAt,
    required this.status,
    required this.method,
    required this.ttl,
  });

  bool get isScheduled => status == NotificationStatus.scheduled;
  bool get isSent => status == NotificationStatus.sent;
  bool get isDelivered => status == NotificationStatus.delivered;
  bool get isPending => isScheduled || isSent;
  bool get isCompleted => status == NotificationStatus.delivered || status == NotificationStatus.opened;
}

class NotificationPreference {
  final String userId;
  final bool enablePush;
  final bool enableInApp;
  final bool enableEmail;
  final bool enableSMS;
  final Map<NotificationType, bool> typePreferences;
  final Map<NotificationPriority, bool> priorityPreferences;
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final String timezone;

  const NotificationPreference({
    required this.userId,
    required this.enablePush,
    required this.enableInApp,
    required this.enableEmail,
    required this.enableSMS,
    required this.typePreferences,
    required this.priorityPreferences,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.timezone,
  });

  bool shouldReceive(NotificationType type, NotificationPriority priority) {
    if (!enablePush && !enableInApp && !enableEmail && !enableSMS) {
      return false;
    }

    if (typePreferences[type] == false) {
      return false;
    }

    if (priorityPreferences[priority] == false) {
      return false;
    }

    return true;
  }

  bool isInQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      quietHoursStart!.hour,
      quietHoursStart!.minute,
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      quietHoursEnd!.hour,
      quietHoursEnd!.minute,
    );

    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}

class NotificationSegment {
  final String segmentId;
  final String name;
  final String description;
  final Map<String, dynamic> criteria;
  final int estimatedSize;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NotificationSegment({
    required this.segmentId,
    required this.name,
    required this.description,
    required this.criteria,
    required this.estimatedSize,
    required this.createdAt,
    this.updatedAt,
  });
}

class NotificationCampaign {
  final String campaignId;
  final String name;
  final String description;
  final NotificationType type;
  final List<String> notificationIds;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final int totalRecipients;
  final int sentCount;
  final int deliveredCount;
  final int openedCount;
  final bool isActive;

  const NotificationCampaign({
    required this.campaignId,
    required this.name,
    required this.description,
    required this.type,
    required this.notificationIds,
    required this.scheduledStart,
    this.scheduledEnd,
    required this.totalRecipients,
    required this.sentCount,
    required this.deliveredCount,
    required this.openedCount,
    required this.isActive,
  });

  double get deliveryRate => totalRecipients > 0 ? deliveredCount / totalRecipients : 0.0;
  double get openRate => deliveredCount > 0 ? openedCount / deliveredCount : 0.0;
}

class PushNotificationManager {
  static final PushNotificationManager _instance = PushNotificationManager._();
  static PushNotificationManager get instance => _instance;

  PushNotificationManager._();

  final Map<String, PushNotification> _notifications = {};
  final Map<String, NotificationPreference> _preferences = {};
  final Map<String, NotificationSegment> _segments = {};
  final Map<String, NotificationCampaign> _campaigns = {};
  final StreamController<NotificationEvent> _eventController = StreamController.broadcast();
  Timer? _processingTimer;
  String? _deviceToken;

  Stream<NotificationEvent> get onNotificationEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultSegments();
    await _loadDefaultPreferences();
    _startProcessingTimer();
  }

  Future<void> _loadDefaultSegments() async {
    final segments = [
      NotificationSegment(
        segmentId: 'all_users',
        name: 'All Users',
        description: 'All registered users',
        criteria: {},
        estimatedSize: 10000,
        createdAt: DateTime.now(),
      ),
      NotificationSegment(
        segmentId: 'active_users',
        name: 'Active Users',
        description: 'Users active in last 7 days',
        criteria: {'lastActive': '7d'},
        estimatedSize: 5000,
        createdAt: DateTime.now(),
      ),
      NotificationSegment(
        segmentId: 'premium_users',
        name: 'Premium Users',
        description: 'Users with active subscription',
        criteria: {'subscription': 'active'},
        estimatedSize: 1000,
        createdAt: DateTime.now(),
      ),
    ];

    for (final segment in segments) {
      _segments[segment.segmentId] = segment;
    }
  }

  Future<void> _loadDefaultPreferences() async {
    final defaultPrefs = NotificationPreference(
      userId: 'default',
      enablePush: true,
      enableInApp: true,
      enableEmail: false,
      enableSMS: false,
      typePreferences: {
        NotificationType.alert: true,
        NotificationType.promo: true,
        NotificationType.reward: true,
        NotificationType.social: true,
        NotificationType.system: true,
        NotificationType.update: true,
        NotificationType.event: true,
        NotificationType.reminder: true,
      },
      priorityPreferences: {
        NotificationPriority.low: true,
        NotificationPriority.normal: true,
        NotificationPriority.high: true,
        NotificationPriority.urgent: true,
      },
      timezone: 'UTC',
    );

    _preferences['default'] = defaultPrefs;
  }

  void _startProcessingTimer() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _processScheduledNotifications(),
    );
  }

  void setDeviceToken(String token) {
    _deviceToken = token;
  }

  Future<String> sendNotification({
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? userId,
    List<String>? userIds,
    String? segmentId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? deepLink,
    DateTime? scheduledAt,
    DeliveryMethod method = DeliveryMethod.push,
    int ttl = 86400,
  }) async {
    final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}';

    final notification = PushNotification(
      notificationId: notificationId,
      title: title,
      body: body,
      type: type,
      priority: priority,
      userId: userId,
      userIds: userIds,
      segmentId: segmentId,
      data: data,
      imageUrl: imageUrl,
      deepLink: deepLink,
      scheduledAt: scheduledAt,
      status: scheduledAt != null ? NotificationStatus.scheduled : NotificationStatus.sent,
      method: method,
      ttl: ttl,
    );

    _notifications[notificationId] = notification;

    _eventController.add(NotificationEvent(
      type: NotificationEventType.notificationCreated,
      notificationId: notificationId,
      timestamp: DateTime.now(),
    ));

    if (scheduledAt == null) {
      await _deliverNotification(notification);
    }

    return notificationId;
  }

  Future<void> _processScheduledNotifications() async {
    final now = DateTime.now();

    for (final notification in _notifications.values) {
      if (notification.isScheduled &&
          notification.scheduledAt != null &&
          now.isAfter(notification.scheduledAt!)) {
        await _deliverNotification(notification);
      }
    }
  }

  Future<void> _deliverNotification(PushNotification notification) async {
    final updated = PushNotification(
      notificationId: notification.notificationId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      priority: notification.priority,
      userId: notification.userId,
      userIds: notification.userIds,
      segmentId: notification.segmentId,
      data: notification.data,
      imageUrl: notification.imageUrl,
      deepLink: notification.deepLink,
      scheduledAt: notification.scheduledAt,
      sentAt: DateTime.now(),
      deliveredAt: DateTime.now(),
      openedAt: notification.openedAt,
      status: NotificationStatus.delivered,
      method: notification.method,
      ttl: notification.ttl,
    );

    _notifications[notification.notificationId] = updated;

    _eventController.add(NotificationEvent(
      type: NotificationEventType.notificationDelivered,
      notificationId: notification.notificationId,
      timestamp: DateTime.now(),
    ));
  }

  Future<bool> markAsOpened({
    required String notificationId,
    required String userId,
  }) async {
    final notification = _notifications[notificationId];
    if (notification == null) return false;

    final updated = PushNotification(
      notificationId: notification.notificationId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      priority: notification.priority,
      userId: notification.userId,
      userIds: notification.userIds,
      segmentId: notification.segmentId,
      data: notification.data,
      imageUrl: notification.imageUrl,
      deepLink: notification.deepLink,
      scheduledAt: notification.scheduledAt,
      sentAt: notification.sentAt,
      deliveredAt: notification.deliveredAt,
      openedAt: DateTime.now(),
      status: NotificationStatus.opened,
      method: notification.method,
      ttl: notification.ttl,
    );

    _notifications[notificationId] = updated;

    _eventController.add(NotificationEvent(
      type: NotificationEventType.notificationOpened,
      notificationId: notificationId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> cancelNotification(String notificationId) async {
    final notification = _notifications[notificationId];
    if (notification == null) return false;

    if (notification.isPending) {
      final updated = PushNotification(
        notificationId: notification.notificationId,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        priority: notification.priority,
        userId: notification.userId,
        userIds: notification.userIds,
        segmentId: notification.segmentId,
        data: notification.data,
        imageUrl: notification.imageUrl,
        deepLink: notification.deepLink,
        scheduledAt: notification.scheduledAt,
        sentAt: notification.sentAt,
        deliveredAt: notification.deliveredAt,
        openedAt: notification.openedAt,
        status: NotificationStatus.cancelled,
        method: notification.method,
        ttl: notification.ttl,
      );

      _notifications[notificationId] = updated;

      _eventController.add(NotificationEvent(
        type: NotificationEventType.notificationCancelled,
        notificationId: notificationId,
        timestamp: DateTime.now(),
      ));

      return true;
    }

    return false;
  }

  void setPreference(NotificationPreference preference) {
    _preferences[preference.userId] = preference;

    _eventController.add(NotificationEvent(
      type: NotificationEventType.preferenceUpdated,
      userId: preference.userId,
      timestamp: DateTime.now(),
    ));
  }

  NotificationPreference? getPreference(String userId) {
    return _preferences[userId] ?? _preferences['default'];
  }

  NotificationSegment createSegment({
    required String segmentId,
    required String name,
    required String description,
    required Map<String, dynamic> criteria,
  }) {
    final segment = NotificationSegment(
      segmentId: segmentId,
      name: name,
      description: description,
      criteria: criteria,
      estimatedSize: 0,
      createdAt: DateTime.now(),
    );

    _segments[segmentId] = segment;

    return segment;
  }

  List<NotificationSegment> getAllSegments() {
    return _segments.values.toList();
  }

  NotificationSegment? getSegment(String segmentId) {
    return _segments[segmentId];
  }

  NotificationCampaign createCampaign({
    required String campaignId,
    required String name,
    required String description,
    required NotificationType type,
    required DateTime scheduledStart,
    DateTime? scheduledEnd,
  }) {
    final campaign = NotificationCampaign(
      campaignId: campaignId,
      name: name,
      description: description,
      type: type,
      notificationIds: [],
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      totalRecipients: 0,
      sentCount: 0,
      deliveredCount: 0,
      openedCount: 0,
      isActive: true,
    );

    _campaigns[campaignId] = campaign;

    return campaign;
  }

  Future<String> sendToCampaign({
    required String campaignId,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final campaign = _campaigns[campaignId];
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    final notificationId = await sendNotification(
      title: title,
      body: body,
      type: campaign.type,
      priority: priority,
      segmentId: campaignId,
      data: data,
      imageUrl: imageUrl,
      scheduledAt: campaign.scheduledStart,
    );

    final updated = NotificationCampaign(
      campaignId: campaign.campaignId,
      name: campaign.name,
      description: campaign.description,
      type: campaign.type,
      notificationIds: [...campaign.notificationIds, notificationId],
      scheduledStart: campaign.scheduledStart,
      scheduledEnd: campaign.scheduledEnd,
      totalRecipients: campaign.totalRecipients,
      sentCount: campaign.sentCount + 1,
      deliveredCount: campaign.deliveredCount,
      openedCount: campaign.openedCount,
      isActive: campaign.isActive,
    );

    _campaigns[campaignId] = updated;

    return notificationId;
  }

  List<PushNotification> getNotificationsForUser(String userId) {
    return _notifications.values
        .where((notif) =>
            notif.userId == userId ||
            notif.userIds?.contains(userId) == true)
        .toList()
      ..sort((a, b) =>
          (b.sentAt ?? b.scheduledAt ?? DateTime.now())
              .compareTo(a.sentAt ?? a.scheduledAt ?? DateTime.now()));
  }

  List<PushNotification> getPendingNotifications() {
    return _notifications.values
        .where((notif) => notif.isPending)
        .toList()
      ..sort((a, b) =>
          (a.scheduledAt ?? DateTime.now())
              .compareTo(b.scheduledAt ?? DateTime.now()));
  }

  Map<String, dynamic> getNotificationStats() {
    final total = _notifications.length;
    final sent = _notifications.values.where((n) => n.isSent).length;
    final delivered = _notifications.values.where((n) => n.isDelivered).length;
    final opened = _notifications.values.where((n) => n.status == NotificationStatus.opened).length;
    final failed = _notifications.values.where((n) => n.status == NotificationStatus.failed).length;

    return {
      'totalNotifications': total,
      'sentNotifications': sent,
      'deliveredNotifications': delivered,
      'openedNotifications': opened,
      'failedNotifications': failed,
      'deliveryRate': total > 0 ? delivered / total : 0.0,
      'openRate': delivered > 0 ? opened / delivered : 0.0,
      'activeCampaigns': _campaigns.values.where((c) => c.isActive).length,
    };
  }

  void dispose() {
    _processingTimer?.cancel();
    _eventController.close();
  }
}

class NotificationEvent {
  final NotificationEventType type;
  final String? notificationId;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const NotificationEvent({
    required this.type,
    this.notificationId,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum NotificationEventType {
  notificationCreated,
  notificationSent,
  notificationDelivered,
  notificationOpened,
  notificationFailed,
  notificationCancelled,
  preferenceUpdated,
  campaignCreated,
  campaignStarted,
  campaignEnded,
}

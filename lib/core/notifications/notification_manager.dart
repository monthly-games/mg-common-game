import 'dart:async';
import 'package:flutter/foundation.dart';

/// Notification types for games
enum NotificationType {
  /// Daily reward available
  dailyReward,

  /// Energy refilled
  energyFull,

  /// Free spin available
  freeSpin,

  /// Event starting/ending
  event,

  /// Special offer
  offer,

  /// Achievement unlocked
  achievement,

  /// Friend activity
  social,

  /// General reminder
  reminder,

  /// Custom notification
  custom,
}

/// Notification priority
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification data
class GameNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final NotificationPriority priority;
  final DateTime? scheduledTime;
  final Map<String, dynamic>? payload;
  final String? imageUrl;
  final String? actionId;

  const GameNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.priority = NotificationPriority.normal,
    this.scheduledTime,
    this.payload,
    this.imageUrl,
    this.actionId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'priority': priority.name,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'payload': payload,
        'imageUrl': imageUrl,
        'actionId': actionId,
      };

  factory GameNotification.fromJson(Map<String, dynamic> json) {
    return GameNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.custom,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      payload: json['payload'] as Map<String, dynamic>?,
      imageUrl: json['imageUrl'] as String?,
      actionId: json['actionId'] as String?,
    );
  }
}

/// Notification callback
typedef NotificationCallback = void Function(GameNotification notification);

/// Notification tap callback
typedef NotificationTapCallback = void Function(
  GameNotification notification,
  String? actionId,
);

/// Notification manager for local and push notifications
///
/// Provides a unified interface for scheduling and handling notifications.
/// Requires platform-specific implementation (flutter_local_notifications, firebase_messaging).
class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;

  NotificationManager._();

  bool _initialized = false;
  bool _permissionGranted = false;
  final List<GameNotification> _pendingNotifications = [];
  final List<GameNotification> _deliveredNotifications = [];

  NotificationCallback? _onReceived;
  NotificationTapCallback? _onTapped;

  /// Whether the manager is initialized
  bool get isInitialized => _initialized;

  /// Whether notification permission is granted
  bool get hasPermission => _permissionGranted;

  /// Pending scheduled notifications
  List<GameNotification> get pendingNotifications =>
      List.unmodifiable(_pendingNotifications);

  /// Delivered notifications
  List<GameNotification> get deliveredNotifications =>
      List.unmodifiable(_deliveredNotifications);

  /// Initialize notification manager
  ///
  /// Call this at app startup.
  Future<void> initialize({
    NotificationCallback? onReceived,
    NotificationTapCallback? onTapped,
  }) async {
    if (_initialized) return;

    _onReceived = onReceived;
    _onTapped = onTapped;

    // TODO: Initialize platform-specific notification plugins
    // await FlutterLocalNotificationsPlugin().initialize(...);
    // await FirebaseMessaging.instance.requestPermission();

    _initialized = true;
    debugPrint('NotificationManager initialized');
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (!_initialized) {
      throw StateError('NotificationManager not initialized');
    }

    // TODO: Request platform-specific permission
    // iOS: await FlutterLocalNotificationsPlugin()
    //   .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
    //   ?.requestPermissions(alert: true, badge: true, sound: true);
    // Android: Automatically granted in most cases

    _permissionGranted = true;
    notifyListeners();
    return _permissionGranted;
  }

  /// Schedule a local notification
  Future<void> scheduleNotification(GameNotification notification) async {
    if (!_initialized || !_permissionGranted) return;

    _pendingNotifications.add(notification);

    // TODO: Schedule with platform plugin
    // await FlutterLocalNotificationsPlugin().zonedSchedule(
    //   notification.id.hashCode,
    //   notification.title,
    //   notification.body,
    //   tz.TZDateTime.from(notification.scheduledTime!, tz.local),
    //   NotificationDetails(...),
    //   androidAllowWhileIdle: true,
    //   uiLocalNotificationDateInterpretation:
    //     UILocalNotificationDateInterpretation.absoluteTime,
    //   payload: jsonEncode(notification.toJson()),
    // );

    debugPrint('Scheduled notification: ${notification.id}');
    notifyListeners();
  }

  /// Show an immediate notification
  Future<void> showNotification(GameNotification notification) async {
    if (!_initialized || !_permissionGranted) return;

    // TODO: Show with platform plugin
    // await FlutterLocalNotificationsPlugin().show(
    //   notification.id.hashCode,
    //   notification.title,
    //   notification.body,
    //   NotificationDetails(...),
    //   payload: jsonEncode(notification.toJson()),
    // );

    _deliveredNotifications.add(notification);
    _onReceived?.call(notification);

    debugPrint('Showed notification: ${notification.id}');
    notifyListeners();
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String id) async {
    if (!_initialized) return;

    _pendingNotifications.removeWhere((n) => n.id == id);

    // TODO: Cancel with platform plugin
    // await FlutterLocalNotificationsPlugin().cancel(id.hashCode);

    debugPrint('Cancelled notification: $id');
    notifyListeners();
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;

    _pendingNotifications.clear();

    // TODO: Cancel all with platform plugin
    // await FlutterLocalNotificationsPlugin().cancelAll();

    debugPrint('Cancelled all notifications');
    notifyListeners();
  }

  /// Get pending notification by ID
  GameNotification? getPendingNotification(String id) {
    return _pendingNotifications.cast<GameNotification?>().firstWhere(
          (n) => n?.id == id,
          orElse: () => null,
        );
  }

  /// Check if notification is scheduled
  bool isScheduled(String id) {
    return _pendingNotifications.any((n) => n.id == id);
  }

  /// Handle notification tap (called from platform code)
  void handleNotificationTap(
    GameNotification notification,
    String? actionId,
  ) {
    _onTapped?.call(notification, actionId);
  }

  /// Clear delivered notifications
  void clearDeliveredNotifications() {
    _deliveredNotifications.clear();
    notifyListeners();
  }

  // ============================================================
  // Common Notification Templates
  // ============================================================

  /// Schedule daily reward notification
  Future<void> scheduleDailyRewardNotification({
    required DateTime time,
    String title = 'Daily Reward Ready!',
    String body = 'Your daily reward is waiting for you!',
  }) async {
    await scheduleNotification(GameNotification(
      id: 'daily_reward',
      type: NotificationType.dailyReward,
      title: title,
      body: body,
      priority: NotificationPriority.high,
      scheduledTime: time,
    ));
  }

  /// Schedule energy full notification
  Future<void> scheduleEnergyFullNotification({
    required DateTime time,
    String title = 'Energy Refilled!',
    String body = 'Your energy is full. Time to play!',
  }) async {
    await scheduleNotification(GameNotification(
      id: 'energy_full',
      type: NotificationType.energyFull,
      title: title,
      body: body,
      priority: NotificationPriority.normal,
      scheduledTime: time,
    ));
  }

  /// Schedule free spin notification
  Future<void> scheduleFreeSpinNotification({
    required DateTime time,
    String title = 'Free Spin Available!',
    String body = 'Spin the wheel for free rewards!',
  }) async {
    await scheduleNotification(GameNotification(
      id: 'free_spin',
      type: NotificationType.freeSpin,
      title: title,
      body: body,
      priority: NotificationPriority.normal,
      scheduledTime: time,
    ));
  }

  /// Schedule event notification
  Future<void> scheduleEventNotification({
    required String eventId,
    required DateTime time,
    required String title,
    required String body,
    bool isEnding = false,
  }) async {
    await scheduleNotification(GameNotification(
      id: 'event_${eventId}_${isEnding ? 'end' : 'start'}',
      type: NotificationType.event,
      title: title,
      body: body,
      priority: NotificationPriority.high,
      scheduledTime: time,
      payload: {'eventId': eventId, 'isEnding': isEnding},
    ));
  }

  /// Schedule comeback notification
  Future<void> scheduleComebackNotification({
    Duration afterInactivity = const Duration(days: 1),
    String title = 'We miss you!',
    String body = 'Come back and claim your welcome reward!',
  }) async {
    await scheduleNotification(GameNotification(
      id: 'comeback',
      type: NotificationType.reminder,
      title: title,
      body: body,
      priority: NotificationPriority.normal,
      scheduledTime: DateTime.now().add(afterInactivity),
    ));
  }

  @override
  void dispose() {
    _pendingNotifications.clear();
    _deliveredNotifications.clear();
    super.dispose();
  }
}

/// Common notification time calculations
class NotificationScheduler {
  /// Get next occurrence of a time today or tomorrow
  static DateTime nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Get time after energy refill
  static DateTime energyRefillTime(
    int currentEnergy,
    int maxEnergy,
    Duration regenInterval,
  ) {
    if (currentEnergy >= maxEnergy) {
      return DateTime.now();
    }

    final energyNeeded = maxEnergy - currentEnergy;
    final regenTime = regenInterval * energyNeeded;
    return DateTime.now().add(regenTime);
  }

  /// Get next daily reset time
  static DateTime nextDailyReset({int resetHour = 0}) {
    return nextOccurrence(resetHour, 0);
  }

  /// Get next weekly reset time
  static DateTime nextWeeklyReset({
    int dayOfWeek = DateTime.monday,
    int resetHour = 0,
  }) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, resetHour);

    final daysUntilTarget = (dayOfWeek - now.weekday + 7) % 7;
    scheduled = scheduled.add(Duration(days: daysUntilTarget));

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}

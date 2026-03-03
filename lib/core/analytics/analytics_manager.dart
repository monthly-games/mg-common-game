import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그 레벨
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf,
}

/// 애널리틱스 이벤트 타입
enum AnalyticsEventType {
  app_open,
  session_start,
  session_end,
  game_start,
  game_complete,
  quest_completed,
  purchase_completed,
  custom,
}

/// 세션 데이터
class SessionData {
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  int durationSeconds;
  final String gameId;

  SessionData({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    required this.gameId,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'gameId': gameId,
      };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
        sessionId: json['sessionId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
        durationSeconds: json['durationSeconds'] as int,
        gameId: json['gameId'] as String,
      );
}

/// 애널리틱스 관리자
class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._();
  static AnalyticsManager get instance => _instance;

  AnalyticsManager._();

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  String? _userId;
  String? _currentSessionId;

  final List<dynamic> _eventBuffer = [];
  Timer? _sessionTimer;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _userId = userId ?? _prefs!.getString('analytics_user_id');

    if (_userId == null) {
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await _prefs!.setString('analytics_user_id', _userId!);
    }

    _isInitialized = true;
    await startSession();
  }

  Future<void> startSession({String? gameId}) async {
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _sessionTimer?.cancel();

    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // 세션 갱신 로직
    });
  }

  Future<void> endSession() async {
    _sessionTimer?.cancel();
    _currentSessionId = null;
  }

  Future<void> logEvent(String name, {Map<String, dynamic> parameters = const {}}) async {
    if (!_isInitialized) return;

    final event = {
      'name': name,
      'parameters': parameters,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _userId,
      'session_id': _currentSessionId,
    };

    _eventBuffer.add(event);
    if (_eventBuffer.length > 500) _eventBuffer.removeAt(0);

    if (kDebugMode) {
      debugPrint('[Analytics] $name: $parameters');
    }
  }

  void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  void dispose() {
    _sessionTimer?.cancel();
  }
}

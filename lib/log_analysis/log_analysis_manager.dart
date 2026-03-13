import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그 레벨
enum LogLevel {
  debug,          // 디버그
  info,           // 정보
  warning,        // 경고
  error,          // 에러
  fatal,          // 치명적
}

/// 로그 카테고리
enum LogCategory {
  gameplay,       // 게임플레이
  system,         // 시스템
  network,        // 네트워크
  security,       // 보안
  performance,    // 성능
  business,       // 비즈니스
  user,           // 유저
}

/// 로그 엔트리
class LogEntry {
  final String id;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final Map<String, dynamic>? data;
  final String? userId;
  final String? sessionId;
  final DateTime timestamp;
  final String? source; // 소스 파일/함수
  final int? lineNumber;

  const LogEntry({
    required this.id,
    required this.level,
    required this.category,
    required this.message,
    this.data,
    this.userId,
    this.sessionId,
    required this.timestamp,
    this.source,
    this.lineNumber,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.name,
      'category': category.name,
      'message': message,
      'data': data,
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'lineNumber': lineNumber,
    };
  }
}

/// 로그 통계
class LogStatistics {
  final int totalLogs;
  final Map<LogLevel, int> levelDistribution;
  final Map<LogCategory, int> categoryDistribution;
  final int errorCount;
  final int warningCount;
  final DateTime? oldestLog;
  final DateTime? newestLog;
  final List<String> topErrors;

  const LogStatistics({
    required this.totalLogs,
    required this.levelDistribution,
    required this.categoryDistribution,
    required this.errorCount,
    required this.warningCount,
    this.oldestLog,
    this.newestLog,
    required this.topErrors,
  });

  /// 에러율
  double get errorRate => totalLogs > 0 ? errorCount / totalLogs : 0.0;
}

/// 로그 필터
class LogFilter {
  final LogLevel? minLevel;
  final List<LogCategory>? categories;
  final String? keyword;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? userId;
  final String? sessionId;

  const LogFilter({
    this.minLevel,
    this.categories,
    this.keyword,
    this.startTime,
    this.endTime,
    this.userId,
    this.sessionId,
  });

  /// 필터 적용
  bool matches(LogEntry entry) {
    if (minLevel != null && entry.level.index < minLevel!.index) {
      return false;
    }

    if (categories != null && !categories!.contains(entry.category)) {
      return false;
    }

    if (keyword != null && !entry.message.contains(keyword!)) {
      return false;
    }

    if (startTime != null && entry.timestamp.isBefore(startTime!)) {
      return false;
    }

    if (endTime != null && entry.timestamp.isAfter(endTime!)) {
      return false;
    }

    if (userId != null && entry.userId != userId) {
      return false;
    }

    if (sessionId != null && entry.sessionId != sessionId) {
      return false;
    }

    return true;
  }
}

/// 로그 리포트
class LogReport {
  final String id;
  final String name;
  final String description;
  final LogFilter filter;
  final DateTime generatedAt;
  final LogStatistics statistics;
  final List<LogEntry> sampleLogs;

  const LogReport({
    required this.id,
    required this.name,
    required this.description,
    required this.filter,
    required this.generatedAt,
    required this.statistics,
    required this.sampleLogs,
  });
}

/// 로그 분석 관리자
class LogAnalysisManager {
  static final LogAnalysisManager _instance = LogAnalysisManager._();
  static LogAnalysisManager get instance => _instance;

  LogAnalysisManager._();

  SharedPreferences? _prefs;

  final List<LogEntry> _logs = [];
  final Map<String, List<LogEntry>> _userLogs = {};
  final Map<String, List<LogEntry>> _sessionLogs = {};

  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();
  final StreamController<LogStatistics> _statisticsController =
      StreamController<LogStatistics>.broadcast();

  Stream<LogEntry> get onLog => _logController.stream;
  Stream<LogStatistics> get onStatisticsUpdate => _statisticsController.stream;

  Timer? _analysisTimer;
  int _logCounter = 0;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 로드된 로그 로드
    await _loadLogs();

    // 주기적 분석 시작
    _startPeriodicAnalysis();

    debugPrint('[LogAnalysis] Initialized');
  }

  Future<void> _loadLogs() async {
    final logsJson = _prefs?.getString('logs');
    if (logsJson != null) {
      // 실제로는 파싱
    }
  }

  void _startPeriodicAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _analyzeLogs();
    });
  }

  /// 로그 기록
  Future<void> log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    Map<String, dynamic>? data,
    String? userId,
    String? sessionId,
    String? source,
    int? lineNumber,
  }) async {
    final entry = LogEntry(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}_$_logCounter',
      level: level,
      category: category,
      message: message,
      data: data,
      userId: userId,
      sessionId: sessionId,
      timestamp: DateTime.now(),
      source: source,
      lineNumber: lineNumber,
    );

    _logs.add(entry);
    _logController.add(entry);

    if (userId != null) {
      _userLogs.putIfAbsent(userId!, () => []).add(entry);
    }

    if (sessionId != null) {
      _sessionLogs.putIfAbsent(sessionId!, () => []).add(entry);
    }

    _logCounter++;

    // 에러/치명적 로그는 즉시 알림
    if (level == LogLevel.error || level == LogLevel.fatal) {
      _handleCriticalLog(entry);
    }

    // 최대 100,000개만 유지
    if (_logs.length > 100000) {
      _logs.removeRange(0, _logs.length - 100000);
    }
  }

  /// 치명적 로그 처리
  void _handleCriticalLog(LogEntry entry) {
    debugPrint('[LogAnalysis] Critical log: ${entry.level.name} - ${entry.message}');

    // 실제 환경에서는 알림 발송
  }

  /// 로그 분석
  void _analyzeLogs() {
    final stats = calculateStatistics();
    _statisticsController.add(stats);

    debugPrint('[LogAnalysis] Logs analyzed: ${stats.totalLogs} total, ${stats.errorCount} errors');
  }

  /// 로그 검색
  List<LogEntry> searchLogs(LogFilter filter) {
    return _logs.where((log) => filter.matches(log)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 통계 계산
  LogStatistics calculateStatistics({LogFilter? filter}) {
    var filteredLogs = _logs.toList();

    if (filter != null) {
      filteredLogs = filteredLogs.where((log) => filter.matches(log)).toList();
    }

    if (filteredLogs.isEmpty) {
      return const LogStatistics(
        totalLogs: 0,
        levelDistribution: {},
        categoryDistribution: {},
        errorCount: 0,
        warningCount: 0,
        topErrors: [],
      );
    }

    // 레벨 분포
    final levelDistribution = <LogLevel, int>{};
    for (final level in LogLevel.values) {
      levelDistribution[level] = filteredLogs.where((l) => l.level == level).length;
    }

    // 카테고리 분포
    final categoryDistribution = <LogCategory, int>{};
    for (final category in LogCategory.values) {
      categoryDistribution[category] = filteredLogs.where((l) => l.category == category).length;
    }

    // 에러/경고 카운트
    final errorCount = filteredLogs.where((l) =>
        l.level == LogLevel.error || l.level == LogLevel.fatal).length;
    final warningCount = filteredLogs.where((l) => l.level == LogLevel.warning).length;

    // 시간 범위
    final sorted = filteredLogs..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final oldestLog = sorted.isNotEmpty ? sorted.first.timestamp : null;
    final newestLog = sorted.isNotEmpty ? sorted.last.timestamp : null;

    // 상위 에러
    final errorLogs = filteredLogs.where((l) =>
        l.level == LogLevel.error || l.level == LogLevel.fatal).toList();
    final errorMessages = <String, int>{};
    for (final log in errorLogs) {
      errorMessages[log.message] = (errorMessages[log.message] ?? 0) + 1;
    }
    final topErrors = errorMessages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topErrorMessages = topErrors.take(10).map((e) => e.key).toList();

    return LogStatistics(
      totalLogs: filteredLogs.length,
      levelDistribution: levelDistribution,
      categoryDistribution: categoryDistribution,
      errorCount: errorCount,
      warningCount: warningCount,
      oldestLog: oldestLog,
      newestLog: newestLog,
      topErrors: topErrorMessages,
    );
  }

  /// 리포트 생성
  Future<LogReport> generateReport({
    required String name,
    required String description,
    required LogFilter filter,
  }) async {
    final filteredLogs = searchLogs(filter);
    final statistics = LogStatistics(
      totalLogs: filteredLogs.length,
      levelDistribution: {},
      categoryDistribution: {},
      errorCount: filteredLogs.where((l) =>
          l.level == LogLevel.error || l.level == LogLevel.fatal).length,
      warningCount: filteredLogs.where((l) => l.level == LogLevel.warning).length,
      topErrors: [],
    );

    final sampleLogs = filteredLogs.take(100).toList();

    final report = LogReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      filter: filter,
      generatedAt: DateTime.now(),
      statistics: statistics,
      sampleLogs: sampleLogs,
    );

    await _saveReport(report);

    debugPrint('[LogAnalysis] Report generated: $name');

    return report;
  }

  /// 유저 로그 조회
  List<LogEntry> getUserLogs(String userId, {LogLevel? minLevel}) {
    var logs = _userLogs[userId] ?? [];

    if (minLevel != null) {
      logs = logs.where((l) => l.level.index >= minLevel!.index).toList();
    }

    return logs..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 세션 로그 조회
  List<LogEntry> getSessionLogs(String sessionId, {LogLevel? minLevel}) {
    var logs = _sessionLogs[sessionId] ?? [];

    if (minLevel != null) {
      logs = logs.where((l) => l.level.index >= minLevel!.index).toList();
    }

    return logs..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 로그 내보기
  Future<String> exportLogs({
    LogFilter? filter,
    String format = 'json', // json, csv
  }) async {
    final logs = filter != null ? searchLogs(filter) : _logs;

    switch (format) {
      case 'json':
        final json = jsonEncode(logs.map((l) => l.toJson()).toList());
        return json;

      case 'csv':
        final csv = StringBuffer();
        csv.writeln('timestamp,level,category,message,userId,sessionId');
        for (final log in logs) {
          csv.writeln(
            '${log.timestamp.toIso8601String()},'
            '${log.level.name},'
            '${log.category.name},'
            '"${log.message}",'
            '${log.userId ?? ""},'
            '${log.sessionId ?? ""}'
          );
        }
        return csv.toString();

      default:
        throw Exception('Unsupported format: $format');
    }
  }

  /// 로그 정리
  Future<void> cleanupLogs({
    Duration? olderThan,
    int? keepCount,
  }) async {
    var count = _logs.length;

    if (olderThan != null) {
      final cutoff = DateTime.now().subtract(olderThan);
      _logs.removeWhere((log) => log.timestamp.isBefore(cutoff));
      for (final userLogs in _userLogs.values) {
        userLogs.removeWhere((log) => log.timestamp.isBefore(cutoff));
      }
      for (final sessionLogs in _sessionLogs.values) {
        sessionLogs.removeWhere((log) => log.timestamp.isBefore(cutoff));
      }
    }

    if (keepCount != null && _logs.length > keepCount) {
      final removeCount = _logs.length - keepCount;
      _logs.removeRange(0, removeCount);
    }

    final removed = count - _logs.length;

    debugPrint('[LogAnalysis] Cleaned up $removed logs');
  }

  /// 로그 레벨별 색상
  Color getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }

  /// 카테고리별 아이콘
  String getCategoryIcon(LogCategory category) {
    switch (category) {
      case LogCategory.gameplay:
        return '🎮';
      case LogCategory.system:
        return '⚙️';
      case LogCategory.network:
        return '🌐';
      case LogCategory.security:
        return '🔒';
      case LogCategory.performance:
        return '📊';
      case LogCategory.business:
        return '💰';
      case LogCategory.user:
        return '👤';
    }
  }

  Future<void> _saveReport(LogReport report) async {
    await _prefs?.setString(
      'log_report_${report.id}',
      jsonEncode({
        'id': report.id,
        'name': report.name,
        'generatedAt': report.generatedAt.toIso8601String(),
        'totalLogs': report.statistics.totalLogs,
      }),
    );
  }

  void dispose() {
    _logController.close();
    _statisticsController.close();
    _analysisTimer?.cancel();
  }
}

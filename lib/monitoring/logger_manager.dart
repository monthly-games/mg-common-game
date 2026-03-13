import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

enum LogCategory {
  network,
  ui,
  game,
  system,
  performance,
  security,
  analytics,
  custom,
}

class LogEntry {
  final String logId;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;
  final String? tag;

  const LogEntry({
    required this.logId,
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.metadata,
    this.stackTrace,
    this.tag,
  });

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'level': level.name,
      'category': category.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
      'metadata': metadata,
      'stackTrace': stackTrace,
      'tag': tag,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}]');
    buffer.write('[${level.name.toUpperCase()}]');
    if (tag != null) buffer.write('[$tag]');
    buffer.write(' $message');
    return buffer.toString();
  }
}

class LogFilter {
  final LogLevel? minLevel;
  final LogLevel? maxLevel;
  final List<LogCategory>? categories;
  final String? tag;
  final String? userId;
  final DateTime? startTime;
  final DateTime? endTime;

  const LogFilter({
    this.minLevel,
    this.maxLevel,
    this.categories,
    this.tag,
    this.userId,
    this.startTime,
    this.endTime,
  });

  bool matches(LogEntry entry) {
    if (minLevel != null && entry.level.index < minLevel!.index) return false;
    if (maxLevel != null && entry.level.index > maxLevel!.index) return false;
    if (categories != null && !categories!.contains(entry.category)) return false;
    if (tag != null && entry.tag != tag) return false;
    if (userId != null && entry.userId != userId) return false;
    if (startTime != null && entry.timestamp.isBefore(startTime!)) return false;
    if (endTime != null && entry.timestamp.isAfter(endTime!)) return false;
    return true;
  }
}

class LoggerConfig {
  final LogLevel minLevel;
  final bool enableConsole;
  final bool enableFile;
  final bool enableRemote;
  final int maxCacheSize;
  final int flushInterval;
  final List<LogLevel> consoleLevels;
  final List<LogLevel> fileLevels;

  const LoggerConfig({
    required this.minLevel,
    required this.enableConsole,
    required this.enableFile,
    required this.enableRemote,
    required this.maxCacheSize,
    required this.flushInterval,
    required this.consoleLevels,
    required this.fileLevels,
  });
}

class LogManager {
  static final LogManager _instance = LogManager._();
  static LogManager get instance => _instance;

  LogManager._();

  LoggerConfig _config = const LoggerConfig(
    minLevel: LogLevel.debug,
    enableConsole: true,
    enableFile: false,
    enableRemote: false,
    maxCacheSize: 1000,
    flushInterval: 30,
    consoleLevels: LogLevel.values,
    fileLevels: [LogLevel.warning, LogLevel.error, LogLevel.fatal],
  );

  final List<LogEntry> _logCache = [];
  final StreamController<LogEntry> _logController = StreamController.broadcast();
  Timer? _flushTimer;

  String? _currentUserId;
  String? _currentSessionId;

  Stream<LogEntry> get onLog => _logController.stream;

  Future<void> initialize(LoggerConfig config) async {
    _config = config;
    _startFlushTimer();
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      Duration(seconds: _config.flushInterval),
      (_) => _flushLogs(),
    );
  }

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  void setSessionId(String? sessionId) {
    _currentSessionId = sessionId;
  }

  void log(
    LogLevel level,
    String message, {
    LogCategory category = LogCategory.custom,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    if (level.index < _config.minLevel.index) return;

    final entry = LogEntry(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      level: level,
      category: category,
      message: message,
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _currentSessionId,
      metadata: metadata,
      stackTrace: stackTrace,
      tag: tag,
    );

    _addLog(entry);
  }

  void verbose(String message, {LogCategory category = LogCategory.custom, String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.verbose, message, category: category, tag: tag, metadata: metadata);
  }

  void debug(String message, {LogCategory category = LogCategory.custom, String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.debug, message, category: category, tag: tag, metadata: metadata);
  }

  void info(String message, {LogCategory category = LogCategory.custom, String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.info, message, category: category, tag: tag, metadata: metadata);
  }

  void warning(String message, {LogCategory category = LogCategory.custom, String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.warning, message, category: category, tag: tag, metadata: metadata);
  }

  void error(String message, {LogCategory category = LogCategory.custom, String? tag, Map<String, dynamic>? metadata, String? stackTrace}) {
    log(LogLevel.error, message, category: category, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  void fatal(String message, {LogCategory category = LogCategory.custom, String? tag, Map<String, dynamic>? metadata, String? stackTrace}) {
    log(LogLevel.fatal, message, category: category, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  void _addLog(LogEntry entry) {
    _logCache.add(entry);

    if (_config.enableConsole && _config.consoleLevels.contains(entry.level)) {
      debugPrint(entry.toString());
    }

    _logController.add(entry);

    if (_logCache.length >= _config.maxCacheSize) {
      _flushLogs();
    }
  }

  void _flushLogs() {
    if (_logCache.isEmpty) return;

    if (_config.enableFile) {
    }

    if (_config.enableRemote) {
    }

    _logCache.clear();
  }

  List<LogEntry> getLogs({LogFilter? filter}) {
    var logs = List<LogEntry>.from(_logCache);

    if (filter != null) {
      logs = logs.where(filter.matches).toList();
    }

    return logs;
  }

  List<LogEntry> getLogsByLevel(LogLevel level) {
    return getLogs(filter: LogFilter(minLevel: level, maxLevel: level));
  }

  List<LogEntry> getLogsByCategory(LogCategory category) {
    return getLogs(filter: LogFilter(categories: [category]));
  }

  List<LogEntry> getLogsByTag(String tag) {
    return getLogs(filter: LogFilter(tag: tag));
  }

  List<LogEntry> getLogsByUser(String userId) {
    return getLogs(filter: LogFilter(userId: userId));
  }

  void clearLogs() {
    _logCache.clear();
  }

  Map<String, dynamic> getLoggerStats() {
    final levelCounts = <LogLevel, int>{};
    for (final level in LogLevel.values) {
      levelCounts[level] = _logCache.where((log) => log.level == level).length;
    }

    return {
      'totalLogs': _logCache.length,
      'cacheSize': _logCache.length,
      'maxCacheSize': _config.maxCacheSize,
      'levelCounts': levelCounts.map((k, v) => MapEntry(k.name, v)),
      'currentUserId': _currentUserId,
      'currentSessionId': _currentSessionId,
    };
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushLogs();
    _logController.close();
  }
}

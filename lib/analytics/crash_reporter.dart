import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mg_common_game/storage/local_storage_service.dart';

/// Crash severity
enum CrashSeverity {
  low,
  medium,
  high,
  critical,
}

/// Crash report
class CrashReport {
  final String crashId;
  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appInfo;
  final CrashSeverity severity;
  final List<StackTraceFrame> stackFrames;
  final Map<String, dynamic>? customData;

  CrashReport({
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    DateTime? timestamp,
    this.userId,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? appInfo,
    this.severity = CrashSeverity.high,
    List<StackTraceFrame>? stackFrames,
    this.customData,
  })  : crashId = 'crash_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now(),
        deviceInfo = deviceInfo ?? {},
        appInfo = appInfo ?? {},
        stackFrames = stackFrames ?? [];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'crashId': crashId,
      'errorType': errorType,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userId': userId,
      'deviceInfo': deviceInfo,
      'appInfo': appInfo,
      'severity': severity.name,
      'stackFrames': stackFrames.map((f) => f.toJson()).toList(),
      'customData': customData,
    };
  }

  /// Create from JSON
  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      errorType: json['errorType'],
      errorMessage: json['errorMessage'],
      stackTrace: json['stackTrace'],
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
      userId: json['userId'],
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>? ?? {},
      appInfo: json['appInfo'] as Map<String, dynamic>? ?? {},
      severity: CrashSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => CrashSeverity.high,
      ),
      stackFrames: (json['stackFrames'] as List?)
          ?.map((f) => StackTraceFrame.fromJson(f))
          .toList() ?? [],
      customData: json['customData'],
    );
  }
}

/// Stack trace frame
class StackTraceFrame {
  final String? file;
  final int? line;
  final String? method;
  final String? className;

  StackTraceFrame({
    this.file,
    this.line,
    this.method,
    this.className,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'line': line,
      'method': method,
      'className': className,
    };
  }

  /// Create from JSON
  factory StackTraceFrame.fromJson(Map<String, dynamic> json) {
    return StackTraceFrame(
      file: json['file'],
      line: json['line'],
      method: json['method'],
      className: json['className'],
    );
  }

  /// Format as string
  String format() {
    final buffer = StringBuffer();
    if (className != null) buffer.write(className);
    if (method != null) {
      if (className != null) buffer.write('.');
      buffer.write(method);
    }
    buffer.write(' (');
    if (file != null) buffer.write(file);
    if (line != null) buffer.write(':$line');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Crash statistics
class CrashStatistics {
  final int totalCrashes;
  final int uniqueCrashes;
  final Map<String, int> crashesByType;
  final Map<CrashSeverity, int> crashesBySeverity;
  final DateTime startDate;
  final DateTime endDate;

  CrashStatistics({
    required this.totalCrashes,
    required this.uniqueCrashes,
    required this.crashesByType,
    required this.crashesBySeverity,
    required this.startDate,
    required this.endDate,
  });

  /// Get crash rate (crashes per hour)
  double get crashRate {
    final hours = endDate.difference(startDate).inHours;
    return hours > 0 ? totalCrashes / hours : 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalCrashes': totalCrashes,
      'uniqueCrashes': uniqueCrashes,
      'crashesByType': crashesByType,
      'crashesBySeverity': crashesBySeverity.map((k, v) => MapEntry(k.name, v)),
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
    };
  }
}

/// Crash reporter configuration
class CrashReporterConfig {
  final bool autoCapture;
  final int maxStoredCrashes;
  final bool enableReporting;
  final String? serverUrl;
  final Duration uploadInterval;

  const CrashReporterConfig({
    this.autoCapture = true,
    this.maxStoredCrashes = 50,
    this.enableReporting = true,
    this.serverUrl,
    this.uploadInterval = const Duration(minutes: 5),
  });
}

/// Crash reporter
class CrashReporter {
  static final CrashReporter _instance = CrashReporter._internal();
  static CrashReporter get instance => _instance;

  CrashReporter._internal();

  final LocalStorageService _storage = LocalStorageService.instance;

  CrashReporterConfig _config = const CrashReporterConfig();

  final List<CrashReport> _crashBuffer = [];
  final Map<String, String> _userIdentifiers = {}; // sessionId -> userId

  Timer? _uploadTimer;

  final StreamController<CrashReport> _crashController = StreamController.broadcast();

  /// Stream of crashes
  Stream<CrashReport> get crashStream => _crashController.stream;

  bool _isInitialized = false;
  String? _currentUserId;

  /// Initialize crash reporter
  Future<void> initialize({CrashReporterConfig? config}) async {
    if (_isInitialized) return;

    if (config != null) {
      _config = config;
    }

    await _storage.initialize();

    // Set up error handlers
    if (_config.autoCapture) {
      _setupErrorHandlers();
    }

    // Load buffered crashes
    await _loadBufferedCrashes();

    // Start upload timer
    if (_config.enableReporting) {
      _startUploadTimer();
    }

    _isInitialized = true;
  }

  /// Set current user
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  /// Setup global error handlers
  void _setupErrorHandlers() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(
        errorType: 'FlutterError',
        errorMessage: details.exceptionAsString(),
        stackTrace: details.stack?.toString(),
        severity: CrashSeverity.critical,
      );
    };
  }

  /// Report an error
  void reportError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    CrashSeverity severity = CrashSeverity.high,
    Map<String, dynamic>? customData,
  }) {
    final report = CrashReport(
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      userId: _currentUserId,
      deviceInfo: _collectDeviceInfo(),
      appInfo: _collectAppInfo(),
      severity: severity,
      stackFrames: _parseStackTrace(stackTrace),
      customData: customData,
    );

    _addCrashReport(report);
  }

  /// Report exception
  void reportException(
    dynamic exception, [
    StackTrace? stackTrace,
    CrashSeverity severity = CrashSeverity.high,
  ]) {
    reportError(
      errorType: exception.runtimeType.toString(),
      errorMessage: exception.toString(),
      stackTrace: stackTrace?.toString(),
      severity: severity,
    );
  }

  /// Add crash report to buffer
  void _addCrashReport(CrashReport report) {
    _crashBuffer.add(report);
    _crashController.add(report);

    // Enforce max buffer size
    if (_crashBuffer.length > _config.maxStoredCrashes) {
      _crashBuffer.removeAt(0);
    }

    // Save to storage
    _saveCrashReports();
  }

  /// Collect device information
  Map<String, dynamic> _collectDeviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'numberOfProcessors': Platform.numberOfProcessors,
      'pathSeparator': Platform.pathSeparator,
    };
  }

  /// Collect app information
  Map<String, dynamic> _collectAppInfo() {
    return {
      'appName': 'MG Game',
      'version': '1.0.0',
      'buildNumber': '1',
    };
  }

  /// Parse stack trace into frames
  List<StackTraceFrame> _parseStackTrace(String? stackTrace) {
    if (stackTrace == null) return [];

    final frames = <StackTraceFrame>[];
    final lines = stackTrace.split('\n');

    for (final line in lines) {
      // Parse stack frame
      // Format: #0 MethodName (file:line:line)
      final match = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+)\)').firstMatch(line);
      if (match != null) {
        frames.add(StackTraceFrame(
          method: match.group(1),
          file: match.group(2),
          line: int.tryParse(match.group(3) ?? ''),
        ));
      }
    }

    return frames;
  }

  /// Load buffered crashes from storage
  Future<void> _loadBufferedCrashes() async {
    final crashesJson = _storage.getJsonList('crash_reports');
    if (crashesJson != null) {
      for (final json in crashesJson) {
        if (json is Map<String, dynamic>) {
          final report = CrashReport.fromJson(json);
          _crashBuffer.add(report);
        }
      }
    }
  }

  /// Save crash reports to storage
  Future<void> _saveCrashReports() async {
    final jsonList = _crashBuffer.map((c) => c.toJson()).toList();
    await _storage.setJsonList('crash_reports', jsonList);
  }

  /// Start upload timer
  void _startUploadTimer() {
    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(_config.uploadInterval, (_) {
      uploadCrashes();
    });
  }

  /// Upload crashes to server
  Future<void> uploadCrashes() async {
    if (_crashBuffer.isEmpty || !_config.enableReporting) return;
    if (_config.serverUrl == null) return;

    // Here you would send crashes to your server
    // For now, we'll just mark them as synced
    await _storage.remove('crash_reports');
  }

  /// Get all crash reports
  List<CrashReport> getAllCrashes() {
    return List.from(_crashBuffer);
  }

  /// Get crashes by user
  List<CrashReport> getCrashesByUser(String userId) {
    return _crashBuffer.where((c) => c.userId == userId).toList();
  }

  /// Get crashes by severity
  List<CrashReport> getCrashesBySeverity(CrashSeverity severity) {
    return _crashBuffer.where((c) => c.severity == severity).toList();
  }

  /// Get crashes by type
  List<CrashReport> getCrashesByType(String errorType) {
    return _crashBuffer.where((c) => c.errorType == errorType).toList();
  }

  /// Get crash statistics
  CrashStatistics getStatistics({Duration? period}) {
    final now = DateTime.now();
    final startDate = period != null ? now.subtract(period) : DateTime.now().subtract(const Duration(days: 30));

    final crashes = _crashBuffer.where((c) => c.timestamp.isAfter(startDate)).toList();

    final crashesByType = <String, int>{};
    final crashesBySeverity = <CrashSeverity, int>{};
    final uniqueTypes = <String>{};

    for (final crash in crashes) {
      crashesByType[crash.errorType] = (crashesByType[crash.errorType] ?? 0) + 1;
      crashesBySeverity[crash.severity] = (crashesBySeverity[crash.severity] ?? 0) + 1;
      uniqueTypes.add(crash.errorType);
    }

    return CrashStatistics(
      totalCrashes: crashes.length,
      uniqueCrashes: uniqueTypes.length,
      crashesByType: crashesByType,
      crashesBySeverity: crashesBySeverity,
      startDate: startDate,
      endDate: now,
    );
  }

  /// Get most frequent crashes
  List<MapEntry<String, int>> getTopCrashes({int limit = 10}) {
    final crashesByType = <String, int>{};

    for (final crash in _crashBuffer) {
      crashesByType[crash.errorType] = (crashesByType[crash.errorType] ?? 0) + 1;
    }

    final entries = crashesByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(limit).toList();
  }

  /// Clear all crash reports
  Future<void> clearCrashes() async {
    _crashBuffer.clear();
    await _storage.remove('crash_reports');
  }

  /// Get recent crashes
  List<CrashReport> getRecentCrashes({int limit = 10}) {
    final sorted = List<CrashReport>.from(_crashBuffer)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// User-friendly error message
  String getUserFriendlyMessage(CrashReport report) {
    switch (report.errorType) {
      case 'NetworkException':
      case 'HttpException':
        return 'Network error. Please check your connection.';
      case 'FileSystemException':
        return 'Storage error. Please check your available space.';
      case 'FormatException':
        return 'Data format error. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if similar crash exists
  bool hasSimilarCrash(CrashReport report) {
    return _crashBuffer.any((c) =>
      c.errorType == report.errorType &&
      c.errorMessage == report.errorMessage);
  }

  /// Get crash group (similar crashes)
  List<CrashReport> getCrashGroup(CrashReport report) {
    return _crashBuffer.where((c) =>
      c.errorType == report.errorType &&
      c.errorMessage == report.errorMessage).toList();
  }

  /// Generate summary report
  Map<String, dynamic> generateSummaryReport() {
    final stats = getStatistics();
    final topCrashes = getTopCrashes(limit: 5);

    return {
      'summary': stats.toJson(),
      'topCrashes': topCrashes.map((e) => {
        'errorType': e.key,
        'count': e.value,
      }).toList(),
      'recentCrashes': getRecentCrashes(limit=10).map((c) => c.toJson()).toList(),
    };
  }

  /// Set custom data for next crash
  void setCustomData(Map<String, dynamic> data) {
    // This would be used to attach context to crashes
    // Implementation depends on your needs
  }

  /// Enable/disable auto-capture
  void setAutoCapture(bool enabled) {
    _config = CrashReporterConfig(
      autoCapture: enabled,
      maxStoredCrashes: _config.maxStoredCrashes,
      enableReporting: _config.enableReporting,
      serverUrl: _config.serverUrl,
      uploadInterval: _config.uploadInterval,
    );

    if (enabled) {
      _setupErrorHandlers();
    }
  }

  /// Test crash reporter
  void test() {
    reportError(
      errorType: 'TestError',
      errorMessage: 'This is a test crash',
      severity: CrashSeverity.low,
    );
  }

  /// Dispose of resources
  void dispose() {
    _uploadTimer?.cancel();
    _crashController.close();
  }
}

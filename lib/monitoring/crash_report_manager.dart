import 'dart:async';
import 'package:flutter/material.dart';

enum CrashSeverity {
  low,
  medium,
  high,
  critical,
}

enum CrashType {
  runtimeError,
  nullPointer,
  networkError,
  outOfMemory,
  stackOverflow,
  assertionFailed,
  stateError,
  typeError,
  unknown,
}

enum CrashStatus {
  pending,
  submitted,
  processing,
  resolved,
  ignored,
}

class CrashReport {
  final String reportId;
  final CrashType type;
  final CrashSeverity severity;
  final String error;
  final String? stackTrace;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final String? deviceId;
  final String? appVersion;
  final String? osVersion;
  final String? deviceModel;
  final Map<String, dynamic>? metadata;
  final CrashStatus status;
  final List<CrashAttachment> attachments;
  final int occurrenceCount;
  final DateTime? firstOccurrence;
  final DateTime? lastOccurrence;

  const CrashReport({
    required this.reportId,
    required this.type,
    required this.severity,
    required this.error,
    this.stackTrace,
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.deviceId,
    this.appVersion,
    this.osVersion,
    this.deviceModel,
    this.metadata,
    required this.status,
    required this.attachments,
    required this.occurrenceCount,
    this.firstOccurrence,
    this.lastOccurrence,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'type': type.name,
      'severity': severity.name,
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
      'deviceId': deviceId,
      'appVersion': appVersion,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'metadata': metadata,
      'status': status.name,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'occurrenceCount': occurrenceCount,
      'firstOccurrence': firstOccurrence?.toIso8601String(),
      'lastOccurrence': lastOccurrence?.toIso8601String(),
    };
  }
}

class CrashAttachment {
  final String attachmentId;
  final String name;
  final String type;
  final int size;
  final String url;

  const CrashAttachment({
    required this.attachmentId,
    required this.name,
    required this.type,
    required this.size,
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'attachmentId': attachmentId,
      'name': name,
      'type': type,
      'size': size,
      'url': url,
    };
  }
}

class CrashGroup {
  final String groupId;
  final String title;
  final CrashType type;
  final CrashSeverity severity;
  final int totalOccurrences;
  final int affectedUsers;
  final DateTime firstOccurrence;
  final DateTime lastOccurrence;
  final CrashStatus status;
  final List<CrashReport> reports;

  const CrashGroup({
    required this.groupId,
    required this.title,
    required this.type,
    required this.severity,
    required this.totalOccurrences,
    required this.affectedUsers,
    required this.firstOccurrence,
    required this.lastOccurrence,
    required this.status,
    required this.reports,
  });
}

class CrashReportManager {
  static final CrashReportManager _instance = CrashReportManager._();
  static CrashReportManager get instance => _instance;

  CrashReportManager._();

  final List<CrashReport> _crashReports = [];
  final Map<String, CrashGroup> _crashGroups = {};
  final StreamController<CrashEvent> _eventController = StreamController.broadcast();

  String? _currentUserId;
  String? _currentSessionId;
  String? _deviceId;
  String? _appVersion;
  String? _osVersion;
  String? _deviceModel;

  Stream<CrashEvent> get onCrashEvent => _eventController.stream;

  Future<void> initialize({
    String? deviceId,
    String? appVersion,
    String? osVersion,
    String? deviceModel,
  }) async {
    _deviceId = deviceId;
    _appVersion = appVersion;
    _osVersion = osVersion;
    _deviceModel = deviceModel;
  }

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  void setSessionId(String? sessionId) {
    _currentSessionId = sessionId;
  }

  Future<String> reportCrash({
    required String error,
    required CrashType type,
    CrashSeverity severity = CrashSeverity.medium,
    String? stackTrace,
    Map<String, dynamic>? metadata,
    List<CrashAttachment>? attachments,
  }) async {
    final reportId = 'crash_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final report = CrashReport(
      reportId: reportId,
      type: type,
      severity: severity,
      error: error,
      stackTrace: stackTrace,
      timestamp: now,
      userId: _currentUserId,
      sessionId: _currentSessionId,
      deviceId: _deviceId,
      appVersion: _appVersion,
      osVersion: _osVersion,
      deviceModel: _deviceModel,
      metadata: metadata,
      status: CrashStatus.pending,
      attachments: attachments ?? [],
      occurrenceCount: 1,
      firstOccurrence: now,
      lastOccurrence: now,
    );

    _crashReports.insert(0, report);
    _updateCrashGroup(report);

    _eventController.add(CrashEvent(
      type: CrashEventType.crashReported,
      reportId: reportId,
      timestamp: now,
      data: {'severity': severity.name, 'type': type.name},
    ));

    return reportId;
  }

  void _updateCrashGroup(CrashReport report) {
    final groupId = _generateGroupId(report);

    final existingGroup = _crashGroups[groupId];
    if (existingGroup != null) {
      final updatedReports = List<CrashReport>.from(existingGroup.reports);
      updatedReports.insert(0, report);

      final affectedUsers = <String>{};
      for (final r in updatedReports) {
        if (r.userId != null) affectedUsers.add(r.userId!);
      }

      _crashGroups[groupId] = CrashGroup(
        groupId: existingGroup.groupId,
        title: existingGroup.title,
        type: existingGroup.type,
        severity: report.severity.index > existingGroup.severity.index
            ? report.severity
            : existingGroup.severity,
        totalOccurrences: existingGroup.totalOccurrences + report.occurrenceCount,
        affectedUsers: affectedUsers.length,
        firstOccurrence: existingGroup.firstOccurrence,
        lastOccurrence: report.lastOccurrence!,
        status: existingGroup.status,
        reports: updatedReports,
      );
    } else {
      _crashGroups[groupId] = CrashGroup(
        groupId: groupId,
        title: _generateGroupTitle(report),
        type: report.type,
        severity: report.severity,
        totalOccurrences: report.occurrenceCount,
        affectedUsers: report.userId != null ? 1 : 0,
        firstOccurrence: report.firstOccurrence!,
        lastOccurrence: report.lastOccurrence!,
        status: report.status,
        reports: [report],
      );
    }
  }

  String _generateGroupId(CrashReport report) {
    final buffer = StringBuffer();
    buffer.write(report.type.name);
    buffer.write('_');
    buffer.write(report.error.split('\n').first.substring(0, 50));
    return buffer.toString().hashCode.toString();
  }

  String _generateGroupTitle(CrashReport report) {
    return '${report.type.name}: ${report.error.split('\n').first}';
  }

  List<CrashReport> getAllCrashReports({int limit = 100}) {
    if (_crashReports.length > limit) {
      return _crashReports.sublist(0, limit);
    }
    return List<CrashReport>.from(_crashReports);
  }

  List<CrashReport> getCrashReportsByType(CrashType type) {
    return _crashReports.where((report) => report.type == type).toList();
  }

  List<CrashReport> getCrashReportsBySeverity(CrashSeverity severity) {
    return _crashReports.where((report) => report.severity == severity).toList();
  }

  List<CrashReport> getCrashReportsByUser(String userId) {
    return _crashReports.where((report) => report.userId == userId).toList();
  }

  CrashReport? getCrashReport(String reportId) {
    try {
      return _crashReports.firstWhere((report) => report.reportId == reportId);
    } catch (e) {
      return null;
    }
  }

  List<CrashGroup> getAllCrashGroups() {
    return _crashGroups.values.toList()
      ..sort((a, b) => b.lastOccurrence.compareTo(a.lastOccurrence));
  }

  List<CrashGroup> getCrashGroupsBySeverity(CrashSeverity severity) {
    return _crashGroups.values
        .where((group) => group.severity == severity)
        .toList()
      ..sort((a, b) => b.lastOccurrence.compareTo(a.lastOccurrence));
  }

  Future<bool> submitCrashReport(String reportId) async {
    final reportIndex = _crashReports.indexWhere((r) => r.reportId == reportId);
    if (reportIndex < 0) return false;

    final report = _crashReports[reportIndex];
    final updated = CrashReport(
      reportId: report.reportId,
      type: report.type,
      severity: report.severity,
      error: report.error,
      stackTrace: report.stackTrace,
      timestamp: report.timestamp,
      userId: report.userId,
      sessionId: report.sessionId,
      deviceId: report.deviceId,
      appVersion: report.appVersion,
      osVersion: report.osVersion,
      deviceModel: report.deviceModel,
      metadata: report.metadata,
      status: CrashStatus.submitted,
      attachments: report.attachments,
      occurrenceCount: report.occurrenceCount,
      firstOccurrence: report.firstOccurrence,
      lastOccurrence: report.lastOccurrence,
    );

    _crashReports[reportIndex] = updated;

    _eventController.add(CrashEvent(
      type: CrashEventType.reportSubmitted,
      reportId: reportId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> markAsResolved(String reportId) async {
    final reportIndex = _crashReports.indexWhere((r) => r.reportId == reportId);
    if (reportIndex < 0) return false;

    final report = _crashReports[reportIndex];
    final updated = CrashReport(
      reportId: report.reportId,
      type: report.type,
      severity: report.severity,
      error: report.error,
      stackTrace: report.stackTrace,
      timestamp: report.timestamp,
      userId: report.userId,
      sessionId: report.sessionId,
      deviceId: report.deviceId,
      appVersion: report.appVersion,
      osVersion: report.osVersion,
      deviceModel: report.deviceModel,
      metadata: report.metadata,
      status: CrashStatus.resolved,
      attachments: report.attachments,
      occurrenceCount: report.occurrenceCount,
      firstOccurrence: report.firstOccurrence,
      lastOccurrence: report.lastOccurrence,
    );

    _crashReports[reportIndex] = updated;

    _eventController.add(CrashEvent(
      type: CrashEventType.reportResolved,
      reportId: reportId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Map<String, dynamic> getCrashStats() {
    final typeCounts = <CrashType, int>{};
    final severityCounts = <CrashSeverity, int>{};

    for (final type in CrashType.values) {
      typeCounts[type] = _crashReports.where((r) => r.type == type).length;
    }

    for (final severity in CrashSeverity.values) {
      severityCounts[severity] = _crashReports.where((r) => r.severity == severity).length;
    }

    return {
      'totalCrashes': _crashReports.length,
      'totalGroups': _crashGroups.length,
      'crashesByType': typeCounts.map((k, v) => MapEntry(k.name, v)),
      'crashesBySeverity': severityCounts.map((k, v) => MapEntry(k.name, v)),
      'pendingReports': _crashReports.where((r) => r.status == CrashStatus.pending).length,
      'resolvedReports': _crashReports.where((r) => r.status == CrashStatus.resolved).length,
    };
  }

  void clearOldReports({Duration? maxAge}) {
    if (maxAge == null) return;

    final cutoff = DateTime.now().subtract(maxAge);
    _crashReports.removeWhere((report) => report.timestamp.isBefore(cutoff));
  }

  void dispose() {
    _eventController.close();
  }
}

class CrashEvent {
  final CrashEventType type;
  final String? reportId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const CrashEvent({
    required this.type,
    this.reportId,
    required this.timestamp,
    this.data,
  });
}

enum CrashEventType {
  crashReported,
  reportSubmitted,
  reportProcessed,
  reportResolved,
  reportIgnored,
  groupCreated,
  groupUpdated,
}

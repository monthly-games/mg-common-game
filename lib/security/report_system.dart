import 'dart:async';
import 'dart:convert';
import 'package:mg_common_game/storage/local_storage_service.dart';

/// Report category
enum ReportCategory {
  harassment,
  hateSpeech,
  spam,
  cheating,
  inappropriateContent,
  personalInfo,
  threat,
  other,
}

/// Report status
enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
  banned,
}

/// Report priority
enum ReportPriority {
  low,
  normal,
  high,
  urgent,
}

/// User report
class UserReport {
  final String reportId;
  final String reporterId;
  final String reporterName;
  final String reportedUserId;
  final String reportedUserName;
  final ReportCategory category;
  final String description;
  final List<String> evidence; // Screenshot URLs, message IDs, etc.
  final ReportStatus status;
  final ReportPriority priority;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;
  final String? reviewerId;
  final String? resolution;
  final Map<String, dynamic>? metadata;

  UserReport({
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.category,
    required this.description,
    required this.evidence,
    this.priority = ReportPriority.normal,
    DateTime? createdAt,
    this.status = ReportStatus.pending,
    this.reviewedAt,
    this.resolvedAt,
    this.reviewerId,
    this.resolution,
    this.metadata,
  })  : reportId = 'report_${DateTime.now().millisecondsSinceEpoch}',
        createdAt = createdAt ?? DateTime.now();

  /// Check if report is resolved
  bool get isResolved {
    return status == ReportStatus.resolved ||
           status == ReportStatus.dismissed ||
           status == ReportStatus.banned;
  }

  /// Get age of report
  Duration get age => DateTime.now().difference(createdAt);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'category': category.name,
      'description': description,
      'evidence': evidence,
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'reviewerId': reviewerId,
      'resolution': resolution,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      reporterId: json['reporterId'],
      reporterName: json['reporterName'],
      reportedUserId: json['reportedUserId'],
      reportedUserName: json['reportedUserName'],
      category: ReportCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ReportCategory.other,
      ),
      description: json['description'],
      evidence: (json['evidence'] as List?)?.cast<String>() ?? [],
      priority: ReportPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => ReportPriority.normal,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['reviewedAt'])
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['resolvedAt'])
          : null,
      reviewerId: json['reviewerId'],
      resolution: json['resolution'],
      metadata: json['metadata'],
    );
  }
}

/// Report action
class ReportAction {
  final String actionId;
  final String reportId;
  final String actionType;
  final String description;
  final String performedBy;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  ReportAction({
    required this.reportId,
    required this.actionType,
    required this.description,
    required this.performedBy,
    DateTime? timestamp,
    this.details,
  })  : actionId = 'action_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'reportId': reportId,
      'actionType': actionType,
      'description': description,
      'performedBy': performedBy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'details': details,
    };
  }
}

/// Report statistics
class ReportStatistics {
  final int totalReports;
  final int pendingReports;
  final int resolvedReports;
  final Map<ReportCategory, int> reportsByCategory;
  final Map<ReportStatus, int> reportsByStatus;
  final Map<String, int> reportsByUser;
  final DateTime startDate;
  final DateTime endDate;

  ReportStatistics({
    required this.totalReports,
    required this.pendingReports,
    required this.resolvedReports,
    required this.reportsByCategory,
    required this.reportsByStatus,
    required this.reportsByUser,
    required this.startDate,
    required this.endDate,
  });

  /// Get average resolution time
  Duration? get averageResolutionTime {
    // This would be calculated from actual report data
    return const Duration(hours: 24);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalReports': totalReports,
      'pendingReports': pendingReports,
      'resolvedReports': resolvedReports,
      'reportsByCategory': reportsByCategory.map((k, v) => MapEntry(k.name, v)),
      'reportsByStatus': reportsByStatus.map((k, v) => MapEntry(k.name, v)),
      'reportsByUser': reportsByUser,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
    };
  }
}

/// Report system configuration
class ReportSystemConfig {
  final int maxEvidenceItems;
  final Duration autoResolveTime;
  final int maxReportsPerUser;
  final bool enableAutoBan;

  const ReportSystemConfig({
    this.maxEvidenceItems = 5,
    this.autoResolveTime = const Duration(days: 7),
    this.maxReportsPerUser = 10,
    this.enableAutoBan = false,
  });
}

/// Report system
class ReportSystem {
  static final ReportSystem _instance = ReportSystem._internal();
  static ReportSystem get instance => _instance;

  ReportSystem._internal();

  final LocalStorageService _storage = LocalStorageService.instance;

  ReportSystemConfig _config = const ReportSystemConfig();

  final List<UserReport> _reports = [];
  final List<ReportAction> _actions = [];

  final StreamController<UserReport> _reportController = StreamController.broadcast();
  final StreamController<ReportAction> _actionController = StreamController.broadcast();

  /// Stream of reports
  Stream<UserReport> get reportStream => _reportController.stream;

  /// Stream of actions
  Stream<ReportAction> get actionStream => _actionController.stream;

  bool _isInitialized = false;

  /// Initialize report system
  Future<void> initialize({ReportSystemConfig? config}) async {
    if (_isInitialized) return;

    if (config != null) {
      _config = config;
    }

    await _storage.initialize();
    await _loadReports();
    await _loadActions();

    // Start auto-resolution timer
    _startAutoResolutionTimer();

    _isInitialized = true;
  }

  /// Load reports from storage
  Future<void> _loadReports() async {
    final reportsJson = _storage.getJsonList('user_reports');
    if (reportsJson != null) {
      for (final json in reportsJson) {
        if (json is Map<String, dynamic>) {
          final report = UserReport.fromJson(json);
          _reports.add(report);
        }
      }
    }
  }

  /// Save reports to storage
  Future<void> _saveReports() async {
    final jsonList = _reports.map((r) => r.toJson()).toList();
    await _storage.setJsonList('user_reports', jsonList);
  }

  /// Load actions from storage
  Future<void> _loadActions() async {
    final actionsJson = _storage.getJsonList('report_actions');
    if (actionsJson != null) {
      for (final json in actionsJson) {
        if (json is Map<String, dynamic>) {
          final action = ReportAction.fromJson(json);
          _actions.add(action);
        }
      }
    }
  }

  /// Save actions to storage
  Future<void> _saveActions() async {
    final jsonList = _actions.map((a) => a.toJson()).toList();
    await _storage.setJsonList('report_actions', jsonList);
  }

  /// Submit a report
  Future<UserReport> submitReport({
    required String reporterId,
    required String reporterName,
    required String reportedUserId,
    required String reportedUserName,
    required ReportCategory category,
    required String description,
    List<String>? evidence,
    ReportPriority priority = ReportPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate evidence count
    if (evidence != null && evidence.length > _config.maxEvidenceItems) {
      throw Exception('Too many evidence items');
    }

    // Check reporter's report count
    final reporterReports = _reports.where((r) =>
      r.reporterId == reporterId &&
      r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length;

    if (reporterReports >= _config.maxReportsPerUser) {
      throw Exception('Too many reports from this user');
    }

    final report = UserReport(
      reporterId: reporterId,
      reporterName: reporterName,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      category: category,
      description: description,
      evidence: evidence ?? [],
      priority: priority,
      metadata: metadata,
    );

    _reports.add(report);
    await _saveReports();

    _reportController.add(report);

    return report;
  }

  /// Get report by ID
  UserReport? getReport(String reportId) {
    try {
      return _reports.firstWhere((r) => r.reportId == reportId);
    } catch (e) {
      return null;
    }
  }

  /// Get all reports
  List<UserReport> getAllReports() {
    return List.from(_reports);
  }

  /// Get reports by status
  List<UserReport> getReportsByStatus(ReportStatus status) {
    return _reports.where((r) => r.status == status).toList();
  }

  /// Get reports by category
  List<UserReport> getReportsByCategory(ReportCategory category) {
    return _reports.where((r) => r.category == category).toList();
  }

  /// Get reports for user
  List<UserReport> getReportsForUser(String userId, {bool asReporter = false}) {
    if (asReporter) {
      return _reports.where((r) => r.reporterId == userId).toList();
    } else {
      return _reports.where((r) => r.reportedUserId == userId).toList();
    }
  }

  /// Get pending reports
  List<UserReport> getPendingReports() {
    return getReportsByStatus(ReportStatus.pending);
  }

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    required String reviewerId,
    String? resolution,
  }) async {
    final index = _reports.indexWhere((r) => r.reportId == reportId);
    if (index < 0) return;

    final report = _reports[index];

    final updated = UserReport(
      reporterId: report.reporterId,
      reporterName: report.reporterName,
      reportedUserId: report.reportedUserId,
      reportedUserName: report.reportedUserName,
      category: report.category,
      description: report.description,
      evidence: report.evidence,
      priority: report.priority,
      createdAt: report.createdAt,
      status: newStatus,
      reviewedAt: newStatus == ReportStatus.underReview ||
                  newStatus == ReportStatus.resolved ||
                  newStatus == ReportStatus.banned
          ? DateTime.now()
          : report.reviewedAt,
      resolvedAt: report.isResolved ? DateTime.now() : report.resolvedAt,
      reviewerId: reviewerId,
      resolution: resolution,
      metadata: report.metadata,
    );

    _reports[index] = updated;
    await _saveReports();

    // Add action
    await addAction(
      reportId: reportId,
      actionType: 'status_change',
      description: 'Status changed to ${newStatus.name}',
      performedBy: reviewerId,
      details: {'oldStatus': report.status.name, 'newStatus': newStatus.name},
    );

    _reportController.add(updated);
  }

  /// Add action to report
  Future<void> addAction({
    required String reportId,
    required String actionType,
    required String description,
    required String performedBy,
    Map<String, dynamic>? details,
  }) async {
    final action = ReportAction(
      reportId: reportId,
      actionType: actionType,
      description: description,
      performedBy: performedBy,
      details: details,
    );

    _actions.add(action);
    await _saveActions();

    _actionController.add(action);
  }

  /// Get actions for report
  List<ReportAction> getActionsForReport(String reportId) {
    return _actions.where((a) => a.reportId == reportId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Auto-resolve old reports
  Future<void> _startAutoResolutionTimer() async {
    // Check for old pending reports
    final cutoff = DateTime.now().subtract(_config.autoResolveTime);

    for (final report in _reports) {
      if (report.status == ReportStatus.pending && report.createdAt.isBefore(cutoff)) {
        await updateReportStatus(
          reportId: report.reportId,
          newStatus: ReportStatus.dismissed,
          reviewerId: 'system',
          resolution: 'Auto-dismissed due to age',
        );
      }
    }
  }

  /// Ban user based on report
  Future<void> banUserFromReport({
    required String reportId,
    required String adminId,
    Duration banDuration = const Duration(days: 30),
    String? reason,
  }) async {
    final report = getReport(reportId);
    if (report == null) return;

    // Update report status
    await updateReportStatus(
      reportId: reportId,
      newStatus: ReportStatus.banned,
      reviewerId: adminId,
      resolution: reason ?? 'User banned',
    );

    // Add ban action
    await addAction(
      reportId: reportId,
      actionType: 'ban',
      description: 'User banned for ${banDuration.inDays} days',
      performedBy: adminId,
      details: {'banDuration': banDuration.inDays},
    );
  }

  /// Get report statistics
  ReportStatistics getStatistics({Duration? period}) {
    final now = DateTime.now();
    final startDate = period != null ? now.subtract(period) : DateTime.now().subtract(const Duration(days: 30));

    final relevantReports = _reports.where((r) => r.createdAt.isAfter(startDate)).toList();

    final reportsByCategory = <ReportCategory, int>{};
    final reportsByStatus = <ReportStatus, int>{};
    final reportsByUser = <String, int>{};

    for (final report in relevantReports) {
      reportsByCategory[report.category] = (reportsByCategory[report.category] ?? 0) + 1;
      reportsByStatus[report.status] = (reportsByStatus[report.status] ?? 0) + 1;
      reportsByUser[report.reportedUserId] = (reportsByUser[report.reportedUserId] ?? 0) + 1;
    }

    return ReportStatistics(
      totalReports: relevantReports.length,
      pendingReports: reportsByStatus[ReportStatus.pending] ?? 0,
      resolvedReports: (reportsByStatus[ReportStatus.resolved] ?? 0) +
                     (reportsByStatus[ReportStatus.banned] ?? 0) +
                     (reportsByStatus[ReportStatus.dismissed] ?? 0),
      reportsByCategory: reportsByCategory,
      reportsByStatus: reportsByStatus,
      reportsByUser: reportsByUser,
      startDate: startDate,
      endDate: now,
    );
  }

  /// Get most reported users
  List<MapEntry<String, int>> getMostReportedUsers({int limit = 10}) {
    final reportsByUser = <String, int>{};

    for (final report in _reports) {
      reportsByUser[report.reportedUserId] = (reportsByUser[report.reportedUserId] ?? 0) + 1;
    }

    final entries = reportsByUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(limit).toList();
  }

  /// Get recent reports
  List<UserReport> getRecentReports({int limit = 20}) {
    final sorted = List<UserReport>.from(_reports)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  /// Search reports
  List<UserReport> searchReports({
    String? userId,
    ReportCategory? category,
    ReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var results = _reports;

    if (userId != null) {
      results = results.where((r) =>
        r.reporterId == userId || r.reportedUserId == userId).toList();
    }

    if (category != null) {
      results = results.where((r) => r.category == category).toList();
    }

    if (status != null) {
      results = results.where((r) => r.status == status).toList();
    }

    if (startDate != null) {
      results = results.where((r) => r.createdAt.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      results = results.where((r) => r.createdAt.isBefore(endDate)).toList();
    }

    return results..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Clear old reports
  Future<void> clearOldReports({Duration? maxAge}) async {
    final cutoff = maxAge != null
        ? DateTime.now().subtract(maxAge)
        : DateTime.now().subtract(const Duration(days: 90));

    _reports.removeWhere((r) => r.createdAt.isBefore(cutoff) && r.isResolved);
    await _saveReports();
  }

  /// Get user-friendly category name
  static String getCategoryName(ReportCategory category) {
    switch (category) {
      case ReportCategory.harassment:
        return 'Harassment';
      case ReportCategory.hateSpeech:
        return 'Hate Speech';
      case ReportCategory.spam:
        return 'Spam';
      case ReportCategory.cheating:
        return 'Cheating';
      case ReportCategory.inappropriateContent:
        return 'Inappropriate Content';
      case ReportCategory.personalInfo:
        return 'Personal Information';
      case ReportCategory.threat:
        return 'Threat';
      case ReportCategory.other:
        return 'Other';
    }
  }

  /// Validate report data
  static String? validateReportData({
    required String reporterId,
    required String reportedUserId,
    required String description,
  }) {
    if (reporterId == reportedUserId) {
      return 'Cannot report yourself';
    }

    if (description.trim().isEmpty) {
      return 'Description is required';
    }

    if (description.length > 1000) {
      return 'Description too long';
    }

    return null;
  }

  /// Dispose of resources
  void dispose() {
    _reportController.close();
    _actionController.close();
  }
}

/// ReportAction extension for JSON
extension ReportActionJson on ReportAction {
  static ReportAction fromJson(Map<String, dynamic> json) {
    return ReportAction(
      reportId: json['reportId'],
      actionType: json['actionType'],
      description: json['description'],
      performedBy: json['performedBy'],
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
      details: json['details'],
    );
  }

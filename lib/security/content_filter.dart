import 'dart:async';
import 'dart:convert';
import 'package:mg_common_game/storage/local_storage_service.dart';

/// Content filter type
enum FilterType {
  profanity,
  spam,
  harassment,
  personalInfo,
  phishing,
  custom,
}

/// Filter result
class FilterResult {
  final bool isFiltered;
  final String? filteredContent;
  final List<FilterViolation> violations;
  final FilterSeverity severity;

  FilterResult({
    required this.isFiltered,
    this.filteredContent,
    this.violations = const [],
    this.severity = FilterSeverity.low,
  });

  /// Create clean result
  factory FilterResult.clean() {
    return FilterResult(
      isFiltered: false,
      violations: [],
    );
  }

  /// Create filtered result
  factory FilterResult.filtered({
    required String filteredContent,
    required List<FilterViolation> violations,
    FilterSeverity severity = FilterSeverity.medium,
  }) {
    return FilterResult(
      isFiltered: true,
      filteredContent: filteredContent,
      violations: violations,
      severity: severity,
    );
  }
}

/// Filter violation
class FilterViolation {
  final FilterType type;
  final String matchedContent;
  final String rule;
  final int position;

  FilterViolation({
    required this.type,
    required this.matchedContent,
    required this.rule,
    required this.position,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'matchedContent': matchedContent,
      'rule': rule,
      'position': position,
    };
  }
}

/// Filter severity
enum FilterSeverity {
  low,
  medium,
  high,
  critical,
}

/// Filter rule
class FilterRule {
  final String ruleId;
  final FilterType type;
  final String pattern;
  final String? replacement;
  final FilterSeverity severity;
  final bool isEnabled;

  FilterRule({
    required this.ruleId,
    required this.type,
    required this.pattern,
    this.replacement,
    required this.severity,
    this.isEnabled = true,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'type': type.name,
      'pattern': pattern,
      'replacement': replacement,
      'severity': severity.name,
      'isEnabled': isEnabled,
    };
  }

  /// Create from JSON
  factory FilterRule.fromJson(Map<String, dynamic> json) {
    return FilterRule(
      ruleId: json['ruleId'],
      type: FilterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FilterType.custom,
      ),
      pattern: json['pattern'],
      replacement: json['replacement'],
      severity: FilterSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => FilterSeverity.medium,
      ),
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}

/// User moderation status
class ModerationStatus {
  final String userId;
  final bool isMuted;
  final bool isBanned;
  final DateTime? muteExpiry;
  final DateTime? banExpiry;
  final int warningCount;
  final List<String> blockedContent;

  ModerationStatus({
    required this.userId,
    this.isMuted = false,
    this.isBanned = false,
    this.muteExpiry,
    this.banExpiry,
    this.warningCount = 0,
    this.blockedContent = const [],
  });

  /// Check if user can post
  bool get canPost => !isMuted && !isBanned;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isMuted': isMuted,
      'isBanned': isBanned,
      'muteExpiry': muteExpiry?.millisecondsSinceEpoch,
      'banExpiry': banExpiry?.millisecondsSinceEpoch,
      'warningCount': warningCount,
      'blockedContent': blockedContent,
    };
  }

  /// Create from JSON
  factory ModerationStatus.fromJson(Map<String, dynamic> json) {
    return ModerationStatus(
      userId: json['userId'],
      isMuted: json['isMuted'] ?? false,
      isBanned: json['isBanned'] ?? false,
      muteExpiry: json['muteExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['muteExpiry'])
          : null,
      banExpiry: json['banExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['banExpiry'])
          : null,
      warningCount: json['warningCount'] ?? 0,
      blockedContent: (json['blockedContent'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Content filter configuration
class ContentFilterConfig {
  final bool enableProfanityFilter;
  final bool enableSpamFilter;
  final bool enableHarassmentFilter;
  final bool enablePersonalInfoFilter;
  final int maxMessageLength;
  final int maxLinksPerMessage;
  final int maxMentionsPerMessage;

  const ContentFilterConfig({
    this.enableProfanityFilter = true,
    this.enableSpamFilter = true,
    this.enableHarassmentFilter = true,
    this.enablePersonalInfoFilter = true,
    this.maxMessageLength = 500,
    this.maxLinksPerMessage = 3,
    this.maxMentionsPerMessage = 5,
  });
}

/// Content filter
class ContentFilter {
  static final ContentFilter _instance = ContentFilter._internal();
  static ContentFilter get instance => _instance;

  ContentFilter._internal();

  final LocalStorageService _storage = LocalStorageService.instance;

  ContentFilterConfig _config = const ContentFilterConfig();

  final List<FilterRule> _rules = [];
  final Map<String, ModerationStatus> _userStatus = {};

  final StreamController<FilterResult> _filterController = StreamController.broadcast();
  final StreamController<ModerationStatus> _moderationController = StreamController.broadcast();

  /// Stream of filter results
  Stream<FilterResult> get filterStream => _filterController.stream;

  /// Stream of moderation updates
  Stream<ModerationStatus> get moderationStream => _moderationController.stream;

  bool _isInitialized = false;

  /// Initialize content filter
  Future<void> initialize({ContentFilterConfig? config}) async {
    if (_isInitialized) return;

    if (config != null) {
      _config = config;
    }

    await _storage.initialize();
    await _loadRules();
    await _loadUserStatus();

    // Create default rules if none exist
    if (_rules.isEmpty) {
      _createDefaultRules();
      await _saveRules();
    }

    _isInitialized = true;
  }

  /// Load filter rules from storage
  Future<void> _loadRules() async {
    final rulesJson = _storage.getJsonList('filter_rules');
    if (rulesJson != null) {
      for (final json in rulesJson) {
        if (json is Map<String, dynamic>) {
          final rule = FilterRule.fromJson(json);
          _rules.add(rule);
        }
      }
    }
  }

  /// Save filter rules to storage
  Future<void> _saveRules() async {
    final jsonList = _rules.map((r) => r.toJson()).toList();
    await _storage.setJsonList('filter_rules', jsonList);
  }

  /// Load user moderation status
  Future<void> _loadUserStatus() async {
    final statusJson = _storage.getJsonList('user_moderation_status');
    if (statusJson != null) {
      for (final json in statusJson) {
        if (json is Map<String, dynamic>) {
          final status = ModerationStatus.fromJson(json);
          _userStatus[status.userId] = status;
        }
      }
    }
  }

  /// Save user moderation status
  Future<void> _saveUserStatus() async {
    final jsonList = _userStatus.values.map((s) => s.toJson()).toList();
    await _storage.setJsonList('user_moderation_status', jsonList);
  }

  /// Create default filter rules
  void _createDefaultRules() {
    _rules.addAll([
      // Profanity filter rules
      FilterRule(
        ruleId: 'profanity_1',
        type: FilterType.profanity,
        pattern: r'\b(badword|offensive|slur)\b',
        replacement: '***',
        severity: FilterSeverity.high,
      ),

      // Spam filter rules
      FilterRule(
        ruleId: 'spam_1',
        type: FilterType.spam,
        pattern: r'(buy\s+gold|cheap\s+gems|free\s+items)',
        replacement: null,
        severity: FilterSeverity.medium,
      ),

      // Personal info filter rules
      FilterRule(
        ruleId: 'personal_info_1',
        type: FilterType.personalInfo,
        pattern: r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', // Phone number
        replacement: '[PHONE]',
        severity: FilterSeverity.high,
      ),

      FilterRule(
        ruleId: 'personal_info_2',
        type: FilterType.personalInfo,
        pattern: r'\b[\w.-]+@[\w.-]+\.\w+\b', // Email
        replacement: '[EMAIL]',
        severity: FilterSeverity.high,
      ),

      // Harassment filter rules
      FilterRule(
        ruleId: 'harassment_1',
        type: FilterType.harassment,
        pattern: r'\b(idiot|stupid|loser|pathetic)\b',
        replacement: '***',
        severity: FilterSeverity.high,
      ),
    ]);
  }

  /// Filter content
  FilterResult filterContent(String content, {String? userId}) {
    final violations = <FilterViolation>[];
    var filteredContent = content;
    var maxSeverity = FilterSeverity.low;

    // Check user moderation status
    if (userId != null) {
      final status = _userStatus[userId];
      if (status != null && !status.canPost) {
        return FilterResult.filtered(
          filteredContent: '',
          violations: [
            FilterViolation(
              type: FilterType.custom,
              matchedContent: content,
              rule: status.isMuted ? 'User is muted' : 'User is banned',
              position: 0,
            ),
          ],
          severity: FilterSeverity.critical,
        );
      }
    }

    // Check message length
    if (content.length > _config.maxMessageLength) {
      return FilterResult.filtered(
        filteredContent: content.substring(0, _config.maxMessageLength),
        violations: [
          FilterViolation(
            type: FilterType.custom,
            matchedContent: content,
            rule: 'Message too long',
            position: 0,
          ),
        ],
        severity: FilterSeverity.low,
      );
    }

    // Check for too many links
    final linkCount = content.replaceAll(RegExp(r'https?://'), '').length;
    if (linkCount > _config.maxLinksPerMessage) {
      violations.add(FilterViolation(
        type: FilterType.spam,
        matchedContent: content,
        rule: 'Too many links',
        position: 0,
      ));
    }

    // Check for too many mentions
    final mentionCount = '@'.allMatches(content).length;
    if (mentionCount > _config.maxMentionsPerMessage) {
      violations.add(FilterViolation(
        type: FilterType.spam,
        matchedContent: content,
        rule: 'Too many mentions',
        position: 0,
      ));
    }

    // Apply filter rules
    for (final rule in _rules) {
      if (!rule.isEnabled) continue;

      // Check if rule type is enabled
      if (!_isRuleTypeEnabled(rule.type)) continue;

      // Apply rule
      final matches = RegExp(rule.pattern, caseSensitive: false).allMatches(content);
      for (final match in matches) {
        violations.add(FilterViolation(
          type: rule.type,
          matchedContent: match.group(0) ?? '',
          rule: rule.ruleId,
          position: match.start,
        ));

        // Update severity if this violation is more severe
        if (rule.severity.index > maxSeverity.index) {
          maxSeverity = rule.severity;
        }

        // Replace content if replacement is provided
        if (rule.replacement != null) {
          filteredContent = filteredContent.replaceAll(RegExp(rule.pattern, caseSensitive: false), rule.replacement!);
        }
      }
    }

    // Determine result
    if (violations.isEmpty) {
      _filterController.add(FilterResult.clean());
      return FilterResult.clean();
    } else {
      final result = FilterResult.filtered(
        filteredContent: filteredContent,
        violations: violations,
        severity: maxSeverity,
      );
      _filterController.add(result);
      return result;
    }
  }

  /// Check if rule type is enabled
  bool _isRuleTypeEnabled(FilterType type) {
    switch (type) {
      case FilterType.profanity:
        return _config.enableProfanityFilter;
      case FilterType.spam:
        return _config.enableSpamFilter;
      case FilterType.harassment:
        return _config.enableHarassmentFilter;
      case FilterType.personalInfo:
        return _config.enablePersonalInfoFilter;
      default:
        return true;
    }
  }

  /// Check if content is safe
  bool isSafe(String content, {String? userId}) {
    final result = filterContent(content, userId: userId);
    return !result.isFiltered;
  }

  /// Get filtered content
  String? getFilteredContent(String content, {String? userId}) {
    final result = filterContent(content, userId: userId);
    return result.filteredContent ?? content;
  }

  /// Add custom filter rule
  Future<void> addRule(FilterRule rule) async {
    _rules.add(rule);
    await _saveRules();
  }

  /// Remove filter rule
  Future<void> removeRule(String ruleId) async {
    _rules.removeWhere((r) => r.ruleId == ruleId);
    await _saveRules();
  }

  /// Get all rules
  List<FilterRule> getRules() {
    return List.from(_rules);
  }

  /// Get rules by type
  List<FilterRule> getRulesByType(FilterType type) {
    return _rules.where((r) => r.type == type).toList();
  }

  /// Enable/disable rule
  Future<void> setRuleEnabled(String ruleId, bool enabled) async {
    final rule = _rules.firstWhere((r) => r.ruleId == ruleId);
    final index = _rules.indexOf(rule);

    final updatedRule = FilterRule(
      ruleId: rule.ruleId,
      type: rule.type,
      pattern: rule.pattern,
      replacement: rule.replacement,
      severity: rule.severity,
      isEnabled: enabled,
    );

    _rules[index] = updatedRule;
    await _saveRules();
  }

  /// Mute user
  Future<void> muteUser(String userId, Duration duration) async {
    final status = _userStatus[userId] ?? ModerationStatus(userId: userId);
    final now = DateTime.now();

    final updatedStatus = ModerationStatus(
      userId: userId,
      isMuted: true,
      isBanned: status.isBanned,
      muteExpiry: now.add(duration),
      banExpiry: status.banExpiry,
      warningCount: status.warningCount,
      blockedContent: status.blockedContent,
    );

    _userStatus[userId] = updatedStatus;
    await _saveUserStatus();

    _moderationController.add(updatedStatus);
  }

  /// Unmute user
  Future<void> unmuteUser(String userId) async {
    final status = _userStatus[userId];
    if (status == null || !status.isMuted) return;

    final updatedStatus = ModerationStatus(
      userId: userId,
      isMuted: false,
      isBanned: status.isBanned,
      muteExpiry: null,
      banExpiry: status.banExpiry,
      warningCount: status.warningCount,
      blockedContent: status.blockedContent,
    );

    _userStatus[userId] = updatedStatus;
    await _saveUserStatus();

    _moderationController.add(updatedStatus);
  }

  /// Ban user
  Future<void> banUser(String userId, Duration duration) async {
    final status = _userStatus[userId] ?? ModerationStatus(userId: userId);
    final now = DateTime.now();

    final updatedStatus = ModerationStatus(
      userId: userId,
      isMuted: status.isMuted,
      isBanned: true,
      muteExpiry: status.muteExpiry,
      banExpiry: now.add(duration),
      warningCount: status.warningCount,
      blockedContent: status.blockedContent,
    );

    _userStatus[userId] = updatedStatus;
    await _saveUserStatus();

    _moderationController.add(updatedStatus);
  }

  /// Unban user
  Future<void> unbanUser(String userId) async {
    final status = _userStatus[userId];
    if (status == null || !status.isBanned) return;

    final updatedStatus = ModerationStatus(
      userId: userId,
      isMuted: status.isMuted,
      isBanned: false,
      muteExpiry: status.muteExpiry,
      banExpiry: null,
      warningCount: status.warningCount,
      blockedContent: status.blockedContent,
    );

    _userStatus[userId] = updatedStatus;
    await _saveUserStatus();

    _moderationController.add(updatedStatus);
  }

  /// Warn user
  Future<void> warnUser(String userId) async {
    final status = _userStatus[userId] ?? ModerationStatus(userId: userId);

    final updatedStatus = ModerationStatus(
      userId: userId,
      isMuted: status.isMuted,
      isBanned: status.isBanned,
      muteExpiry: status.muteExpiry,
      banExpiry: status.banExpiry,
      warningCount: status.warningCount + 1,
      blockedContent: status.blockedContent,
    );

    _userStatus[userId] = updatedStatus;
    await _saveUserStatus();

    _moderationController.add(updatedStatus);
  }

  /// Get user moderation status
  ModerationStatus? getUserStatus(String userId) {
    return _userStatus[userId];
  }

  /// Check if user can post
  bool canUserPost(String userId) {
    final status = _userStatus[userId];
    return status?.canPost ?? true;
  }

  /// Get moderation statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    int mutedCount = 0;
    int bannedCount = 0;

    for (final status in _userStatus.values) {
      if (status.isMuted && status.muteExpiry != null && now.isBefore(status.muteExpiry!)) {
        mutedCount++;
      }
      if (status.isBanned && status.banExpiry != null && now.isBefore(status.banExpiry!)) {
        bannedCount++;
      }
    }

    return {
      'totalRules': _rules.length,
      'enabledRules': _rules.where((r) => r.isEnabled).length,
      'usersUnderModeration': _userStatus.length,
      'mutedUsers': mutedCount,
      'bannedUsers': bannedCount,
      'rulesByType': {
        for (final type in FilterType.values)
          type.name: _rules.where((r) => r.type == type && r.isEnabled).length
      },
    };
  }

  /// Dispose of resources
  void dispose() {
    _filterController.close();
    _moderationController.close();
  }
}

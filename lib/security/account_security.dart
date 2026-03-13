import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:mg_common_game/storage/local_storage_service.dart';
import 'package:mg_common_game/network/auth_service.dart';

/// Security level
enum SecurityLevel {
  low,
  medium,
  high,
  maximum,
}

/// Session type
enum SessionType {
  web,
  mobile,
  desktop,
}

/// Security event
class SecurityEvent {
  final String eventId;
  final String userId;
  final String eventType;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  SecurityEvent({
    required this.userId,
    required this.eventType,
    required this.description,
    this.metadata = const {},
    DateTime? timestamp,
    this.ipAddress,
    this.userAgent,
  })  : eventId = 'event_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'eventType': eventType,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }
}

/// User session
class UserSession {
  final String sessionId;
  final String userId;
  final SessionType type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? lastActiveAt;
  final String? ipAddress;
  final String? deviceInfo;
  final bool isActive;

  UserSession({
    required this.sessionId,
    required this.userId,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.lastActiveAt,
    this.ipAddress,
    this.deviceInfo,
    this.isActive = true,
  });

  /// Check if session is valid
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Check if session is expired
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Get session duration
  Duration get duration {
    final end = lastActiveAt ?? DateTime.now();
    return end.difference(createdAt);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'lastActiveAt': lastActiveAt?.millisecondsSinceEpoch,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'isActive': isActive,
    };
  }

  /// Create from JSON
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['sessionId'],
      userId: json['userId'],
      type: SessionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SessionType.mobile,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'])
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActiveAt'])
          : null,
      ipAddress: json['ipAddress'],
      deviceInfo: json['deviceInfo'],
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Password policy
class PasswordPolicy {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  final List<String> forbiddenPasswords;
  final int maxAge; // in days

  const PasswordPolicy({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
    this.forbiddenPasswords = const [],
    this.maxAge = 90,
  });

  /// Validate password
  String? validate(String password) {
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letters';
    }

    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letters';
    }

    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain numbers';
    }

    if (requireSpecialChars && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special characters';
    }

    if (forbiddenPasswords.contains(password)) {
      return 'This password is too common';
    }

    return null;
  }

  /// Generate secure random password
  String generate({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random.secure();

    return List.generate(length, (index) {
      return chars[random.nextInt(chars.length)];
    }).join('');
  }
}

/// 2FA configuration
class TwoFactorConfig {
  final String userId;
  final bool isEnabled;
  final String? secretKey;
  final List<String> backupCodes;
  final DateTime? enabledAt;

  TwoFactorConfig({
    required this.userId,
    this.isEnabled = false,
    this.secretKey,
    this.backupCodes = const [],
    this.enabledAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isEnabled': isEnabled,
      'secretKey': secretKey,
      'backupCodes': backupCodes,
      'enabledAt': enabledAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory TwoFactorConfig.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfig(
      userId: json['userId'],
      isEnabled: json['isEnabled'] ?? false,
      secretKey: json['secretKey'],
      backupCodes: (json['backupCodes'] as List?)?.cast<String>() ?? [],
      enabledAt: json['enabledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['enabledAt'])
          : null,
    );
  }
}

/// Security configuration
class SecurityConfig {
  final PasswordPolicy passwordPolicy;
  final int maxFailedAttempts;
  final Duration lockoutDuration;
  final Duration sessionTimeout;
  final bool require2FA;
  final bool enableIPTracking;
  final bool enableDeviceFingerprinting;
  final int maxConcurrentSessions;

  const SecurityConfig({
    this.passwordPolicy = const PasswordPolicy(),
    this.maxFailedAttempts = 5,
    this.lockoutDuration = const Duration(minutes: 30),
    this.sessionTimeout = const Duration(days: 7),
    this.require2FA = false,
    this.enableIPTracking = true,
    this.enableDeviceFingerprinting = true,
    this.maxConcurrentSessions = 3,
  });
}

/// Account security manager
class AccountSecurityManager {
  static final AccountSecurityManager _instance = AccountSecurityManager._internal();
  static AccountSecurityManager get instance => _instance;

  AccountSecurityManager._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final AuthService _authService = AuthService.instance;

  SecurityConfig _config = const SecurityConfig();

  final Map<String, UserSession> _sessions = {};
  final Map<String, TwoFactorConfig> _twoFactorConfigs = {};
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockouts = {};
  final List<SecurityEvent> _securityEvents = [];

  final StreamController<UserSession> _sessionController = StreamController.broadcast();
  final StreamController<SecurityEvent> _eventController = StreamController.broadcast();

  /// Stream of session updates
  Stream<UserSession> get sessionStream => _sessionController.stream;

  /// Stream of security events
  Stream<SecurityEvent> get eventStream => _eventController.stream;

  bool _isInitialized = false;

  /// Initialize security manager
  Future<void> initialize({SecurityConfig? config}) async {
    if (_isInitialized) return;

    if (config != null) {
      _config = config;
    }

    await _storage.initialize();
    await _loadSessions();
    await _loadTwoFactorConfigs();
    await _loadFailedAttempts();

    _isInitialized = true;
  }

  /// Load sessions from storage
  Future<void> _loadSessions() async {
    final sessionsJson = _storage.getJsonList('user_sessions');
    if (sessionsJson != null) {
      for (final json in sessionsJson) {
        if (json is Map<String, dynamic>) {
          final session = UserSession.fromJson(json);
          if (session.isValid) {
            _sessions[session.sessionId] = session;
          }
        }
      }
    }
  }

  /// Save sessions to storage
  Future<void> _saveSessions() async {
    final jsonList = _sessions.values.map((s) => s.toJson()).toList();
    await _storage.setJsonList('user_sessions', jsonList);
  }

  /// Load 2FA configs from storage
  Future<void> _loadTwoFactorConfigs() async {
    final configsJson = _storage.getJsonList('two_factor_configs');
    if (configsJson != null) {
      for (final json in configsJson) {
        if (json is Map<String, dynamic>) {
          final config = TwoFactorConfig.fromJson(json);
          _twoFactorConfigs[config.userId] = config;
        }
      }
    }
  }

  /// Save 2FA configs to storage
  Future<void> _saveTwoFactorConfigs() async {
    final jsonList = _twoFactorConfigs.values.map((c) => c.toJson()).toList();
    await _storage.setJsonList('two_factor_configs', jsonList);
  }

  /// Load failed attempts from storage
  Future<void> _loadFailedAttempts() async {
    final attemptsJson = _storage.getJson('failed_attempts');
    if (attemptsJson != null) {
      for (final entry in attemptsJson.entries) {
        _failedAttempts[entry.key] = entry.value as int;
      }
    }

    final lockoutsJson = _storage.getJson('account_lockouts');
    if (lockoutsJson != null) {
      for (final entry in lockoutsJson.entries) {
        _lockouts[entry.key] = DateTime.fromMillisecondsSinceEpoch(entry.value as int);
      }
    }
  }

  /// Save failed attempts to storage
  Future<void> _saveFailedAttempts() async {
    await _storage.setJson('failed_attempts', _failedAttempts);
    await _storage.setJson('account_lockouts',
      _lockouts.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)));
  }

  /// Create session
  Future<UserSession> createSession({
    required String userId,
    required SessionType type,
    String? ipAddress,
    String? deviceInfo,
    Duration? timeout,
  }) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Check concurrent session limit
    final userSessions = _sessions.values.where((s) => s.userId == userId && s.isValid).toList();
    if (userSessions.length >= _config.maxConcurrentSessions) {
      // Terminate oldest session
      final oldest = userSessions.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);
      await terminateSession(oldest.sessionId);
    }

    final session = UserSession(
      sessionId: sessionId,
      userId: userId,
      type: type,
      createdAt: now,
      expiresAt: timeout != null ? now.add(timeout) : now.add(_config.sessionTimeout),
      lastActiveAt: now,
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    );

    _sessions[sessionId] = session;
    await _saveSessions();

    // Log security event
    _logEvent(SecurityEvent(
      userId: userId,
      eventType: 'session_created',
      description: 'New session created',
      metadata: {
        'sessionId': sessionId,
        'type': type.name,
      },
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    ));

    _sessionController.add(session);

    return session;
  }

  /// Terminate session
  Future<void> terminateSession(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) return;

    final terminated = UserSession(
      sessionId: session.sessionId,
      userId: session.userId,
      type: session.type,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      lastActiveAt: DateTime.now(),
      ipAddress: session.ipAddress,
      deviceInfo: session.deviceInfo,
      isActive: false,
    );

    _sessions[sessionId] = terminated;
    await _saveSessions();

    _logEvent(SecurityEvent(
      userId: session.userId,
      eventType: 'session_terminated',
      description: 'Session terminated',
      metadata: {'sessionId': sessionId},
    ));

    _sessionController.add(terminated);
  }

  /// Terminate all user sessions
  Future<void> terminateAllUserSessions(String userId) async {
    final userSessions = _sessions.entries
        .where((e) => e.value.userId == userId && e.value.isValid)
        .map((e) => e.key)
        .toList();

    for (final sessionId in userSessions) {
      await terminateSession(sessionId);
    }
  }

  /// Validate session
  bool validateSession(String sessionId) {
    final session = _sessions[sessionId];
    return session != null && session.isValid;
  }

  /// Get active sessions for user
  List<UserSession> getUserSessions(String userId) {
    return _sessions.values
        .where((s) => s.userId == userId && s.isValid)
        .toList()
      ..sort((a, b) => b.lastActiveAt!.compareTo(a.lastActiveAt!));
  }

  /// Record failed login attempt
  Future<void> recordFailedAttempt(String userId) async {
    _failedAttempts[userId] = (_failedAttempts[userId] ?? 0) + 1;
    await _saveFailedAttempts();

    // Check if should lock account
    if (_failedAttempts[userId]! >= _config.maxFailedAttempts) {
      await _lockAccount(userId);
    }

    _logEvent(SecurityEvent(
      userId: userId,
      eventType: 'failed_login',
      description: 'Failed login attempt',
      metadata: {
        'attemptCount': _failedAttempts[userId],
        'maxAttempts': _config.maxFailedAttempts,
      },
    ));
  }

  /// Clear failed attempts
  Future<void> clearFailedAttempts(String userId) async {
    _failedAttempts.remove(userId);
    await _saveFailedAttempts();
  }

  /// Lock account
  Future<void> _lockAccount(String userId) async {
    _lockouts[userId] = DateTime.now().add(_config.lockoutDuration);
    await _saveFailedAttempts();

    // Terminate all sessions
    await terminateAllUserSessions(userId);

    _logEvent(SecurityEvent(
      userId: userId,
      eventType: 'account_locked',
      description: 'Account locked due to too many failed attempts',
      metadata: {
        'duration': _config.lockoutDuration.inMinutes,
      },
    ));
  }

  /// Check if account is locked
  bool isAccountLocked(String userId) {
    final lockUntil = _lockouts[userId];
    if (lockUntil == null) return false;

    if (DateTime.now().isAfter(lockUntil)) {
      _lockouts.remove(userId);
      _saveFailedAttempts();
      return false;
    }

    return true;
  }

  /// Validate password
  String? validatePassword(String password) {
    return _config.passwordPolicy.validate(password);
  }

  /// Generate secure password
  String generatePassword({int length = 16}) {
    return _config.passwordPolicy.generate(length: length);
  }

  /// Setup 2FA
  Future<TwoFactorConfig> setup2FA(String userId) async {
    final secret = _generateSecretKey();
    final backupCodes = _generateBackupCodes();

    final config = TwoFactorConfig(
      userId: userId,
      isEnabled: true,
      secretKey: secret,
      backupCodes: backupCodes,
      enabledAt: DateTime.now(),
    );

    _twoFactorConfigs[userId] = config;
    await _saveTwoFactorConfigs();

    _logEvent(SecurityEvent(
      userId: userId,
      eventType: '2fa_enabled',
      description: '2FA enabled',
    ));

    return config;
  }

  /// Disable 2FA
  Future<void> disable2FA(String userId) async {
    _twoFactorConfigs.remove(userId);
    await _saveTwoFactorConfigs();

    _logEvent(SecurityEvent(
      userId: userId,
      eventType: '2fa_disabled',
      description: '2FA disabled',
    ));
  }

  /// Verify 2FA code
  bool verify2FACode(String userId, String code) {
    final config = _twoFactorConfigs[userId];
    if (config == null || !config.isEnabled) {
      return false;
    }

    // Here you would verify the TOTP code
    // For now, just check if it's a 6-digit code
    return RegExp(r'^\d{6}$').hasMatch(code);
  }

  /// Use backup code
  bool useBackupCode(String userId, String code) {
    final config = _twoFactorConfigs[userId];
    if (config == null) return false;

    if (config.backupCodes.contains(code)) {
      config.backupCodes.remove(code);
      _saveTwoFactorConfigs();
      return true;
    }

    return false;
  }

  /// Generate secret key for 2FA
  String _generateSecretKey() {
    final random = Random.secure();
    final codeUnits = List.generate(32, (index) {
      return random.nextInt(256);
    });

    return base64Url.encode(codeUnits);
  }

  /// Generate backup codes for 2FA
  List<String> _generateBackupCodes() {
    final codes = <String>[];
    final random = Random.secure();

    for (int i = 0; i < 10; i++) {
      final code = random.nextInt(1000000).toString().padLeft(6, '0');
      codes.add(code);
    }

    return codes;
  }

  /// Log security event
  void _logEvent(SecurityEvent event) {
    _securityEvents.add(event);
    _eventController.add(event);

    // Save to storage if needed
    _storage.setJson(
      'security_event_${event.eventId}',
      event.toJson(),
    );
  }

  /// Get security events for user
  List<SecurityEvent> getSecurityEvents(String userId, {int limit = 100}) {
    return _securityEvents
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
      ..take(limit);
  }

  /// Get user's 2FA config
  TwoFactorConfig? getTwoFactorConfig(String userId) {
    return _twoFactorConfigs[userId];
  }

  /// Check if user has 2FA enabled
  bool has2FAEnabled(String userId) {
    return _twoFactorConfigs[userId]?.isEnabled ?? false;
  }

  /// Update session activity
  Future<void> updateSessionActivity(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null || !session.isValid) return;

    final updated = UserSession(
      sessionId: session.sessionId,
      userId: session.userId,
      type: session.type,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      lastActiveAt: DateTime.now(),
      ipAddress: session.ipAddress,
      deviceInfo: session.deviceInfo,
      isActive: session.isActive,
    );

    _sessions[sessionId] = updated;
    await _saveSessions();

    _sessionController.add(updated);
  }

  /// Clean up expired sessions
  Future<void> cleanupExpiredSessions() async {
    final now = DateTime.now();
    final expiredSessions = _sessions.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();

    for (final sessionId in expiredSessions) {
      await terminateSession(sessionId);
    }
  }

  /// Get security statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final activeSessions = _sessions.values.where((s) => s.isValid).length;
    final lockedAccounts = _lockouts.values.where((lockUntil) => now.isBefore(lockUntil)).length;

    return {
      'activeSessions': activeSessions,
      'lockedAccounts': lockedAccounts,
      'usersWith2FA': _twoFactorConfigs.values.where((c) => c.isEnabled).length,
      'totalEvents': _securityEvents.length,
      'config': {
        'maxConcurrentSessions': _config.maxConcurrentSessions,
        'maxFailedAttempts': _config.maxFailedAttempts,
        'require2FA': _config.require2FA,
        'enableIPTracking': _config.enableIPTracking,
      },
    };
  }

  /// Dispose of resources
  void dispose() {
    _sessionController.close();
    _eventController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart' as pointy;

/// 보안 이벤트 타입
enum SecurityEventType {
  login,          // 로그인
  logout,         // 로그아웃
  passwordChange, // 비밀번호 변경
  twoFactorEnabled, // 2FA 활성화
  twoFactorDisabled, // 2FA 비활성화
  suspiciousActivity, // 의심스러운 활동
  accountLocked,  // 계정 잠금
  accountUnlocked, // 계정 잠금 해제
  dataEncryption,  // 데이터 암호화
  dataDecryption,  // 데이터 복호화
}

/// 보안 위협 레벨
enum ThreatLevel {
  none,           // 없음
  low,            // 낮음
  medium,         // 중간
  high,           // 높음
  critical,       // 치명적
}

/// 2FA 타입
enum TwoFactorType {
  sms,            // SMS
  email,          // 이메일
  authenticator,   // 인증 앱 (Google Authenticator 등)
  biometric,      // 생체 인식
  hardwareKey,     // 하드웨어 키 (YubiKey 등)
}

/// 암호화 알고리즘
enum EncryptionAlgorithm {
  aes256GCM,      // AES-256-GCM
  aes256CBC,      // AES-256-CBC
  rsa2048,        // RSA-2048
  rsa4096,        // RSA-4096
  chaCha20,       // ChaCha20
}

/// 보안 이벤트
class SecurityEvent {
  final String id;
  final SecurityEventType type;
  final String userId;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final ThreatLevel threatLevel;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const SecurityEvent({
    required this.id,
    required this.type,
    required this.userId,
    this.description,
    this.ipAddress,
    this.userAgent,
    required this.threatLevel,
    required this.timestamp,
    this.metadata,
  });
}

/// 2FA 설정
class TwoFactorSettings {
  final String userId;
  final bool isEnabled;
  final TwoFactorType type;
  final String? secretKey; // 인증 앱용 시크릿 키
  final List<String> backupCodes; // 백업 코드
  final DateTime? enabledAt;

  const TwoFactorSettings({
    required this.userId,
    required this.isEnabled,
    required this.type,
    this.secretKey,
    required this.backupCodes,
    this.enabledAt,
  });
}

/// 암호화된 데이터
class EncryptedData {
  final String id;
  final String data;
  final String nonce; // AES-GCM용
  final String? tag; // 인증 태그
  final EncryptionAlgorithm algorithm;
  final DateTime encryptedAt;

  const EncryptedData({
    required this.id,
    required this.data,
    required this.nonce,
    this.tag,
    required this.algorithm,
    required this.encryptedAt,
  });
}

/// 접속 제어 규칙
class AccessControlRule {
  final String id;
  final String name;
  final Map<String, dynamic> conditions;
  final Action action;
  final DateTime createdAt;

  const AccessControlRule({
    required this.id,
    required this.name,
    required this.conditions,
    required this.action,
    required this.createdAt,
  });
}

enum Action {
  allow,          // 허용
  deny,           // 거부
  challenge,       // 추가 검증 요구
  mfa,            // MFA 요구
}

/// 보안 강화 관리자
class SecurityEnhancementManager {
  static final SecurityEnhancementManager _instance =
      SecurityEnhancementManager._();
  static SecurityEnhancementManager get instance => _instance;

  SecurityEnhancementManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, TwoFactorSettings> _twoFactorSettings = {};
  final Map<String, EncryptedData> _encryptedData = {};
  final Map<String, List<SecurityEvent>> _securityEvents = {};
  final Map<String, AccessControlRule> _accessRules = {};

  final StreamController<SecurityEvent> _eventController =
      StreamController<SecurityEvent>.broadcast();
  final StreamController<ThreatLevel> _threatController =
      StreamController<ThreatLevel>.broadcast();

  Stream<SecurityEvent> get onSecurityEvent => _eventController.stream;
  Stream<ThreatLevel> get onThreatChange => _threatController.stream;

  Timer? _monitoringTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 2FA 설정 로드
    await _loadTwoFactorSettings();

    // 접근 제어 규칙 로드
    _loadAccessRules();

    // 보안 모니터링 시작
    _startSecurityMonitoring();

    debugPrint('[SecurityEnhancement] Initialized');
  }

  Future<void> _loadTwoFactorSettings() async {
    if (_currentUserId != null) {
      _twoFactorSettings[_currentUserId!] = const TwoFactorSettings(
        userId: _currentUserId!,
        isEnabled: false,
        type: TwoFactorType.authenticator,
        backupCodes: [],
      );
    }
  }

  void _loadAccessRules() {
    // IP 기반 차단 규칙
    _accessRules['block_suspicious_ip'] = const AccessControlRule(
      id: 'block_suspicious_ip',
      name: '의심 IP 차단',
      conditions: {
        'ip_blacklist': ['192.168.1.100', '10.0.0.50'],
      },
      action: Action.deny,
      createdAt: DateTime.now(),
    );

    // 비정상적 로그인 시도 규칙
    _accessRules['limit_login_attempts'] = const AccessControlRule(
      id: 'limit_login_attempts',
      name: '로그인 시도 제한',
      conditions: {
        'max_attempts': 5,
        'time_window_minutes': 15,
      },
      action: Action.challenge,
      createdAt: DateTime.now(),
    );

    // 관리자 기업 접근 규칙
    _accessRules['admin_mfa'] = const AccessControlRule(
      id: 'admin_mfa',
      name: '관리자 MFA',
      conditions: {
        'user_role': 'admin',
      },
      action: Action.mfa,
      createdAt: DateTime.now(),
    );
  }

  void _startSecurityMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _monitorSecurity();
    });
  }

  /// 2FA 활성화
  Future<TwoFactorSettings> enableTwoFactor({
    required String userId,
    required TwoFactorType type,
  }) async {
    // 시크릿 키 생성 (TOTP용)
    final secretKey = _generateSecretKey();
    final backupCodes = _generateBackupCodes();

    final settings = TwoFactorSettings(
      userId: userId,
      isEnabled: true,
      type: type,
      secretKey: secretKey,
      backupCodes: backupCodes,
      enabledAt: DateTime.now(),
    );

    _twoFactorSettings[userId] = settings;

    // 이벤트 기록
    await _logEvent(SecurityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: SecurityEventType.twoFactorEnabled,
      userId: userId,
      description: '2FA 활성화: ${type.name}',
      threatLevel: ThreatLevel.none,
      timestamp: DateTime.now(),
    ));

    await _saveTwoFactorSettings(settings);

    debugPrint('[SecurityEnhancement] 2FA enabled: $userId');

    return settings;
  }

  /// 2FA 비활성화
  Future<void> disableTwoFactor({
    required String userId,
    required String code, // 확인용 코드
  }) async {
    final settings = _twoFactorSettings[userId];
    if (settings == null || !settings.isEnabled) {
      throw Exception('2FA not enabled');
    }

    // 코드 검증 (실제로는 2FA 코드 검증)
    if (!_verifyCode(userId, code)) {
      throw Exception('Invalid code');
    }

    final updated = TwoFactorSettings(
      userId: userId,
      isEnabled: false,
      type: settings.type,
      backupCodes: settings.backupCodes,
    );

    _twoFactorSettings[userId] = updated;

    await _logEvent(SecurityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: SecurityEventType.twoFactorDisabled,
      userId: userId,
      description: '2FA 비활성화',
      threatLevel: ThreatLevel.low,
      timestamp: DateTime.now(),
    ));

    await _saveTwoFactorSettings(updated);

    debugPrint('[SecurityEnhancement] 2FA disabled: $userId');
  }

  /// 2FA 코드 검증
  Future<bool> verifyTwoFactorCode({
    required String userId,
    required String code,
  }) async {
    final settings = _twoFactorSettings[userId];
    if (settings == null || !settings.isEnabled) {
      return false; // 2FA가 비활성화되어 있으면 통과
    }

    return _verifyCode(userId, code);
  }

  bool _verifyCode(String userId, String code) {
    final settings = _twoFactorSettings[userId];

    // 백업 코드 검증
    if (settings?.backupCodes.contains(code) ?? false) {
      return true;
    }

    // TOTP 검증 (실제로는 Time-based OTP 검증)
    // 시뮬레이션을 위해 6자리 숫자 확인
    if (code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code)) {
      return true;
    }

    return false;
  }

  /// 시크릿 키 생성
  String _generateSecretKey() {
    // 32바이트 Base64 인코딩
    final secret = pointy.SecureRandom(32).getBytes(32);
    return base64.encode(secret);
  }

  /// 백업 코드 생성
  List<String> _generateBackupCodes() {
    final codes = <String>[];
    final random = Random.secure();

    for (int i = 0; i < 10; i++) {
      final code = List.generate(8, (_) => random.nextInt(10)).join();
      codes.add(code);
    }

    return codes;
  }

  /// 데이터 암호화
  Future<EncryptedData> encryptData({
    required String data,
    EncryptionAlgorithm algorithm = EncryptionAlgorithm.aes256GCM,
    String? keyId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    switch (algorithm) {
      case EncryptionAlgorithm.aes256GCM:
        return await _encryptAES256GCM(data, keyId);

      default:
        throw Exception('Unsupported algorithm: ${algorithm.name}');
    }
  }

  /// AES-256-GCM 암호화
  Future<EncryptedData> _encryptAES256GCM(String data, String? keyId) async {
    // 키 생성 (실제로는 KMS에서 획득)
    final key = pointy.KeyParameter.fromRandom(
      secureRandom: pointy.SecureRandom(),
      keySize: 256,
    );
    final keyBytes = key.key.bytes;

    // 논스 생성
    final nonce = pointy.SecureRandom(12).getBytes(12);

    // 암호화 (실제로는 AES-GCM 구현)
    final encrypted = _performAESEncryption(data, keyBytes, nonce);

    final encryptedData = EncryptedData(
      id: 'encrypted_${DateTime.now().millisecondsSinceEpoch}',
      data: encrypted,
      nonce: base64.encode(nonce),
      algorithm: EncryptionAlgorithm.aes256GCM,
      encryptedAt: DateTime.now(),
    );

    _encryptedData[encryptedData.id] = encryptedData;

    await _logEvent(SecurityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: SecurityEventType.dataEncryption,
      userId: _currentUserId!,
      description: '데이터 암호화: ${encryptedData.id}',
      threatLevel: ThreatLevel.none,
      timestamp: DateTime.now(),
    ));

    debugPrint('[SecurityEnhancement] Data encrypted: ${encryptedData.id}');

    return encryptedData;
  }

  /// AES 암호화 수행 (시뮬레이션)
  String _performAESEncryption(String data, List<int> key, List<int> nonce) {
    // 실제 환경에서는 pointycastle 또는 flutter encrypt 사용
    // 여기서는 시뮬레이션
    return base64.encode(utf8.encode(data));
  }

  /// 데이터 복호화
  Future<String> decryptData(EncryptedData encryptedData) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    switch (encryptedData.algorithm) {
      case EncryptionAlgorithm.aes256GCM:
        return await _decryptAES256GCM(encryptedData);

      default:
        throw Exception('Unsupported algorithm: ${encryptedData.algorithm.name}');
    }
  }

  /// AES-256-GCM 복호화
  Future<String> _decryptAES256GCM(EncryptedData encryptedData) async {
    // 복호화 (실제로는 AES-GCM 복호화)
    final decrypted = _performAESDecryption(
      encryptedData.data,
      base64.decode(encryptedData.nonce),
    );

    await _logEvent(SecurityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: SecurityEventType.dataDecryption,
      userId: _currentUserId!,
      description: '데이터 복호화: ${encryptedData.id}',
      threatLevel: ThreatLevel.none,
      timestamp: DateTime.now(),
    ));

    debugPrint('[SecurityEnhancement] Data decrypted: ${encryptedData.id}');

    return decrypted;
  }

  /// AES 복호화 수행 (시뮬레이션)
  String _performAESDecryption(String encrypted, List<int> nonce) {
    // 실제 환경에서는 AES-GCM 복호화
    return utf8.decode(base64.decode(encrypted));
  }

  /// 비밀번호 해싱
  String hashPassword(String password, {String? salt}) {
    salt ??= _generateSalt();
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return salt + ':' + hash.toString();
  }

  /// 비밀번호 검증
  bool verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final hash = parts[1];

    final computedHash = hashPassword(password, salt: salt);
    return computedHash == hashedPassword;
  }

  /// 솔트 생성
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List.generate(32, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// 접근 제어 확인
  Future<Action> checkAccessControl({
    required String userId,
    required String resource,
    String? ipAddress,
    Map<String, dynamic>? context,
  }) async {
    for (final rule in _accessRules.values) {
      if (_evaluateRule(rule, userId, resource, ipAddress, context)) {
        return rule.action;
      }
    }

    return Action.allow; // 기본 허용
  }

  /// 규칙 평가
  bool _evaluateRule(
    AccessControlRule rule,
    String userId,
    String resource,
    String? ipAddress,
    Map<String, dynamic>? context,
  ) {
    final conditions = rule.conditions;

    // IP 블랙리스트 체크
    if (conditions.containsKey('ip_blacklist')) {
      final blacklist = conditions['ip_blacklist'] as List;
      if (ipAddress != null && blacklist.contains(ipAddress)) {
        return true;
      }
    }

    // 로그인 시도 제한 체크
    if (conditions.containsKey('max_attempts')) {
      final maxAttempts = conditions['max_attempts'] as int;
      final timeWindow = conditions['time_window_minutes'] as int;

      final recentAttempts = _securityEvents[userId]?.where((e) =>
          e.type == SecurityEventType.login &&
          DateTime.now().difference(e.timestamp).inMinutes <= timeWindow
      ).length ?? 0;

      if (recentAttempts >= maxAttempts) {
        return true;
      }
    }

    return false;
  }

  /// 보안 모니터링
  void _monitorSecurity() {
    // 의심스러운 활동 탐지
    final suspiciousEvents = _detectSuspiciousActivity();

    for (final event in suspiciousEvents) {
      _eventController.add(event);
      _threatController.add(event.threatLevel);

      // 심각 위협 시 계정 잠금
      if (event.threatLevel == ThreatLevel.critical) {
        _lockAccount(event.userId);
      }
    }
  }

  /// 의심스러운 활동 탐지
  List<SecurityEvent> _detectSuspiciousActivity() {
    final events = <SecurityEvent>[];

    // 최근 보안 이벤트 분석
    for (final userId in _securityEvents.keys) {
      final userEvents = _securityEvents[userId]!;
      final recentEvents = userEvents.where((e) =>
          DateTime.now().difference(e.timestamp).inHours <= 1).toList();

      // 다양한 위치에서 로그인
      final locations = recentEvents
          .where((e) => e.ipAddress != null)
          .map((e) => e.ipAddress!)
          .toSet();

      if (locations.length > 3) {
        events.add(SecurityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: SecurityEventType.suspiciousActivity,
          userId: userId,
          description: '여러 위치에서 로그인 감지',
          threatLevel: ThreatLevel.high,
          timestamp: DateTime.now(),
          metadata: {'locations': locations.toList()},
        ));
      }

      // 로그인 실패 반복
      final failedLogins = recentEvents
          .where((e) => e.type == SecurityEventType.login)
          .where((e) => e.threatLevel == ThreatLevel.medium)
          .length;

      if (failedLogins > 10) {
        events.add(SecurityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: SecurityEventType.suspiciousActivity,
          userId: userId,
          description: '반복적인 로그인 시도',
          threatLevel: ThreatLevel.medium,
          timestamp: DateTime.now(),
        ));
      }
    }

    return events;
  }

  /// 계정 잠금
  Future<void> _lockAccount(String userId) async {
    await _logEvent(SecurityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: SecurityEventType.accountLocked,
      userId: userId,
      description: '보안상의 이유로 계정 잠금',
      threatLevel: ThreatLevel.critical,
      timestamp: DateTime.now(),
    ));

    debugPrint('[SecurityEnhancement] Account locked: $userId');
  }

  /// 계정 잠금 해제
  Future<void> unlockAccount({
    required String userId,
    required String adminKey,
  }) async {
    // 관리자 키 검증 (실제로는 관리자 권한 확인)
    if (adminKey != 'ADMIN_SECRET_KEY') {
      throw Exception('Invalid admin key');
    }

    await _logEvent(SecurityEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: SecurityEventType.accountUnlocked,
      userId: userId,
      description: '관리자에 의해 계정 잠금 해제',
      threatLevel: ThreatLevel.none,
      timestamp: DateTime.now(),
    ));

    debugPrint('[SecurityEnhancement] Account unlocked: $userId');
  }

  /// 보안 이벤트 로그
  Future<void> _logEvent(SecurityEvent event) async {
    _securityEvents.putIfAbsent(event.userId, () => []).add(event);

    // 최대 1000개만 유지
    final events = _securityEvents[event.userId]!;
    if (events.length > 1000) {
      events.removeRange(0, events.length - 1000);
    }

    debugPrint('[SecurityEnhancement] Security event: ${event.type.name}');
  }

  /// 사용자 보안 점수
  double getSecurityScore(String userId) {
    final settings = _twoFactorSettings[userId];
    final events = _securityEvents[userId] ?? [];

    var score = 50.0; // 기본 점수

    // 2FA 활성화
    if (settings?.isEnabled ?? false) {
      score += 30;
    }

    // 최근 보안 이벤트 분석
    final recentEvents = events.where((e) =>
        DateTime.now().difference(e.timestamp).inDays <= 7).toList();

    final criticalEvents = recentEvents
        .where((e) => e.threatLevel == ThreatLevel.critical)
        .length;
    score -= criticalEvents * 20;

    final highEvents = recentEvents
        .where((e) => e.threatLevel == ThreatLevel.high)
        .length;
    score -= highEvents * 10;

    return score.clamp(0.0, 100.0);
  }

  /// 2FA 설정 조회
  TwoFactorSettings? getTwoFactorSettings(String userId) {
    return _twoFactorSettings[userId];
  }

  /// 보안 이벤트 조회
  List<SecurityEvent> getSecurityEvents(String userId, {int limit = 50}) {
    return (_securityEvents[userId] ?? []).take(limit).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 접근 제어 규칙 추가
  void addAccessRule(AccessControlRule rule) {
    _accessRules[rule.id] = rule;
    debugPrint('[SecurityEnhancement] Access rule added: ${rule.name}');
  }

  /// 접근 제어 규칙 제거
  void removeAccessRule(String ruleId) {
    _accessRules.remove(ruleId);
    debugPrint('[SecurityEnhancement] Access rule removed: $ruleId');
  }

  Future<void> _saveTwoFactorSettings(TwoFactorSettings settings) async {
    await _prefs?.setString(
      '2fa_${settings.userId}',
      jsonEncode({
        'isEnabled': settings.isEnabled,
        'type': settings.type.name,
        'enabledAt': settings.enabledAt?.toIso8601String(),
      }),
    );
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final totalUsers = _twoFactorSettings.length;
    final enabled2FA = _twoFactorSettings.values.where((s) => s.isEnabled).length;
    final totalEvents = _securityEvents.values.fold<int>(
        0, (sum, events) => sum + events.length);

    return {
      'totalUsers': totalUsers,
      'enabled2FA': enabled2FA,
      '2FAAdoptionRate': totalUsers > 0 ? enabled2FA / totalUsers : 0.0,
      'totalSecurityEvents': totalEvents,
      'activeRules': _accessRules.length,
    };
  }

  void dispose() {
    _eventController.close();
    _threatController.close();
    _monitoringTimer?.cancel();
  }
}

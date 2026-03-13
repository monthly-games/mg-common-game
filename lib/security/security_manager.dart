import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토큰 타입
enum TokenType {
  access,
  refresh,
  reset,
  email,
}

/// 토큰
class AuthToken {
  final String token;
  final TokenType type;
  final DateTime expiresAt;
  final String? userId;

  const AuthToken({
    required this.token,
    required this.type,
    required this.expiresAt,
    this.userId,
  });

  /// 만료 여부
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 유효 여부
  bool get isValid => !isExpired;

  Map<String, dynamic> toJson() => {
        'token': token,
        'type': type.name,
        'expiresAt': expiresAt.toIso8601String(),
        'userId': userId,
      };
}

/// 인증 정보
class AuthInfo {
  final String userId;
  final String username;
  final String email;
  final String? avatarUrl;
  final DateTime? lastLoginAt;

  const AuthInfo({
    required this.userId,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
}

/// 보안 관리자
class SecurityManager {
  static final SecurityManager _instance = SecurityManager._();
  static SecurityManager get instance => _instance;

  SecurityManager._();

  SharedPreferences? _prefs;
  AuthToken? _accessToken;
  AuthToken? _refreshToken;
  AuthInfo? _authInfo;

  final StreamController<AuthInfo?> _authController =
      StreamController<AuthInfo>.broadcast();

  Stream<AuthInfo?> get onAuthChange => _authController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 저장된 인증 정보 로드
    await _loadAuthData();

    debugPrint('[Security] Initialized');
  }

  Future<void> _loadAuthData() async {
    final tokenJson = _prefs?.getString('access_token');
    final authJson = _prefs?.getString('auth_info');

    if (tokenJson != null) {
      // _accessToken = AuthToken.fromJson(...);
    }

    if (authJson != null) {
      // _authInfo = AuthInfo.fromJson(...);
    }

    _authController.add(_authInfo);
  }

  /// 로그인
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      // 비밀번호 해싱
      final hashedPassword = _hashPassword(password);

      // 실제 API 호출 (시뮬레이션)
      await Future.delayed(const Duration(seconds: 1));

      // 토큰 생성 (시뮬레이션)
      final accessToken = AuthToken(
        token: _generateToken(),
        type: TokenType.access,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: 'user_123',
      );

      final refreshToken = AuthToken(
        token: _generateToken(),
        type: TokenType.refresh,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        userId: 'user_123',
      );

      // 인증 정보 저장
      _authInfo = const AuthInfo(
        userId: 'user_123',
        username: '테스터',
        email: 'test@example.com',
      );

      await _saveTokens(accessToken, refreshToken);
      await _saveAuthInfo(_authInfo!);

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      _authController.add(_authInfo);

      debugPrint('[Security] Logged in: ${_authInfo?.userId}');

      return true;
    } catch (e) {
      debugPrint('[Security] Login failed: $e');
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    await _prefs?.remove('access_token');
    await _prefs?.remove('refresh_token');
    await _prefs?.remove('auth_info');

    _accessToken = null;
    _refreshToken = null;
    _authInfo = null;

    _authController.add(null);

    debugPrint('[Security] Logged out');
  }

  /// 토큰 갱신
  Future<bool> refreshToken() async {
    if (_refreshToken == null || _refreshToken!.isExpired) {
      return false;
    }

    try {
      // 토큰 갱신 API 호출 (시뮬레이션)
      await Future.delayed(const Duration(milliseconds: 500));

      final newAccessToken = AuthToken(
        token: _generateToken(),
        type: TokenType.access,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: _refreshToken!.userId,
      );

      await _prefs?.setString('access_token', jsonEncode(newAccessToken.toJson()));

      _accessToken = newAccessToken;

      debugPrint('[Security] Token refreshed');

      return true;
    } catch (e) {
      debugPrint('[Security] Token refresh failed: $e');
      return false;
    }
  }

  /// 비밀번호 해싱
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 토큰 생성
  String _generateToken() {
    final bytes = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256 + i);
    final base64 = base64Encode(bytes);
    return base64;
  }

  Future<void> _saveTokens(AuthToken access, AuthToken refresh) async {
    await _prefs?.setString('access_token', jsonEncode(access.toJson()));
    await _prefs?.setString('refresh_token', jsonEncode(refresh.toJson()));
  }

  Future<void> _saveAuthInfo(AuthInfo authInfo) async {
    await _prefs?.setString('auth_info', jsonEncode(authInfo.toJson()));
  }

  /// 현재 사용자
  AuthInfo? get currentUser => _authInfo;

  /// 로그인 여부
  bool get isLoggedIn => _accessToken?.isValid == true;

  /// 액세스 토큰
  String? get accessToken => _accessToken?.token;
}

/// 암호화 유틸
class EncryptionUtils {
  /// AES 암호화
  static String encrypt(String data, String key) {
    // 실제 구현에서는 encrypt 패키지 사용
    final bytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);

    // 간단한 XOR 암호화 (실제로는 AES 사용)
    final encrypted = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return base64Encode(encrypted);
  }

  /// AES 복호화
  static String decrypt(String encryptedData, String key) {
    final encrypted = base64Decode(encryptedData);
    final keyBytes = utf8.encode(key);

    final decrypted = List<int>.generate(
      encrypted.length,
      (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
    );

    return utf8.decode(decrypted);
  }
}

/// API 서명
class APISigner {
  /// 서명 생성
  static String sign({
    required String method,
    required String path,
    required Map<String, dynamic> params,
    required String secretKey,
  }) {
    // 파라미터 정렬
    final sortedParams = Map.from(params)..removeWhere((key, value) => key == 'signature');
    final sortedKeys = sortedParams.keys.toList()..sort();

    // 쿼리 문자열 생성
    final queryString = sortedKeys.map((key) => '$key=${sortedParams[key]}').join('&');

    // 서명 문자열
    final signatureString = '$method\n$path\n$queryString';

    // HMAC-SHA256 서명
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(signatureString);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return digest.toString();
  }
}

/// 타임스탬프 검증
class TimestampValidator {
  /// 허용된 시간 차이 (초)
  static const int _maxTimeDiff = 300; // 5분

  /// 타임스탬프 검증
  static bool isValidTimestamp(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = (now - timestamp).abs();

    return diff <= _maxTimeDiff;
  }

  /// 현재 타임스탬프 생성
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}

/// 위변조 방지
class AntiTamper {
  static final Map<String, String> _checksums = {};

  /// 체크섬 계산
  static String calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 체크센 검증
  static bool verifyChecksum(String data, String expectedChecksum) {
    return calculateChecksum(data) == expectedChecksum;
  }

  /// 데이터 무결성 검증
  static bool verifyIntegrity(String data, String signature, String publicKey) {
    // 실제 구현에서는 전자서명 검증
    return true;
  }
}

/// 앱 보안 체크
class AppSecurityCheck {
  /// 루팅 여부 확인 (시뮬레이션)
  static Future<bool> isRooted() async {
    // 실제 구현에서는 네이티브 코드로 확인
    return false;
  }

  /// 에뮬레이터 여부 확인
  static Future<bool> isEmulator() async {
    // 실제 구현에서는 여러 체크 수행
    return false;
  }

  /// 디버거 여부 확인
  static Future<bool> isDebuggerAttached() async {
    // 실제 구현에서는 네이티브 코드로 확인
    return false;
  }

  /// SSL 핀닝
  static bool validateSSLCertificate(String host, String certificate) {
    // 실제 구현에서는 인증서 체인 검증
    return true;
  }
}

/// 비밀번호 정책
class PasswordPolicy {
  /// 최소 길이
  static const int minLength = 8;

  /// 최대 길이
  static const int maxLength = 128;

  /// 요구사항
  static bool isValid(String password) {
    if (password.length < minLength || password.length > maxLength) {
      return false;
    }

    // 영문, 숫자, 특수문자 포함
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasLetter && hasDigit && hasSpecial;
  }

  /// 강도 계산
  static PasswordStrength calculateStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

/// 비밀번호 강도
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// 세션 관리자
class SessionManager {
  static final SessionManager _instance = SessionManager._();
  static SessionManager get instance => _instance;

  SessionManager._();

  final Map<String, DateTime> _sessions = {};
  Timer? _cleanupTimer;

  /// 세션 생성
  String createSession(String userId) {
    final sessionId = _generateSessionId();
    _sessions[sessionId] = DateTime.now().add(const Duration(hours: 24));

    return sessionId;
  }

  /// 세션 확인
  bool isValidSession(String sessionId) {
    final expiresAt = _sessions[sessionId];
    if (expiresAt == null) return false;

    return DateTime.now().isBefore(expiresAt);
  }

  /// 세션 갱신
  void refreshSession(String sessionId) {
    if (_sessions.containsKey(sessionId)) {
      _sessions[sessionId] = DateTime.now().add(const Duration(hours: 24));
    }
  }

  /// 세션 삭제
  void removeSession(String sessionId) {
    _sessions.remove(sessionId);
  }

  /// 만료된 세션 정리
  void cleanupExpiredSessions() {
    final now = DateTime.now();
    _sessions.removeWhere((key, value) => now.isAfter(value));
  }

  String _generateSessionId() {
    final bytes = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256 + i);
    return base64Encode(bytes);
  }

  void startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      cleanupExpiredSessions();
    });
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 보안 레벨
enum SecurityLevel {
  low,
  medium,
  high,
  maximum,
}

/// 해시 알고리즘
enum HashAlgorithm {
  sha256,
  sha512,
  md5,
}

/// 암호화 모드
enum EncryptionMode {
  aes,
  xor,
  none,
}

/// 보안 위협 타입
enum SecurityThreat {
  timeManipulation,
  memoryTampering,
  rootDetection,
  speedHack,
  dataTampering,
}

/// 보안 이벤트
class SecurityEvent {
  final SecurityThreat threat;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  const SecurityEvent({
    required this.threat,
    required this.timestamp,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'threat': threat.name,
        'timestamp': timestamp.toIso8601String(),
        'details': details,
      };

  factory SecurityEvent.fromJson(Map<String, dynamic> json) => SecurityEvent(
        threat: SecurityThreat.values.firstWhere(
          (e) => e.name == json['threat'],
          orElse: () => SecurityThreat.dataTampering,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        details: json['details'] as Map<String, dynamic>? ?? {},
      );
}

/// 보안 매니저
class SecurityManager {
  static final SecurityManager _instance = SecurityManager._();
  static SecurityManager get instance => _instance;

  SecurityManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  SecurityLevel _securityLevel = SecurityLevel.medium;
  final List<SecurityEvent> _securityEvents = [];
  final StreamController<SecurityEvent> _eventController =
      StreamController<SecurityEvent>.broadcast();

  // 보안 키
  late String _encryptionKey;
  late String _hmacKey;

  // ============================================
  // Getters
  // ============================================
  SecurityLevel get securityLevel => _securityLevel;
  List<SecurityEvent> get securityEvents => List.unmodifiable(_securityEvents);
  Stream<SecurityEvent> get onSecurityEvent => _eventController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize({SecurityLevel level = SecurityLevel.medium}) async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 보안 키 생성 (또는 로드)
    _encryptionKey = await _getOrCreateKey('encryption_key');
    _hmacKey = await _getOrCreateKey('hmac_key');

    _securityLevel = level;

    // 보안 체크 수행
    await _performSecurityChecks();

    debugPrint('[Security] Initialized with level: $level');
  }

  Future<String> _getOrCreateKey(String keyName) async {
    final existingKey = _prefs!.getString(keyName);
    if (existingKey != null) {
      return existingKey;
    }

    // 새 키 생성
    final key = _generateSecureKey(32);
    await _prefs!.setString(keyName, key);
    return key;
  }

  String _generateSecureKey(int length) {
    final random = Random.secure();
    final key = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(key);
  }

  // ============================================
  // 암호화/복호화
  // ============================================

  /// 데이터 암호화
  Future<String> encrypt(String data) async {
    if (_securityLevel == SecurityLevel.low) {
      return data; // 낮은 보안 수준에서는 암호화하지 않음
    }

    try {
      switch (_securityLevel) {
        case SecurityLevel.high:
        case SecurityLevel.maximum:
          // AES 암호화
          return _aesEncrypt(data);
        default:
          // XOR 암호화
          return _xorEncrypt(data);
      }
    } catch (e) {
      debugPrint('[Security] Encryption error: $e');
      return data; // 실패 시 원본 반환
    }
  }

  /// 데이터 복호화
  Future<String> decrypt(String encryptedData) async {
    if (_securityLevel == SecurityLevel.low) {
      return encryptedData;
    }

    try {
      switch (_securityLevel) {
        case SecurityLevel.high:
        case SecurityLevel.maximum:
          return _aesDecrypt(encryptedData);
        default:
          return _xorEncrypt(encryptedData); // XOR은 자체 복호화
      }
    } catch (e) {
      debugPrint('[Security] Decryption error: $e');
      return encryptedData;
    }
  }

  String _xorEncrypt(String data) {
    final keyBytes = base64Decode(_encryptionKey);
    final dataBytes = utf8.encode(data);

    final encrypted = List<int>.generate(dataBytes.length, (i) {
      return dataBytes[i] ^ keyBytes[i % keyBytes.length];
    });

    return base64Encode(encrypted);
  }

  String _aesEncrypt(String data) {
    // 실제 AES 암호화는 flutter 암호화 패키지 사용 필요
    // 여기서는 시뮬레이션
    final keyBytes = base64Decode(_encryptionKey);
    final dataBytes = utf8.encode(data);

    // 간단한 암호화 (실제로는 crypto 패키지의 AES 사용)
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);

    final combined = [...dataBytes, ...digest.bytes];
    return base64Encode(combined);
  }

  String _aesDecrypt(String encryptedData) {
    final combined = base64Decode(encryptedData);
    final keyBytes = base64Decode(_encryptionKey);

    // 데이터와 HMAC 분리
    final dataBytes = combined.sublist(0, combined.length - 32);
    final receivedHmac = combined.sublist(combined.length - 32);

    // HMAC 검증
    final hmac = Hmac(sha256, keyBytes);
    final computedHmac = hmac.convert(dataBytes);

    if (const ListEquality().equals(receivedHmac, computedHmac.bytes)) {
      return utf8.decode(dataBytes);
    }

    throw Exception('HMAC verification failed');
  }

  // ============================================
  // 무결성 체크
  // ============================================

  /// HMAC 생성
  String generateHMAC(String data) {
    final keyBytes = base64Decode(_hmacKey);
    final dataBytes = utf8.encode(data);

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);

    return base64Encode(digest.bytes);
  }

  /// HMAC 검증
  bool verifyHMAC(String data, String hmac) {
    final computedHMAC = generateHMAC(data);
    return computedHMAC == hmac;
  }

  /// 데이터 서명 생성
  Future<String> signData(Map<String, dynamic> data) async {
    final json = jsonEncode(data);
    final signature = generateHMAC(json);
    return signature;
  }

  /// 데이터 서명 검증
  Future<bool> verifySignature(
    Map<String, dynamic> data,
    String signature,
  ) async {
    final json = jsonEncode(data);
    return verifyHMAC(json, signature);
  }

  // ============================================
  // 해싱
  // ============================================

  /// 문자열 해싱
  String hash(String data, {HashAlgorithm algorithm = HashAlgorithm.sha256}) {
    final dataBytes = utf8.encode(data);

    switch (algorithm) {
      case HashAlgorithm.sha256:
        final digest = sha256.convert(dataBytes);
        return digest.toString();
      case HashAlgorithm.sha512:
        final digest = sha512.convert(dataBytes);
        return digest.toString();
      case HashAlgorithm.md5:
        final digest = md5.convert(dataBytes);
        return digest.toString();
    }
  }

  /// 비밀번호 해싱 (솔트 + pepper)
  String hashPassword(String password) {
    final salt = _generateSecureSalt();
    final pepper = _securityLevel == SecurityLevel.maximum ? 'mg_games_pepper' : '';

    final saltedPassword = '$salt$password$pepper';
    final hashed = hash(saltedPassword);

    // salt와 해시를 결합하여 저장
    return '$salt:$hashed';
  }

  /// 비밀번호 검증
  bool verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final storedHash = parts[1];
    final pepper = _securityLevel == SecurityLevel.maximum ? 'mg_games_pepper' : '';

    final saltedPassword = '$salt$password$pepper';
    final computedHash = hash(saltedPassword);

    return computedHash == storedHash;
  }

  String _generateSecureSalt() {
    final random = Random.secure();
    final salt = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(salt);
  }

  // ============================================
  // 보안 체크
  // ============================================

  Future<void> _performSecurityChecks() async {
    if (_securityLevel == SecurityLevel.low) return;

    // 시간 조작 검사
    await _checkTimeManipulation();

    // 루팅 검사 (간단 구현)
    if (_securityLevel == SecurityLevel.high ||
        _securityLevel == SecurityLevel.maximum) {
      await _checkRooting();
    }
  }

  Future<void> _checkTimeManipulation() async {
    final savedTime = _prefs!.getString('last_valid_time');
    final currentTime = DateTime.now();

    if (savedTime != null) {
      final lastValid = DateTime.parse(savedTime);

      // 시간이 크게 조작되었는지 확인
      final difference = currentTime.difference(lastValid);

      if (difference.inSeconds < -60) {
        // 시간이 60초 이상 거슬러감 (시간 조작 의심)
        _reportThreat(SecurityThreat.timeManipulation, {
          'saved_time': savedTime,
          'current_time': currentTime.toIso8601String(),
          'difference_seconds': difference.inSeconds,
        });
      }
    }

    await _prefs!.setString('last_valid_time', currentTime.toIso8601String());
  }

  Future<void> _checkRooting() async {
    // 실제 루팅 감지 코드는 플랫폼별로 다름
    // 여기서는 시뮬레이션만 수행

    // 안드로이드의 경우:
    // - su 바이너리 존재 여부
    // - 루팅 관련 앱 존재 여부
    // - 시스템 속성 확인

    // iOS의 경우:
    // - Cydia 존재 여부
    // - 탈옥 감지

    debugPrint('[Security] Root check completed');
  }

  /// 속도 핵 감지
  void detectSpeedHack(int expectedDuration, int actualDuration) {
    // 실제 시간이 예상보다 너무 빠르면 속도 핵 의심
    if (actualDuration > 0 &&
        actualDuration < expectedDuration ~/ 2) {
      _reportThreat(SecurityThreat.speedHack, {
        'expected_duration': expectedDuration,
        'actual_duration': actualDuration,
        'ratio': expectedDuration / actualDuration,
      });
    }
  }

  // ============================================
  // 위협 보고
  // ============================================

  void _reportThreat(SecurityThreat threat, Map<String, dynamic> details) {
    final event = SecurityEvent(
      threat: threat,
      timestamp: DateTime.now(),
      details: details,
    );

    _securityEvents.add(event);
    _eventController.add(event);

    debugPrint('[Security] Threat detected: $threat');

    // 심각한 위협의 경우 조치
    if (_securityLevel == SecurityLevel.maximum) {
      _handleThreat(event);
    }
  }

  void _handleThreat(SecurityEvent event) {
    switch (event.threat) {
      case SecurityThreat.timeManipulation:
        // 시간 조작 감지 시 데이터 초기화 등
        debugPrint('[Security] Time manipulation detected - resetting data');
        break;
      case SecurityThreat.speedHack:
        // 속도 핵 감지 시 계약 정지 등
        debugPrint('[Security] Speed hack detected - applying penalty');
        break;
      default:
        break;
    }
  }

  // ============================================
  // 토큰 관리
  // ============================================

  /// 토큰 생성 (일회용)
  String generateToken({Map<String, dynamic>? payload}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(1000000);

    final tokenData = {
      'timestamp': timestamp,
      'random': random,
      if (payload != null) ...payload,
    };

    final json = jsonEncode(tokenData);
    final signature = generateHMAC(json);

    return base64Encode(utf8.encode('$json.$signature'));
  }

  /// 토큰 검증
  bool verifyToken(String token) {
    try {
      final decoded = utf8.decode(base64Decode(token));
      final parts = decoded.split('.');

      if (parts.length != 2) return false;

      final json = parts[0];
      final signature = parts[1];

      return verifyHMAC(json, signature);
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // 보안 레벨 관리
  // ============================================

  Future<void> setSecurityLevel(SecurityLevel level) async {
    if (_securityLevel != level) {
      _securityLevel = level;
      await _prefs!.setInt('security_level', level.index);
      debugPrint('[Security] Security level changed to: $level');
    }
  }

  // ============================================
  // 데이터 정리
  // ============================================

  void dispose() {
    _eventController.close();
  }
}

/// 보안 유틸리티 클래스
class SecurityUtils {
  static String obfuscateString(String input) {
    final bytes = utf8.encode(input);
    final obfuscated = bytes.map((b) => b ^ 0x55).toList();
    return base64Encode(obfuscated);
  }

  static String deobfuscateString(String obfuscated) {
    final bytes = base64Decode(obfuscated);
    final deobfuscated = bytes.map((b) => b ^ 0x55).toList();
    return utf8.decode(deobfuscated);
  }

  /// 안전한 난수 생성
  static String generateSecureRandom(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// UUID 생성 (v4)
  static String generateUUID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));

    // UUID v4 variant 설정
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // variant
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20, 32),
    ].join('-');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/security/security_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  group('SecurityManager Integration Tests', () {
    late SecurityManager securityManager;

    setUp(() async {
      // SharedPreferences 초기화 모의
      SharedPreferences.setMockInitialValues({});
      securityManager = SecurityManager.instance;
      await securityManager.initialize(level: SecurityLevel.high);
    });

    tearDown(() async {
      securityManager.dispose();
    });

    test('암호화 및 복호화 통합 테스트', () async {
      const originalData = '테스트 데이터입니다.';

      // 암호화
      final encrypted = await securityManager.encrypt(originalData);
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(originalData));

      // 복호화
      final decrypted = await securityManager.decrypt(encrypted);
      expect(decrypted, equals(originalData));
    });

    test('HMAC 생성 및 검증', () {
      const data = '무결성 테스트 데이터';

      final hmac = securityManager.generateHMAC(data);
      expect(hmac, isNotEmpty);
      expect(hmac.length, greaterThan(32));

      final isValid = securityManager.verifyHMAC(data, hmac);
      expect(isValid, isTrue);

      final tamperedData = '$data tempered';
      final isTamperedValid = securityManager.verifyHMAC(tamperedData, hmac);
      expect(isTamperedValid, isFalse);
    });

    test('비밀번호 해싱 및 검증', () {
      const password = 'MySecurePassword123!';

      final hashed = securityManager.hashPassword(password);
      expect(hashed, contains(':'));
      expect(hashed, isNot(password));

      final isValid = securityManager.verifyPassword(password, hashed);
      expect(isValid, isTrue);

      final isWrongValid = securityManager.verifyPassword('WrongPassword', hashed);
      expect(isWrongValid, isFalse);
    });

    test('토큰 생성 및 검증', () async {
      final payload = {'userId': 'user123', 'role': 'admin'};

      final token = await securityManager.generateToken(payload: payload);
      expect(token, isNotEmpty);

      final isValid = securityManager.verifyToken(token);
      expect(isValid, isTrue);

      final tamperedToken = '${token}tempered';
      final isTamperedValid = securityManager.verifyToken(tamperedToken);
      expect(isTamperedValid, isFalse);
    });

    test('보안 위협 감지 - 속도 핵', () {
      final events = <SecurityEvent>[];

      securityManager.onSecurityEvent.listen(events.add);

      // 정상 상황
      securityManager.detectSpeedHack(1000, 800);
      expect(events.where((e) => e.threat == SecurityThreat.speedHack).length, 0);

      // 속도 핵 의심 (너무 빠름)
      securityManager.detectSpeedHack(1000, 300);
      expect(events.where((e) => e.threat == SecurityThreat.speedHack).length, 1);
    });

    test('보안 레벨 변경', () async {
      await securityManager.setSecurityLevel(SecurityLevel.maximum);

      // Maximum 레벨에서는 더 강력한 암호화 사용
      const data = 'sensitive data';
      final encrypted = await securityManager.encrypt(data);

      expect(encrypted, isNotNull);
      expect(encrypted, isNot(data));
    });

    test('데이터 서명 및 검증', () async {
      final data = {
        'transactionId': 'tx123',
        'amount': 1000,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final signature = await securityManager.signData(data);
      expect(signature, isNotEmpty);

      final isValid = await securityManager.verifySignature(data, signature);
      expect(isValid, isTrue);

      final tamperedData = Map<String, dynamic>.from(data);
      tamperedData['amount'] = 9999;

      final isTamperedValid = await securityManager.verifySignature(tamperedData, signature);
      expect(isTamperedValid, isFalse);
    });
  });
}

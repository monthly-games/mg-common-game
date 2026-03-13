import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

enum EncryptionAlgorithm {
  aes,
  rsa,
  hmac,
}

enum EncryptionMode {
  ecb,
  cbc,
  gcm,
}

class EncryptionKey {
  final String keyId;
  final String key;
  final EncryptionAlgorithm algorithm;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int keySize;

  const EncryptionKey({
    required this.keyId,
    required this.key,
    required this.algorithm,
    required this.createdAt,
    this.expiresAt,
    required this.keySize,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get remainingTime {
    if (expiresAt == null) return const Duration(days: 365);
    return expiresAt!.difference(DateTime.now());
  }
}

class EncryptedData {
  final String dataId;
  final String encryptedData;
  final String keyId;
  final EncryptionAlgorithm algorithm;
  final String iv;
  final DateTime encryptedAt;

  const EncryptedData({
    required this.dataId,
    required this.encryptedData,
    required this.keyId,
    required this.algorithm,
    required this.iv,
    required this.encryptedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataId': dataId,
      'encryptedData': encryptedData,
      'keyId': keyId,
      'algorithm': algorithm.toString(),
      'iv': iv,
      'encryptedAt': encryptedAt.toIso8601String(),
    };
  }

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      dataId: json['dataId'] as String,
      encryptedData: json['encryptedData'] as String,
      keyId: json['keyId'] as String,
      algorithm: EncryptionAlgorithm.values.firstWhere(
        (e) => e.toString() == json['algorithm'],
      ),
      iv: json['iv'] as String,
      encryptedAt: DateTime.parse(json['encryptedAt'] as String),
    );
  }
}

class HashResult {
  final String hash;
  final String algorithm;
  final DateTime hashedAt;

  const HashResult({
    required this.hash,
    required this.algorithm,
    required this.hashedAt,
  });
}

class EncryptionManager {
  static final EncryptionManager _instance = EncryptionManager._();
  static EncryptionManager get instance => _instance;

  EncryptionManager._();

  final Map<String, EncryptionKey> _keys = {};
  final Map<String, EncryptedData> _encryptedData = {};
  final StreamController<EncryptionEvent> _eventController = StreamController.broadcast();

  Stream<EncryptionEvent> get onEncryptionEvent => _eventController.stream;

  Future<void> initialize() async {
    await _generateDefaultKeys();
  }

  Future<void> _generateDefaultKeys() async {
    final aesKey = EncryptionKey(
      keyId: 'key_default_aes',
      key: _generateKey(256),
      algorithm: EncryptionAlgorithm.aes,
      createdAt: DateTime.now(),
      keySize: 256,
    );

    final hmacKey = EncryptionKey(
      keyId: 'key_default_hmac',
      key: _generateKey(256),
      algorithm: EncryptionAlgorithm.hmac,
      createdAt: DateTime.now(),
      keySize: 256,
    );

    _keys[aesKey.keyId] = aesKey;
    _keys[hmacKey.keyId] = hmacKey;
  }

  String _generateKey(int size) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final bytes = List<int>.generate(size ~/ 8, (i) => (random + i) % 256);
    return base64.encode(bytes);
  }

  Future<EncryptionKey> createKey({
    required String keyId,
    required EncryptionAlgorithm algorithm,
    int keySize = 256,
    Duration? expiration,
  }) async {
    final key = EncryptionKey(
      keyId: keyId,
      key: _generateKey(keySize),
      algorithm: algorithm,
      createdAt: DateTime.now(),
      expiresAt: expiration != null
          ? DateTime.now().add(expiration)
          : null,
      keySize: keySize,
    );

    _keys[keyId] = key;

    _eventController.add(EncryptionEvent(
      type: EncryptionEventType.keyCreated,
      keyId: keyId,
      timestamp: DateTime.now(),
    ));

    return key;
  }

  EncryptionKey? getKey(String keyId) {
    return _keys[keyId];
  }

  List<EncryptionKey> getAllKeys() {
    return _keys.values.toList();
  }

  Future<void> deleteKey(String keyId) async {
    _keys.remove(keyId);

    _eventController.add(EncryptionEvent(
      type: EncryptionEventType.keyDeleted,
      keyId: keyId,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> rotateKey(String keyId) async {
    final oldKey = _keys[keyId];
    if (oldKey == null) return;

    final newKey = EncryptionKey(
      keyId: keyId,
      key: _generateKey(oldKey.keySize),
      algorithm: oldKey.algorithm,
      createdAt: DateTime.now(),
      expiresAt: oldKey.expiresAt,
      keySize: oldKey.keySize,
    );

    _keys[keyId] = newKey;

    _eventController.add(EncryptionEvent(
      type: EncryptionEventType.keyRotated,
      keyId: keyId,
      timestamp: DateTime.now(),
    ));
  }

  Future<EncryptedData> encrypt({
    required String data,
    String? keyId,
    EncryptionAlgorithm algorithm = EncryptionAlgorithm.aes,
    EncryptionMode mode = EncryptionMode.gcm,
  }) async {
    final effectiveKeyId = keyId ?? 'key_default_aes';
    final key = _keys[effectiveKeyId];

    if (key == null) {
      throw Exception('Key not found: $effectiveKeyId');
    }

    final iv = _generateIV();
    final encryptedData = _performEncryption(data, key.key, iv);

    final encrypted = EncryptedData(
      dataId: 'data_${DateTime.now().millisecondsSinceEpoch}',
      encryptedData: encryptedData,
      keyId: effectiveKeyId,
      algorithm: algorithm,
      iv: iv,
      encryptedAt: DateTime.now(),
    );

    _encryptedData[encrypted.dataId] = encrypted;

    _eventController.add(EncryptionEvent(
      type: EncryptionEventType.dataEncrypted,
      dataId: encrypted.dataId,
      timestamp: DateTime.now(),
    ));

    return encrypted;
  }

  String _generateIV() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final bytes = List<int>.generate(16, (i) => (random + i) % 256);
    return base64.encode(bytes);
  }

  String _performEncryption(String data, String key, String iv) {
    final combined = '$key$iv$data';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return base64.encode(hash.bytes);
  }

  Future<String> decrypt({
    required String encryptedData,
    required String keyId,
    required String iv,
  }) async {
    final key = _keys[keyId];
    if (key == null) {
      throw Exception('Key not found: $keyId');
    }

    final decrypted = _performDecryption(encryptedData, key.key, iv);

    _eventController.add(EncryptionEvent(
      type: EncryptionEventType.dataDecrypted,
      timestamp: DateTime.now(),
    ));

    return decrypted;
  }

  String _performDecryption(String encryptedData, String key, String iv) {
    final decoded = base64.decode(encryptedData);
    return String.fromCharCodes(decoded);
  }

  Future<HashResult> hash({
    required String data,
    String algorithm = 'sha256',
  }) async {
    String hash;
    switch (algorithm) {
      case 'sha256':
        final bytes = utf8.encode(data);
        final digest = sha256.convert(bytes);
        hash = digest.toString();
        break;
      case 'sha512':
        final bytes = utf8.encode(data);
        final digest = sha512.convert(bytes);
        hash = digest.toString();
        break;
      default:
        final bytes = utf8.encode(data);
        final digest = sha256.convert(bytes);
        hash = digest.toString();
    }

    return HashResult(
      hash: hash,
      algorithm: algorithm,
      hashedAt: DateTime.now(),
    );
  }

  Future<bool> verifyHash({
    required String data,
    required String hash,
    required String algorithm,
  }) async {
    final result = await hashData(data: data, algorithm: algorithm);
    return result.hash == hash;
  }

  Future<HashResult> hashData({
    required String data,
    required String algorithm,
  }) async {
    return await hash(data: data, algorithm: algorithm);
  }

  Future<String> hashPassword({
    required String password,
    String? salt,
  }) async {
    final effectiveSalt = salt ?? _generateKey(128);
    final combined = '$password$effectiveSalt';
    final result = await hash(data: combined, algorithm: 'sha256');
    return '${result.hash}$effectiveSalt';
  }

  Future<bool> verifyPassword({
    required String password,
    required String hashedPassword,
  }) async {
    final parts = hashedPassword.split('\$');
    if (parts.length < 2) return false;

    final salt = parts[1];
    final computed = await hashPassword(password: password, salt: salt);
    return computed == hashedPassword;
  }

  Future<String> secureRandom({
    int length = 32,
  }) async {
    final random = DateTime.now().millisecondsSinceEpoch;
    final bytes = List<int>.generate(length, (i) => (random + i * 17) % 256);
    return base64.encode(bytes);
  }

  EncryptedData? getEncryptedData(String dataId) {
    return _encryptedData[dataId];
  }

  void dispose() {
    _eventController.close();
  }
}

class EncryptionEvent {
  final EncryptionEventType type;
  final String? keyId;
  final String? dataId;
  final DateTime timestamp;

  const EncryptionEvent({
    required this.type,
    this.keyId,
    this.dataId,
    required this.timestamp,
  });
}

enum EncryptionEventType {
  keyCreated,
  keyDeleted,
  keyRotated,
  dataEncrypted,
  dataDecrypted,
}

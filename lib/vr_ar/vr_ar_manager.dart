import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math.dart';

/// XR 장치 타입
enum XRDeviceType {
  vrHeadset,          // VR 헤드셋
  ar Glasses,          // AR 글래스
  mobileAR,            // 모바일 AR
  none,                // 없음
}

/// XR 플랫폼
enum XRPlatform {
  oculus,              // Oculus
  htcVive,             // HTC Vive
  pico,                // Pico
  hololens,            // HoloLens
  magicLeap,           // Magic Leap
  arKit,               // Apple ARKit
  arCore,              // Google ARCore
  openXR,              // OpenXR
}

/// 추적 타입
enum TrackingType {
  none,                // 없음
  rotationOnly,        // 회전만
  positionAndRotation, // 위치 + 회전
  worldTracking,       // 월드 추적
}

/// 손 제스처
enum HandGesture {
  pinch,               // 집기
  grab,                // 잡기
  point,               // 가리키기
  thumbsUp,            // 엄지 척
  open,                // 손 펴기
  fist,                // 주먹
  wave,                // 손 흔들기
}

/// AR 앵커
class ARAnchor {
  final String id;
  final Vector3 position;
  final Quaternion rotation;
  final Vector3 scale;
  final String? attachedObjectId;
  final DateTime createdAt;
  final bool isTracked;

  const ARAnchor({
    required this.id,
    required this.position,
    required this.rotation,
    required this.scale,
    this.attachedObjectId,
    required this.createdAt,
    required this.isTracked,
  });
}

/// 3D 오브젝트
class ARObject {
  final String id;
  final String name;
  final String modelPath;
  final Vector3 position;
  final Quaternion rotation;
  final Vector3 scale;
  final bool isInteractable;
  final Map<String, dynamic> properties;

  const ARObject({
    required this.id,
    required this.name,
    required this.modelPath,
    required this.position,
    required this.rotation,
    required this.scale,
    required this.isInteractable,
    required this.properties,
  });

  ARObject copyWith({
    String? id,
    String? name,
    String? modelPath,
    Vector3? position,
    Quaternion? rotation,
    Vector3? scale,
    bool? isInteractable,
    Map<String, dynamic>? properties,
  }) {
    return ARObject(
      id: id ?? this.id,
      name: name ?? this.name,
      modelPath: modelPath ?? this.modelPath,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      isInteractable: isInteractable ?? this.isInteractable,
      properties: properties ?? this.properties,
    );
  }
}

/// 손 상태
class HandState {
  final HandGesture gesture;
  final Vector3 position;
  final Quaternion rotation;
  final double confidence; // 0.0 - 1.0
  final List<double> fingerCurls; // 5 fingers
  final DateTime timestamp;

  const HandState({
    required this.gesture,
    required this.position,
    required this.rotation,
    required this.confidence,
    required this.fingerCurls,
    required this.timestamp,
  });
}

/// 충격 피드백
class HapticFeedback {
  final double intensity; // 0.0 - 1.0
  final Duration duration;
  final double frequency; // Hz

  const HapticFeedback({
    required this.intensity,
    required this.duration,
    required this.frequency,
  });
}

/// 공간 오디오 소스
class SpatialAudioSource {
  final String id;
  final Vector3 position;
  final double volume; // 0.0 - 1.0
  final double minDistance;
  final double maxDistance;
  final bool isLooping;
  final String? assetPath;

  const SpatialAudioSource({
    required this.id,
    required this.position,
    required this.volume,
    required this.minDistance,
    required this.maxDistance,
    required this.isLooping,
    this.assetPath,
  });
}

/// VR/AR 관리자
class VRARManager {
  static final VRARManager _instance = VRARManager._();
  static VRARManager get instance => _instance;

  VRARManager._();

  SharedPreferences? _prefs;
  XRDeviceType _deviceType = XRDeviceType.none;
  XRPlatform _platform = XRPlatform.openXR;
  bool _isXRSupported = false;
  bool _isSessionActive = false;

  final Map<String, ARAnchor> _anchors = {};
  final Map<String, ARObject> _arObjects = {};
  final Map<String, SpatialAudioSource> _audioSources = {};

  HandState? _leftHandState;
  HandState? _rightHandState;

  final StreamController<bool> _sessionController =
      StreamController<bool>.broadcast();
  final StreamController<HandState> _handController =
      StreamController<HandState>.broadcast();
  final StreamController<ARAnchor> _anchorController =
      StreamController<ARAnchor>.broadcast();
  final StreamController<ARObject> _objectController =
      StreamController<ARObject>.broadcast();

  Stream<bool> get onSessionChange => _sessionController.stream;
  Stream<HandState> get onHandUpdate => _handController.stream;
  Stream<ARAnchor> get onAnchorUpdate => _anchorController.stream;
  Stream<ARObject> get onObjectUpdate => _objectController.stream;

  Timer? _trackingTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // XR 지원 확인
    await _checkXRSupport();

    // 설정 로드
    await _loadSettings();

    debugPrint('[VRAR] Initialized - Device: $_deviceType, Platform: $_platform');
  }

  /// XR 지원 확인
  Future<void> _checkXRSupport() async {
    // 실제 환경에서는 장치 확인
    // 시뮬레이션을 위해 mobileAR로 설정
    _deviceType = XRDeviceType.mobileAR;
    _platform = XRPlatform.arCore;
    _isXRSupported = true;
  }

  Future<void> _loadSettings() async {
    final settingsJson = _prefs?.getString('vr_ar_settings');
    if (settingsJson != null) {
      // 실제로는 파싱
    }
  }

  /// XR 세션 시작
  Future<bool> startXRSession() async {
    if (!_isXRSupported) {
      debugPrint('[VRAR] XR not supported');
      return false;
    }

    if (_isSessionActive) {
      debugPrint('[VRAR] Session already active');
      return false;
    }

    // 세션 초기화
    await _initializeSession();

    _isSessionActive = true;
    _sessionController.add(true);

    // 추적 시작
    _startTracking();

    debugPrint('[VRAR] Session started');

    return true;
  }

  /// 세션 초기화
  Future<void> _initializeSession() async {
    // 실제 환경에서는 ARKit/ARCore 초기화
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('[VRAR] Session initialized');
  }

  /// 추적 시작
  void _startTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updateTracking();
    });
  }

  /// 추적 업데이트
  Future<void> _updateTracking() async {
    if (!_isSessionActive) return;

    // 앵커 추적 상태 업데이트
    for (final anchor in _anchors.values) {
      // 실제 환경에서는 장치에서 추적 상태 수신
      final updated = ARAnchor(
        id: anchor.id,
        position: anchor.position,
        rotation: anchor.rotation,
        scale: anchor.scale,
        attachedObjectId: anchor.attachedObjectId,
        createdAt: anchor.createdAt,
        isTracked: Random().nextBool(), // 시뮬레이션
      );

      _anchors[anchor.id] = updated;
      _anchorController.add(updated);
    }

    // 손 추적 업데이트
    await _updateHandTracking();
  }

  /// 손 추적 업데이트
  Future<void> _updateHandTracking() async {
    if (_deviceType != XRDeviceType.vrHeadset &&
        _deviceType != XRDeviceType.arGlasses) {
      return;
    }

    // 왼손 업데이트
    if (Random().nextBool()) {
      final leftHand = HandState(
        gesture: HandGesture.values[Random().nextInt(HandGesture.values.length)],
        position: Vector3(-0.5, 1.0, -1.0),
        rotation: Quaternion.identity(),
        confidence: 0.8 + Random().nextDouble() * 0.2,
        fingerCurls: List.generate(5, (_) => Random().nextDouble()),
        timestamp: DateTime.now(),
      );

      _leftHandState = leftHand;
      _handController.add(leftHand);
    }

    // 오른손 업데이트
    if (Random().nextBool()) {
      final rightHand = HandState(
        gesture: HandGesture.values[Random().nextInt(HandGesture.values.length)],
        position: Vector3(0.5, 1.0, -1.0),
        rotation: Quaternion.identity(),
        confidence: 0.8 + Random().nextDouble() * 0.2,
        fingerCurls: List.generate(5, (_) => Random().nextDouble()),
        timestamp: DateTime.now(),
      );

      _rightHandState = rightHand;
      _handController.add(rightHand);
    }
  }

  /// XR 세션 중지
  Future<void> stopXRSession() async {
    if (!_isSessionActive) return;

    _trackingTimer?.cancel();

    // 세션 정리
    await _cleanupSession();

    _isSessionActive = false;
    _sessionController.add(false);

    debugPrint('[VRAR] Session stopped');
  }

  /// 세션 정리
  Future<void> _cleanupSession() async {
    // 앵커 제거
    _anchors.clear();

    debugPrint('[VRAR] Session cleaned up');
  }

  /// 앵커 추가
  Future<ARAnchor> addAnchor({
    required Vector3 position,
    required Quaternion rotation,
    Vector3? scale,
    String? attachedObjectId,
  }) async {
    if (!_isSessionActive) {
      throw Exception('XR session not active');
    }

    final anchorId = 'anchor_${DateTime.now().millisecondsSinceEpoch}';
    final anchor = ARAnchor(
      id: anchorId,
      position: position,
      rotation: rotation,
      scale: scale ?? Vector3.all(1.0),
      attachedObjectId: attachedObjectId,
      createdAt: DateTime.now(),
      isTracked: true,
    );

    _anchors[anchorId] = anchor;
    _anchorController.add(anchor);

    debugPrint('[VRAR] Anchor added: $anchorId');

    return anchor;
  }

  /// 앵커 제거
  Future<void> removeAnchor(String anchorId) async {
    _anchors.remove(anchorId);

    debugPrint('[VRAR] Anchor removed: $anchorId');
  }

  /// AR 오브젝트 배치
  Future<ARObject> placeARObject({
    required String modelPath,
    required Vector3 position,
    Quaternion? rotation,
    Vector3? scale,
    bool isInteractable = true,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isSessionActive) {
      throw Exception('XR session not active');
    }

    final objectId = 'object_${DateTime.now().millisecondsSinceEpoch}';
    final object = ARObject(
      id: objectId,
      name: objectId,
      modelPath: modelPath,
      position: position,
      rotation: rotation ?? Quaternion.identity(),
      scale: scale ?? Vector3.all(1.0),
      isInteractable: isInteractable,
      properties: properties ?? {},
    );

    _arObjects[objectId] = object;

    // 앵커에 연결
    await addAnchor(
      position: position,
      rotation: object.rotation,
      scale: object.scale,
      attachedObjectId: objectId,
    );

    _objectController.add(object);

    debugPrint('[VRAR] Object placed: $objectId');

    return object;
  }

  /// AR 오브젝트 이동
  Future<void> moveARObject({
    required String objectId,
    required Vector3 newPosition,
  }) async {
    final object = _arObjects[objectId];
    if (object == null) return;

    final updated = object.copyWith(position: newPosition);

    _arObjects[objectId] = updated;
    _objectController.add(updated);

    debugPrint('[VRAR] Object moved: $objectId');
  }

  /// AR 오브젝트 회전
  Future<void> rotateARObject({
    required String objectId,
    required Quaternion newRotation,
  }) async {
    final object = _arObjects[objectId];
    if (object == null) return;

    final updated = object.copyWith(rotation: newRotation);

    _arObjects[objectId] = updated;
    _objectController.add(updated);

    debugPrint('[VRAR] Object rotated: $objectId');
  }

  /// AR 오브젝트 제거
  Future<void> removeARObject(String objectId) async {
    _arObjects.remove(objectId);

    // 연결된 앵커 제거
    final anchorId = _anchors.entries
        .firstWhere((entry) => entry.value.attachedObjectId == objectId,
            orElse: () => MapEntry('', _anchors.values.first))
        .key;

    if (anchorId.isNotEmpty) {
      await removeAnchor(anchorId);
    }

    debugPrint('[VRAR] Object removed: $objectId');
  }

  /// 오브젝트 상호작용
  Future<bool> interactWithObject({
    required String objectId,
    required HandGesture gesture,
  }) async {
    final object = _arObjects[objectId];
    if (object == null || !object.isInteractable) {
      return false;
    }

    // 제스처에 따른 상호작용
    switch (gesture) {
      case HandGesture.grab:
        // 객체 잡기
        debugPrint('[VRAR] Object grabbed: $objectId');
        return true;
      case HandGesture.pinch:
        // 객체 조작
        debugPrint('[VRAR] Object pinched: $objectId');
        return true;
      case HandGesture.point:
        // 객체 선택
        debugPrint('[VRAR] Object pointed: $objectId');
        return true;
      default:
        return false;
    }
  }

  /// 충격 피드백 발생
  Future<void> triggerHaptic({
    required double intensity,
    Duration duration = const Duration(milliseconds: 100),
    double frequency = 50.0,
  }) async {
    if (!_isSessionActive) return;

    final feedback = HapticFeedback(
      intensity: intensity.clamp(0.0, 1.0),
      duration: duration,
      frequency: frequency,
    );

    // 실제 환경에서는 장치 API 호출
    debugPrint('[VRAR] Haptic triggered: ${feedback.intensity}');

    await Future.delayed(feedback.duration);
  }

  /// 공간 오디오 추가
  Future<SpatialAudioSource> addSpatialAudio({
    required Vector3 position,
    required double volume,
    double minDistance = 1.0,
    double maxDistance = 10.0,
    bool isLooping = false,
    String? assetPath,
  }) async {
    final audioId = 'audio_${DateTime.now().millisecondsSinceEpoch}';
    final source = SpatialAudioSource(
      id: audioId,
      position: position,
      volume: volume.clamp(0.0, 1.0),
      minDistance: minDistance,
      maxDistance: maxDistance,
      isLooping: isLooping,
      assetPath: assetPath,
    );

    _audioSources[audioId] = source;

    debugPrint('[VRAR] Spatial audio added: $audioId');

    return source;
  }

  /// 공간 오디오 업데이트
  Future<void> updateSpatialAudio({
    required String audioId,
    Vector3? newPosition,
    double? newVolume,
  }) async {
    final source = _audioSources[audioId];
    if (source == null) return;

    final updated = SpatialAudioSource(
      id: source.id,
      position: newPosition ?? source.position,
      volume: newVolume?.clamp(0.0, 1.0) ?? source.volume,
      minDistance: source.minDistance,
      maxDistance: source.maxDistance,
      isLooping: source.isLooping,
      assetPath: source.assetPath,
    );

    _audioSources[audioId] = source;

    debugPrint('[VRAR] Spatial audio updated: $audioId');
  }

  /// 공간 오디오 제거
  Future<void> removeSpatialAudio(String audioId) async {
    _audioSources.remove(audioId);

    debugPrint('[VRAR] Spatial audio removed: $audioId');
  }

  /// 평면 감지
  Future<List<Vector3>> detectPlanes() async {
    if (!_isSessionActive) return [];

    // 실제 환경에서는 ARKit/ARCore 평면 감지 API 호출
    await Future.delayed(const Duration(milliseconds: 500));

    // 시뮬레이션: 랜덤 평면 위치 반환
    return List.generate(3, (i) {
      return Vector3(
        (i - 1) * 2.0,
        0.0,
        -2.0 + Random().nextDouble(),
      );
    });
  }

  /// 레이캐스트
  Future<Vector3?> raycast({
    required Vector2 screenPosition,
    String? objectType,
  }) async {
    if (!_isSessionActive) return null;

    // 실제 환경에서는 ARKit/ARCore 레이캐스트 API 호출
    await Future.delayed(const Duration(milliseconds: 50));

    // 시뮬레이션: 랜덤 지점 반환
    return Vector3(
      Random().nextDouble() * 4.0 - 2.0,
      Random().nextDouble(),
      -2.0 + Random().nextDouble(),
    );
  }

  /// 조명 추정
  Future<Map<String, double>> estimateLighting() async {
    if (!_isSessionActive) return {};

    // 실제 환경에서는 카메라 프레임 분석
    await Future.delayed(const Duration(milliseconds: 100));

    return {
      'intensity': 0.7 + Random().nextDouble() * 0.3,
      'temperature': 5000 + Random().nextInt(2000),
      'ambient': 0.3 + Random().nextDouble() * 0.3,
    };
  }

  /// 장치 정보 조회
  Map<String, dynamic> getDeviceInfo() {
    return {
      'deviceType': _deviceType.name,
      'platform': _platform.name,
      'isSupported': _isXRSupported,
      'isSessionActive': _isSessionActive,
      'trackingType': _getTrackingType().name,
    };
  }

  /// 추적 타입 조회
  TrackingType _getTrackingType() {
    switch (_deviceType) {
      case XRDeviceType.vrHeadset:
        return TrackingType.positionAndRotation;
      case XRDeviceType.arGlasses:
      case XRDeviceType.mobileAR:
        return TrackingType.worldTracking;
      default:
        return TrackingType.none;
    }
  }

  /// 앵커 목록 조회
  List<ARAnchor> getAnchors() {
    return _anchors.values.toList();
  }

  /// 오브젝트 목록 조회
  List<ARObject> getARObjects() {
    return _arObjects.values.toList();
  }

  /// 손 상태 조회
  HandState? getLeftHandState() => _leftHandState;
  HandState? getRightHandState() => _rightHandState;

  /// 세션 활성 여부
  bool get isSessionActive => _isSessionActive;

  /// XR 지원 여부
  bool get isXRSupported => _isXRSupported;

  void dispose() {
    _trackingTimer?.cancel();
    _sessionController.close();
    _handController.close();
    _anchorController.close();
    _objectController.close();
  }
}

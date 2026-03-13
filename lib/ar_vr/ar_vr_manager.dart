import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// XR 모드 타입
enum XRMode {
  none,           // 없음
  ar,             // AR (증강현실)
  vr,             // VR (가상현실)
  mr,             // MR (혼합현실)
}

/// XR 디바이스 타입
enum XRDeviceType {
  mobileAr,       // 모바일 AR (ARCore, ARKit)
  vrHeadset,      // VR 헤드셋 (Oculus, Vive)
  arGlass,        // AR 글래스 (HoloLens, Glass)
  cardboard,      // Cardboard 스타일
  none,           // 없음
}

/// 추적 타입
enum TrackingType {
  none,           // 없음
  _3dof,          // 3DoF (3자유도)
  _6dof,          // 6DoF (6자유도)
  insideOut,      // Inside-out
  outsideIn,      // Outside-in
}

/// 컨트롤러 타입
enum ControllerType {
  none,           // 없음
  gaze,           // 시선 추적
  motion,         // 모션 컨트롤러
  hand,           // 손 추적
  voice,          // 음성
}

/// 포즈 데이터
class PoseData {
  final Vector3 position;
  final Quaternion rotation;
  final DateTime timestamp;

  const PoseData({
    required this.position,
    required this.rotation,
    required this.timestamp,
  });
}

/// 3D 벡터
class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  double get length => sqrt(x * x + y * y + z * z);
}

/// 쿼터니언
class Quaternion {
  final double x;
  final double y;
  final double z;
  final double w;

  const Quaternion(this.x, this.y, this.z, this.w);
}

/// AR 앵커
class ARAnchor {
  final String anchorId;
  final String name;
  final PoseData pose;
  final Map<String, dynamic>? metadata;

  const ARAnchor({
    required this.anchorId,
    required this.name,
    required this.pose,
    this.metadata,
  });
}

/// AR 플레인
class ARPlane {
  final String planeId;
  final PoseData centerPose;
  final Vector3 extent; // 가로, 세로, 높이
  final List<Vector3> boundary;

  const ARPlane({
    required this.planeId,
    required this.centerPose,
    required this.extent,
    required this.boundary,
  });
}

/// VR 렌더링 설정
class VRRenderSettings {
  final double targetFrameRate;
  final int renderResolution;
  final bool enableFoveatedRendering;
  final bool enablePostProcessing;
  final double fieldOfView;
  final double ipd; // Interpupillary Distance

  const VRRenderSettings({
    required this.targetFrameRate,
    required this.renderResolution,
    required this.enableFoveatedRendering,
    required this.enablePostProcessing,
    required this.fieldOfView,
    required this.ipd,
  });
}

/// AR 세션
class ARSession {
  final String sessionId;
  final DateTime startedAt;
  final ARTrackingQuality trackingQuality;
  final List<ARAnchor> anchors;
  final List<ARPlane> planes;

  const ARSession({
    required this.sessionId,
    required this.startedAt,
    required this.trackingQuality,
    required this.anchors,
    required this.planes,
  });
}

/// 추적 품질
enum ARTrackingQuality {
  notAvailable,   // 사용 불가
  poor,           // 나쁨
  medium,         // 보통
  good,           // 좋음
  excellent,      // 매우 좋음
}

/// 레이캐스트 결과
class ARRaycastResult {
  final String resultId;
  final PoseData pose;
  final double distance;
  final String? anchorId;

  const ARRaycastResult({
    required this.resultId,
    required this.pose,
    required this.distance,
    this.anchorId,
  });
}

/// XR 모드 관리자
class ARVRManager {
  static final ARVRManager _instance = ARVRManager._();
  static ARVRManager get instance => _instance;

  ARVRManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  XRMode _currentMode = XRMode.none;
  XRDeviceType? _deviceType;
  TrackingType _trackingType = TrackingType.none;
  ControllerType _controllerType = ControllerType.none;

  ARSession? _currentARSession;
  PoseData? _headPose;
  PoseData? _leftControllerPose;
  PoseData? _rightControllerPose;

  VRRenderSettings? _vrSettings;

  final StreamController<XRMode> _modeController =
      StreamController<XRMode>.broadcast();
  final StreamController<PoseData> _headPoseController =
      StreamController<PoseData>.broadcast();
  final StreamController<ARSession> _arSessionController =
      StreamController<ARSession>.broadcast();

  Stream<XRMode> get onModeChange => _modeController.stream;
  Stream<PoseData> get onHeadPoseUpdate => _headPoseController.stream;
  Stream<ARSession> get onARSessionUpdate => _arSessionController.stream;

  Timer? _poseUpdateTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 디바이스 감지
    await _detectDevice();

    // 설정 로드
    await _loadSettings();

    debugPrint('[ARVR] Initialized: ${_currentMode.name}');
  }

  Future<void> _detectDevice() async {
    // 실제로는 platform_info, device_info_plus 등 사용
    // 여기서는 시뮬레이션
    _deviceType = XRDeviceType.mobileAr;
    _trackingType = TrackingType._6dof;
    _controllerType = ControllerType.gaze;
  }

  Future<void> _loadSettings() async {
    _vrSettings = const VRRenderSettings(
      targetFrameRate: 90,
      renderResolution: 2160,
      enableFoveatedRendering: true,
      enablePostProcessing: true,
      fieldOfView: 100,
      ipd: 0.064, // 평균 동간 거리 (m)
    );
  }

  /// XR 모드 설정
  Future<bool> setXRMode(XRMode mode) async {
    if (_currentMode == mode) return true;

    // 모드 전환 전 정리
    if (_currentMode != XRMode.none) {
      await _stopCurrentSession();
    }

    _currentMode = mode;

    // 모드별 초기화
    switch (mode) {
      case XRMode.ar:
        await _startARSession();
        break;

      case XRMode.vr:
        await _startVRSession();
        break;

      case XRMode.mr:
        await _startMRSession();
        break;

      case XRMode.none:
        break;
    }

    _modeController.add(mode);

    await _prefs?.setString('xr_mode', mode.name);

    debugPrint('[ARVR] Mode changed: ${mode.name}');

    return true;
  }

  /// 현재 모드
  XRMode get currentMode => _currentMode;

  /// 디바이스 타입
  XRDeviceType? get deviceType => _deviceType;

  /// 추적 타입
  TrackingType get trackingType => _trackingType;

  /// AR 세션 시작
  Future<void> _startARSession() async {
    final session = ARSession(
      sessionId: 'ar_${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now(),
      trackingQuality: ARTrackingQuality.medium,
      anchors: [],
      planes: [],
    );

    _currentARSession = session;
    _arSessionController.add(session);

    // 포즈 업데이트 시작
    _startPoseUpdates();

    debugPrint('[ARVR] AR session started');
  }

  /// VR 세션 시작
  Future<void> _startVRSession() async {
    // VR 초기화
    _startPoseUpdates();

    debugPrint('[ARVR] VR session started');
  }

  /// MR 세션 시작
  Future<void> _startMRSession() async {
    // MR 초기화
    _startPoseUpdates();

    debugPrint('[ARVR] MR session started');
  }

  /// 현재 세션 종료
  Future<void> _stopCurrentSession() async {
    _poseUpdateTimer?.cancel();
    _currentARSession = null;
    _headPose = null;
    _leftControllerPose = null;
    _rightControllerPose = null;

    debugPrint('[ARVR] Session stopped');
  }

  void _startPoseUpdates() {
    _poseUpdateTimer?.cancel();
    _poseUpdateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updatePoses();
    });
  }

  void _updatePoses() {
    // 실제로는 디바이스 센서에서 포즈 데이터 가져옴
    // 여기서는 시뮬레이션

    final headPose = PoseData(
      position: Vector3(
        Random().nextDouble() * 0.1,
        Random().nextDouble() * 0.1,
        Random().nextDouble() * 0.1,
      ),
      rotation: Quaternion(
        Random().nextDouble(),
        Random().nextDouble(),
        Random().nextDouble(),
        Random().nextDouble(),
      ),
      timestamp: DateTime.now(),
    );

    _headPose = headPose;
    _headPoseController.add(headPose);

    // AR 추적 품질 업데이트
    if (_currentARSession != null) {
      final updated = ARSession(
        sessionId: _currentARSession!.sessionId,
        startedAt: _currentARSession!.startedAt,
        trackingQuality: _simulateTrackingQuality(),
        anchors: _currentARSession!.anchors,
        planes: _currentARSession!.planes,
      );

      _currentARSession = updated;
      _arSessionController.add(updated);
    }
  }

  ARTrackingQuality _simulateTrackingQuality() {
    final random = Random().nextDouble();

    if (random < 0.1) return ARTrackingQuality.poor;
    if (random < 0.3) return ARTrackingQuality.medium;
    if (random < 0.7) return ARTrackingQuality.good;
    return ARTrackingQuality.excellent;
  }

  /// 현재 헤드 포즈
  PoseData? get headPose => _headPose;

  /// 레이캐스트
  Future<ARRaycastResult?> raycast({
    required Vector3 origin,
    required Vector3 direction,
  }) async {
    if (_currentMode != XRMode.ar || _currentARSession == null) {
      return null;
    }

    // 실제로는 AR 플랫폼의 raycast 함수 호출
    // 여기서는 시뮬레이션

    final result = ARRaycastResult(
      resultId: 'raycast_${DateTime.now().millisecondsSinceEpoch}',
      pose: PoseData(
        position: origin + direction * 2.0,
        rotation: const Quaternion(0, 0, 0, 1),
        timestamp: DateTime.now(),
      ),
      distance: 2.0,
    );

    return result;
  }

  /// 앵커 추가
  Future<ARAnchor?> addAnchor({
    required PoseData pose,
    String? name,
  }) async {
    if (_currentARSession == null) return null;

    final anchor = ARAnchor(
      anchorId: 'anchor_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Anchor',
      pose: pose,
    );

    final updated = ARSession(
      sessionId: _currentARSession!.sessionId,
      startedAt: _currentARSession!.startedAt,
      trackingQuality: _currentARSession!.trackingQuality,
      anchors: [..._currentARSession!.anchors, anchor],
      planes: _currentARSession!.planes,
    );

    _currentARSession = updated;
    _arSessionController.add(updated);

    return anchor;
  }

  /// 앵커 제거
  Future<bool> removeAnchor(String anchorId) async {
    if (_currentARSession == null) return false;

    final anchors = _currentARSession!.anchors
        .where((a) => a.anchorId != anchorId)
        .toList();

    final updated = ARSession(
      sessionId: _currentARSession!.sessionId,
      startedAt: _currentARSession!.startedAt,
      trackingQuality: _currentARSession!.trackingQuality,
      anchors: anchors,
      planes: _currentARSession!.planes,
    );

    _currentARSession = updated;
    _arSessionController.add(updated);

    return true;
  }

  /// 플레인 감지
  Future<List<ARPlane>> detectPlanes() async {
    if (_currentMode != XRMode.ar || _currentARSession == null) {
      return [];
    }

    // 실제로는 AR 플랫폼의 플레인 감지 함수 호출
    // 여기서는 시뮬레이션

    final planes = [
      ARPlane(
        planeId: 'plane_1',
        centerPose: PoseData(
          position: const Vector3(0, 0, -2),
          rotation: const Quaternion(0, 0, 0, 1),
          timestamp: DateTime.now(),
        ),
        extent: const Vector3(2, 0, 2),
        boundary: const [],
      ),
    ];

    final updated = ARSession(
      sessionId: _currentARSession!.sessionId,
      startedAt: _currentARSession!.startedAt,
      trackingQuality: _currentARSession!.trackingQuality,
      anchors: _currentARSession!.anchors,
      planes: planes,
    );

    _currentARSession = updated;
    _arSessionController.add(updated);

    return planes;
  }

  /// VR 렌더링 설정
  VRRenderSettings? get vrRenderSettings => _vrSettings;

  /// VR 렌더링 설정 업데이트
  Future<void> updateVRSettings(VRRenderSettings settings) async {
    _vrSettings = settings;

    await _prefs?.setString('vr_settings', jsonEncode({
      'targetFrameRate': settings.targetFrameRate,
      'renderResolution': settings.renderResolution,
      'enableFoveatedRendering': settings.enableFoveatedRendering,
    }));
  }

  /// 컨트롤러 포즈
  PoseData? get leftControllerPose => _leftControllerPose;
  PoseData? get rightControllerPose => _rightControllerPose;

  /// AR 세션
  ARSession? get arSession => _currentARSession;

  /// XR 지원 여부
  bool get isXRSupported {
    return _deviceType != null && _deviceType != XRDeviceType.none;
  }

  /// AR 지원 여부
  bool get isARSupported {
    return _deviceType == XRDeviceType.mobileAr ||
        _deviceType == XRDeviceType.arGlass;
  }

  /// VR 지원 여부
  bool get isVRSupported {
    return _deviceType == XRDeviceType.vrHeadset;
  }

  void dispose() {
    _modeController.close();
    _headPoseController.close();
    _arSessionController.close();
    _poseUpdateTimer?.cancel();
  }
}

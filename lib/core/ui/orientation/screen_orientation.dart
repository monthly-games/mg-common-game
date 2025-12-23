import 'package:flutter/services.dart';

/// MG-Games 화면 방향 시스템
/// SCREEN_ORIENTATION_GUIDE.md 기반
class MGScreenOrientation {
  MGScreenOrientation._();

  // ============================================================
  // 화면 방향 유형
  // ============================================================

  /// Portrait 전용 (46개 게임)
  static const List<DeviceOrientation> portrait = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  /// Portrait Up만 (portrait + notch 위쪽 고정)
  static const List<DeviceOrientation> portraitUp = [
    DeviceOrientation.portraitUp,
  ];

  /// Landscape 전용 (4개 게임)
  static const List<DeviceOrientation> landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  /// Flexible (Portrait + Landscape, 2개 게임)
  static const List<DeviceOrientation> flexible = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  // ============================================================
  // 게임별 화면 방향 설정
  // ============================================================

  /// 게임 ID별 화면 방향 반환
  static List<DeviceOrientation> getOrientationForGame(String gameId) {
    // Landscape 게임 (4개)
    const landscapeGames = {
      '0014', // Tactical RPG
      '0023', // Racing
      '0038', // Fighting
      '0052', // Sports
    };

    // Flexible 게임 (2개)
    const flexibleGames = {
      '0013', // Board Game
      '0022', // Card Battle
    };

    if (landscapeGames.contains(gameId)) {
      return landscape;
    } else if (flexibleGames.contains(gameId)) {
      return flexible;
    } else {
      return portrait;
    }
  }

  /// 게임 ID에 해당하는 방향 타입 반환
  static OrientationType getOrientationType(String gameId) {
    const landscapeGames = {'0014', '0023', '0038', '0052'};
    const flexibleGames = {'0013', '0022'};

    if (landscapeGames.contains(gameId)) {
      return OrientationType.landscape;
    } else if (flexibleGames.contains(gameId)) {
      return OrientationType.flexible;
    } else {
      return OrientationType.portrait;
    }
  }

  // ============================================================
  // 시스템 설정 헬퍼
  // ============================================================

  /// 화면 방향 설정 적용
  static Future<void> setOrientation(List<DeviceOrientation> orientations) {
    return SystemChrome.setPreferredOrientations(orientations);
  }

  /// 게임 ID로 화면 방향 설정
  static Future<void> setOrientationForGame(String gameId) {
    final orientations = getOrientationForGame(gameId);
    return setOrientation(orientations);
  }

  /// Portrait 설정
  static Future<void> setPortrait() {
    return setOrientation(portrait);
  }

  /// Landscape 설정
  static Future<void> setLandscape() {
    return setOrientation(landscape);
  }

  /// Flexible 설정
  static Future<void> setFlexible() {
    return setOrientation(flexible);
  }

  /// 모든 방향 허용 (초기화)
  static Future<void> reset() {
    return SystemChrome.setPreferredOrientations([]);
  }

  // ============================================================
  // 풀스크린 모드
  // ============================================================

  /// 풀스크린 모드 활성화 (상태바, 네비게이션 숨김)
  static Future<void> enableFullscreen() {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  /// 풀스크린 해제
  static Future<void> disableFullscreen() {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  /// 게임 시작 시 권장 설정 (풀스크린 + 방향 고정)
  static Future<void> setupForGame(String gameId) async {
    await setOrientationForGame(gameId);
    await enableFullscreen();
  }

  /// 게임 종료 시 설정 초기화
  static Future<void> cleanup() async {
    await reset();
    await disableFullscreen();
  }
}

/// 화면 방향 유형
enum OrientationType {
  /// 세로 고정 (46개 게임)
  portrait,

  /// 가로 고정 (4개 게임)
  landscape,

  /// 세로/가로 모두 지원 (2개 게임)
  flexible,
}

/// 화면 방향 유형 확장
extension OrientationTypeExtension on OrientationType {
  /// 방향 타입 이름 (한글)
  String get nameKr {
    switch (this) {
      case OrientationType.portrait:
        return '세로 고정';
      case OrientationType.landscape:
        return '가로 고정';
      case OrientationType.flexible:
        return '세로/가로 모두';
    }
  }

  /// 방향 타입 이름 (영문)
  String get nameEn {
    switch (this) {
      case OrientationType.portrait:
        return 'Portrait';
      case OrientationType.landscape:
        return 'Landscape';
      case OrientationType.flexible:
        return 'Flexible';
    }
  }

  /// 해당 DeviceOrientation 목록
  List<DeviceOrientation> get orientations {
    switch (this) {
      case OrientationType.portrait:
        return MGScreenOrientation.portrait;
      case OrientationType.landscape:
        return MGScreenOrientation.landscape;
      case OrientationType.flexible:
        return MGScreenOrientation.flexible;
    }
  }

  /// 현재 Portrait 모드인지
  bool get isPortrait => this == OrientationType.portrait;

  /// 현재 Landscape 모드인지
  bool get isLandscape => this == OrientationType.landscape;

  /// 현재 Flexible 모드인지
  bool get isFlexible => this == OrientationType.flexible;
}

/// 게임별 방향 설정 상세 정보
class GameOrientationInfo {
  final String gameId;
  final String gameName;
  final OrientationType orientationType;
  final String reason;

  const GameOrientationInfo({
    required this.gameId,
    required this.gameName,
    required this.orientationType,
    required this.reason,
  });

  /// Landscape 게임 목록
  static const List<GameOrientationInfo> landscapeGames = [
    GameOrientationInfo(
      gameId: '0014',
      gameName: 'Tactical RPG',
      orientationType: OrientationType.landscape,
      reason: '전술 맵 표시를 위한 넓은 화면 필요',
    ),
    GameOrientationInfo(
      gameId: '0023',
      gameName: 'Racing',
      orientationType: OrientationType.landscape,
      reason: '레이싱 트랙의 넓은 시야 확보',
    ),
    GameOrientationInfo(
      gameId: '0038',
      gameName: 'Fighting',
      orientationType: OrientationType.landscape,
      reason: '1:1 대전 화면 구성',
    ),
    GameOrientationInfo(
      gameId: '0052',
      gameName: 'Sports',
      orientationType: OrientationType.landscape,
      reason: '스포츠 필드 전체 표시',
    ),
  ];

  /// Flexible 게임 목록
  static const List<GameOrientationInfo> flexibleGames = [
    GameOrientationInfo(
      gameId: '0013',
      gameName: 'Board Game',
      orientationType: OrientationType.flexible,
      reason: '보드 게임 테이블 다양한 방향 지원',
    ),
    GameOrientationInfo(
      gameId: '0022',
      gameName: 'Card Battle',
      orientationType: OrientationType.flexible,
      reason: '카드 배치 유연성 제공',
    ),
  ];
}

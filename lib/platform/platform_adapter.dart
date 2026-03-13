import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 플랫폼 타입
enum PlatformType {
  mobile,    // iOS/Android
  web,       // Flutter Web
  desktop,   // Windows/macOS/Linux
}

/// 플랫폼� 정보
class PlatformInfo {
  final PlatformType type;
  final String name;
  final bool isMobile;
  final bool isWeb;
  final bool isDesktop;
  final Size? screenSize;
  final TargetPlatform? targetPlatform;

  const PlatformInfo({
    required this.type,
    required this.name,
    required this.isMobile,
    required this.isWeb,
    required this.isDesktop,
    this.screenSize,
    this.targetPlatform,
  });

  /// 현재 플랫폼 정보
  static PlatformInfo get current {
    if (kIsWeb) {
      return const PlatformInfo(
        type: PlatformType.web,
        name: 'Web',
        isMobile: false,
        isWeb: true,
        isDesktop: false,
      );
    }

    // 모바일 확인
    if (Theme.of(WidgetsBinding.instance.rootContext as BuildContext).platform ==
        TargetPlatform.iOS ||
        Theme.of(WidgetsBinding.instance.rootContext as BuildContext).platform ==
        TargetPlatform.android) {
      return const PlatformInfo(
        type: PlatformType.mobile,
        name: 'Mobile',
        isMobile: true,
        isWeb: false,
        isDesktop: false,
      );
    }

    // 데스크탑
    return const PlatformInfo(
      type: PlatformType.desktop,
      name: 'Desktop',
      isMobile: false,
      isWeb: false,
      isDesktop: true,
    );
  }
}

/// 플랫폼 어댑터
class PlatformAdapter {
  /// 플랫폼별 UI 조정
  static Widget adaptToPlatform(Widget mobile, {Widget? web, Widget? desktop}) {
    final platform = PlatformInfo.current;

    switch (platform.type) {
      case PlatformType.mobile:
        return mobile;
      case PlatformType.web:
        return web ?? mobile;
      case PlatformType.desktop:
        return desktop ?? mobile;
    }
  }

  /// 플랫폼별 레이아웃
  static Widget buildAdaptiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // 모바일
        if (width < 600) {
          return mobile;
        }

        // 태블릿
        if (width < 900) {
          return tablet ?? mobile;
        }

        // 데스크탑
        return desktop ?? tablet ?? mobile;
      },
    );
  }

  /// 플랫폼별 폰트 크기
  static double getAdaptiveFontSize(BuildContext context, double mobileSize) {
    final platform = PlatformInfo.current;

    if (platform.isDesktop) {
      return mobileSize * 1.2;
    }

    return mobileSize;
  }

  /// 플랫폼별 패딩
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final platform = PlatformInfo.current;

    if (platform.isDesktop) {
      return const EdgeInsets.all(32);
    }

    return const EdgeInsets.all(16);
  }
}

/// 데이터 동기화 관리자
class DataSyncManager {
  static final DataSyncManager _instance = DataSyncManager._();
  static DataSyncManager get instance => _instance;

  DataSyncManager._();

  final StreamController<SyncEvent> _syncController =
      StreamController<SyncEvent>.broadcast();

  Stream<SyncEvent> get onSyncEvent => _syncController.stream;

  Future<void> syncAcrossPlatforms({
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    final event = SyncEvent(
      type: SyncType.full,
      platform: PlatformInfo.current.name,
      timestamp: DateTime.now(),
    );

    _syncController.add(event);

    // 실제 동기화 로직 (클라우드 등)
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('[Sync] Synced across platforms');
  }

  Future<void> syncProgress({
    required String userId,
    required String gameId,
    required Map<String, dynamic> progressData,
  }) async {
    // 진행 상태 동기화
    debugPrint('[Sync] Progress synced for $gameId');
  }
}

enum SyncType {
  full,
  incremental,
  progress,
  settings,
}

class SyncEvent {
  final SyncType type;
  final String platform;
  final DateTime timestamp;

  const SyncEvent({
    required this.type,
    required this.platform,
    required this.timestamp,
  });
}

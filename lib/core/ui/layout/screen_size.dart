import 'package:flutter/material.dart';

/// MG-Games 화면 크기 유틸리티
/// UI_UX_MASTER_GUIDE.md 기반

/// 화면 크기 분류
enum ScreenSize {
  /// 컴팩트 (0 ~ 599dp)
  /// 대부분의 스마트폰
  compact,

  /// 미디엄 (600 ~ 839dp)
  /// 태블릿 세로, 폴더블
  medium,

  /// 확장 (840dp ~)
  /// 태블릿 가로, 데스크톱
  expanded,
}

extension ScreenSizeExtension on ScreenSize {
  /// 최소 너비
  double get minWidth {
    switch (this) {
      case ScreenSize.compact:
        return 0;
      case ScreenSize.medium:
        return 600;
      case ScreenSize.expanded:
        return 840;
    }
  }

  /// 그리드 컬럼 수
  int get columns {
    switch (this) {
      case ScreenSize.compact:
        return 4;
      case ScreenSize.medium:
        return 8;
      case ScreenSize.expanded:
        return 12;
    }
  }

  /// 마진
  double get margin {
    switch (this) {
      case ScreenSize.compact:
        return 16;
      case ScreenSize.medium:
        return 24;
      case ScreenSize.expanded:
        return 32;
    }
  }

  /// 거터 (컬럼 간격)
  double get gutter {
    switch (this) {
      case ScreenSize.compact:
        return 16;
      case ScreenSize.medium:
        return 24;
      case ScreenSize.expanded:
        return 24;
    }
  }
}

/// 화면 크기 유틸리티
class MGScreenSize {
  MGScreenSize._();

  // ============================================================
  // 브레이크포인트
  // ============================================================

  /// 미디엄 브레이크포인트
  static const double mediumBreakpoint = 600;

  /// 확장 브레이크포인트
  static const double expandedBreakpoint = 840;

  // ============================================================
  // 화면 크기 감지
  // ============================================================

  /// 현재 화면 크기 분류
  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return fromWidth(width);
  }

  /// 너비로 화면 크기 분류
  static ScreenSize fromWidth(double width) {
    if (width >= expandedBreakpoint) {
      return ScreenSize.expanded;
    } else if (width >= mediumBreakpoint) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.compact;
    }
  }

  /// 컴팩트 화면인지
  static bool isCompact(BuildContext context) {
    return of(context) == ScreenSize.compact;
  }

  /// 미디엄 화면인지
  static bool isMedium(BuildContext context) {
    return of(context) == ScreenSize.medium;
  }

  /// 확장 화면인지
  static bool isExpanded(BuildContext context) {
    return of(context) == ScreenSize.expanded;
  }

  /// 태블릿 크기인지 (미디엄 이상)
  static bool isTablet(BuildContext context) {
    return of(context) != ScreenSize.compact;
  }

  // ============================================================
  // 화면 정보
  // ============================================================

  /// 화면 너비
  static double widthOf(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 화면 높이
  static double heightOf(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 화면 비율 (width / height)
  static double aspectRatioOf(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  /// 가로 모드인지
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 세로 모드인지
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // ============================================================
  // 그리드 계산
  // ============================================================

  /// 그리드 컬럼 수
  static int columnsOf(BuildContext context) {
    return of(context).columns;
  }

  /// 그리드 마진
  static double marginOf(BuildContext context) {
    return of(context).margin;
  }

  /// 그리드 거터
  static double gutterOf(BuildContext context) {
    return of(context).gutter;
  }

  /// 컬럼 너비 계산
  static double columnWidth(BuildContext context, int spans) {
    final screenSize = of(context);
    final screenWidth = widthOf(context);
    final totalMargin = screenSize.margin * 2;
    final totalGutter = screenSize.gutter * (screenSize.columns - 1);
    final availableWidth = screenWidth - totalMargin - totalGutter;
    final columnWidth = availableWidth / screenSize.columns;
    return columnWidth * spans + screenSize.gutter * (spans - 1);
  }
}

/// 반응형 값 빌더
class MGResponsive<T> {
  final T compact;
  final T? medium;
  final T? expanded;

  const MGResponsive({
    required this.compact,
    this.medium,
    this.expanded,
  });

  /// 현재 화면 크기에 맞는 값
  T of(BuildContext context) {
    final screenSize = MGScreenSize.of(context);
    switch (screenSize) {
      case ScreenSize.expanded:
        return expanded ?? medium ?? compact;
      case ScreenSize.medium:
        return medium ?? compact;
      case ScreenSize.compact:
        return compact;
    }
  }
}

/// 반응형 위젯 빌더
class MGResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const MGResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, MGScreenSize.of(context));
  }
}

/// 화면 크기별 위젯
class MGResponsiveWidget extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const MGResponsiveWidget({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MGScreenSize.of(context);
    switch (screenSize) {
      case ScreenSize.expanded:
        return expanded ?? medium ?? compact;
      case ScreenSize.medium:
        return medium ?? compact;
      case ScreenSize.compact:
        return compact;
    }
  }
}

/// 화면 크기별 여백
class MGResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? compact;
  final EdgeInsets? medium;
  final EdgeInsets? expanded;

  const MGResponsivePadding({
    super.key,
    required this.child,
    this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MGScreenSize.of(context);
    EdgeInsets padding;

    switch (screenSize) {
      case ScreenSize.expanded:
        padding = expanded ??
            medium ??
            compact ??
            EdgeInsets.symmetric(horizontal: screenSize.margin);
        break;
      case ScreenSize.medium:
        padding = medium ??
            compact ??
            EdgeInsets.symmetric(horizontal: screenSize.margin);
        break;
      case ScreenSize.compact:
        padding = compact ??
            EdgeInsets.symmetric(horizontal: screenSize.margin);
        break;
    }

    return Padding(padding: padding, child: child);
  }
}

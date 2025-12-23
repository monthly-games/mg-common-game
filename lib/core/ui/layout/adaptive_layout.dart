import 'package:flutter/material.dart';
import 'screen_size.dart';

/// MG-Games 적응형 레이아웃
/// UI_UX_MASTER_GUIDE.md 기반

/// 적응형 레이아웃 위젯
class MGAdaptiveLayout extends StatelessWidget {
  /// 컴팩트 화면 레이아웃
  final Widget body;

  /// 미디엄/확장 화면에서 표시할 사이드 패널
  final Widget? sidePanel;

  /// 사이드 패널 너비 비율 (0.0 ~ 0.5)
  final double sidePanelRatio;

  /// 사이드 패널 위치
  final SidePanelPosition sidePanelPosition;

  /// 컴팩트 화면에서 사이드 패널을 드로어로 표시할지
  final bool useDrawerOnCompact;

  const MGAdaptiveLayout({
    super.key,
    required this.body,
    this.sidePanel,
    this.sidePanelRatio = 0.35,
    this.sidePanelPosition = SidePanelPosition.left,
    this.useDrawerOnCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MGScreenSize.of(context);

    // 사이드 패널 없으면 본문만 표시
    if (sidePanel == null) {
      return body;
    }

    // 컴팩트 화면
    if (screenSize == ScreenSize.compact) {
      return body;
    }

    // 미디엄/확장 화면 - 사이드 패널 표시
    final panelWidth = MediaQuery.of(context).size.width * sidePanelRatio;

    if (sidePanelPosition == SidePanelPosition.left) {
      return Row(
        children: [
          SizedBox(width: panelWidth, child: sidePanel),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: body),
          const VerticalDivider(width: 1),
          SizedBox(width: panelWidth, child: sidePanel),
        ],
      );
    }
  }
}

/// 사이드 패널 위치
enum SidePanelPosition {
  left,
  right,
}

/// 적응형 그리드
class MGAdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? compactColumns;
  final int? mediumColumns;
  final int? expandedColumns;

  const MGAdaptiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.compactColumns,
    this.mediumColumns,
    this.expandedColumns,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MGScreenSize.of(context);
    int columns;

    switch (screenSize) {
      case ScreenSize.expanded:
        columns = expandedColumns ?? mediumColumns ?? 4;
        break;
      case ScreenSize.medium:
        columns = mediumColumns ?? 3;
        break;
      case ScreenSize.compact:
        columns = compactColumns ?? 2;
        break;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 적응형 리스트/그리드 전환
class MGAdaptiveListGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final bool useListOnCompact;
  final int gridColumns;

  const MGAdaptiveListGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.useListOnCompact = true,
    this.gridColumns = 2,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MGScreenSize.of(context);

    // 컴팩트 화면에서는 리스트
    if (screenSize == ScreenSize.compact && useListOnCompact) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(height: spacing),
        itemBuilder: (_, index) => children[index],
      );
    }

    // 그 외에는 그리드
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: children.length,
      itemBuilder: (_, index) => children[index],
    );
  }
}

/// 적응형 네비게이션
class MGAdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<MGNavigationDestination> destinations;
  final Widget body;
  final Widget? floatingActionButton;

  const MGAdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MGScreenSize.of(context);

    // 확장 화면 - NavigationRail
    if (screenSize == ScreenSize.expanded) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon ?? d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // 미디엄 화면 - NavigationRail (아이콘만)
    if (screenSize == ScreenSize.medium) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.selected,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon ?? d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // 컴팩트 화면 - BottomNavigationBar
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon ?? d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// 네비게이션 목적지
class MGNavigationDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const MGNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// 마스터-디테일 레이아웃
class MGMasterDetail extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final Widget? emptyDetail;
  final double masterRatio;

  const MGMasterDetail({
    super.key,
    required this.master,
    this.detail,
    this.emptyDetail,
    this.masterRatio = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MGScreenSize.of(context);

    // 컴팩트 화면 - 마스터만 또는 디테일만
    if (screenSize == ScreenSize.compact) {
      return detail ?? master;
    }

    // 확장 화면 - 사이드 바이 사이드
    final masterWidth = MediaQuery.of(context).size.width * masterRatio;

    return Row(
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1),
        Expanded(
          child: detail ??
              emptyDetail ??
              const Center(child: Text('선택된 항목 없음')),
        ),
      ],
    );
  }
}

/// 적응형 다이얼로그
class MGAdaptiveDialog {
  MGAdaptiveDialog._();

  /// 적응형 다이얼로그 표시
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    final screenSize = MGScreenSize.of(context);

    // 확장 화면 - 센터 다이얼로그
    if (screenSize != ScreenSize.compact) {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: child,
                  ),
                ),
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // 컴팩트 화면 - 풀스크린 다이얼로그
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: barrierDismissible,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
            ),
            if (actions != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// MG-Games 오프라인 표시 위젯
/// UI_UX_MASTER_GUIDE.md 기반

/// 오프라인 배너
class MGOfflineBanner extends StatelessWidget {
  final bool isOffline;
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const MGOfflineBanner({
    super.key,
    required this.isOffline,
    this.message = '오프라인 상태입니다',
    this.backgroundColor = Colors.orange,
    this.textColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOffline ? 32 : 0,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: textColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 오프라인 표시가 포함된 Scaffold
class MGOfflineScaffold extends StatelessWidget {
  final bool isOffline;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final String offlineMessage;

  const MGOfflineScaffold({
    super.key,
    required this.isOffline,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.offlineMessage = '오프라인 상태입니다',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          MGOfflineBanner(
            isOffline: isOffline,
            message: offlineMessage,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// 네트워크 상태 아이콘
class MGNetworkStatusIcon extends StatelessWidget {
  final bool isOnline;
  final double size;
  final Color? onlineColor;
  final Color? offlineColor;
  final bool showLabel;

  const MGNetworkStatusIcon({
    super.key,
    required this.isOnline,
    this.size = 24,
    this.onlineColor,
    this.offlineColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline
        ? (onlineColor ?? Colors.green)
        : (offlineColor ?? Colors.red);
    final icon = isOnline ? Icons.wifi : Icons.wifi_off;
    final label = isOnline ? '온라인' : '오프라인';

    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: size * 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Icon(icon, size: size, color: color);
  }
}

/// 연결 상태 표시
class MGConnectionStatus extends StatelessWidget {
  final ConnectionState state;
  final double size;
  final bool showLabel;

  const MGConnectionStatus({
    super.key,
    required this.state,
    this.size = 16,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (state) {
      case ConnectionState.connected:
        color = Colors.green;
        label = '연결됨';
        icon = Icons.cloud_done;
        break;
      case ConnectionState.connecting:
        color = Colors.orange;
        label = '연결 중...';
        icon = Icons.cloud_sync;
        break;
      case ConnectionState.disconnected:
        color = Colors.red;
        label = '연결 끊김';
        icon = Icons.cloud_off;
        break;
      case ConnectionState.error:
        color = Colors.red;
        label = '연결 오류';
        icon = Icons.error;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state == ConnectionState.connecting)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          )
        else
          Icon(icon, size: size, color: color),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: size * 0.75,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// 연결 상태
enum ConnectionState {
  connected,
  connecting,
  disconnected,
  error,
}

/// 동기화 상태 표시
class MGSyncStatus extends StatelessWidget {
  final SyncState state;
  final int? pendingCount;
  final DateTime? lastSyncTime;
  final VoidCallback? onSync;

  const MGSyncStatus({
    super.key,
    required this.state,
    this.pendingCount,
    this.lastSyncTime,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (state) {
      case SyncState.synced:
        color = Colors.green;
        label = '동기화됨';
        icon = Icons.cloud_done;
        break;
      case SyncState.syncing:
        color = Colors.blue;
        label = '동기화 중...';
        icon = Icons.sync;
        break;
      case SyncState.pending:
        color = Colors.orange;
        label = pendingCount != null ? '$pendingCount개 대기' : '대기 중';
        icon = Icons.cloud_upload;
        break;
      case SyncState.error:
        color = Colors.red;
        label = '동기화 실패';
        icon = Icons.sync_problem;
        break;
      case SyncState.offline:
        color = Colors.grey;
        label = '오프라인';
        icon = Icons.cloud_off;
        break;
    }

    return InkWell(
      onTap: onSync,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == SyncState.syncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (lastSyncTime != null && state == SyncState.synced)
                  Text(
                    _formatLastSync(lastSyncTime!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

/// 동기화 상태
enum SyncState {
  synced,
  syncing,
  pending,
  error,
  offline,
}

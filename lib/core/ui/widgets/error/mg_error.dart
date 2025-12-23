import 'package:flutter/material.dart';
import '../../layout/mg_spacing.dart';
import '../buttons/mg_button.dart';

/// MG-Games 오류 위젯
/// UI_UX_MASTER_GUIDE.md 기반

/// 오류 유형
enum MGErrorType {
  network,
  server,
  notFound,
  permission,
  validation,
  generic,
}

extension MGErrorTypeExtension on MGErrorType {
  IconData get icon {
    switch (this) {
      case MGErrorType.network:
        return Icons.wifi_off;
      case MGErrorType.server:
        return Icons.cloud_off;
      case MGErrorType.notFound:
        return Icons.search_off;
      case MGErrorType.permission:
        return Icons.lock;
      case MGErrorType.validation:
        return Icons.warning;
      case MGErrorType.generic:
        return Icons.error_outline;
    }
  }

  String get defaultTitle {
    switch (this) {
      case MGErrorType.network:
        return '네트워크 오류';
      case MGErrorType.server:
        return '서버 오류';
      case MGErrorType.notFound:
        return '찾을 수 없음';
      case MGErrorType.permission:
        return '권한 필요';
      case MGErrorType.validation:
        return '입력 오류';
      case MGErrorType.generic:
        return '오류 발생';
    }
  }

  String get defaultMessage {
    switch (this) {
      case MGErrorType.network:
        return '인터넷 연결을 확인해주세요.';
      case MGErrorType.server:
        return '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case MGErrorType.notFound:
        return '요청하신 내용을 찾을 수 없습니다.';
      case MGErrorType.permission:
        return '이 기능을 사용하려면 권한이 필요합니다.';
      case MGErrorType.validation:
        return '입력 내용을 확인해주세요.';
      case MGErrorType.generic:
        return '문제가 발생했습니다. 다시 시도해주세요.';
    }
  }

  Color get color {
    switch (this) {
      case MGErrorType.network:
        return Colors.orange;
      case MGErrorType.server:
        return Colors.red;
      case MGErrorType.notFound:
        return Colors.grey;
      case MGErrorType.permission:
        return Colors.amber;
      case MGErrorType.validation:
        return Colors.orange;
      case MGErrorType.generic:
        return Colors.red;
    }
  }
}

/// 오류 표시 위젯
class MGErrorWidget extends StatelessWidget {
  final MGErrorType type;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryText;
  final VoidCallback? onAction;
  final String? actionText;
  final double iconSize;
  final bool compact;

  const MGErrorWidget({
    super.key,
    this.type = MGErrorType.generic,
    this.title,
    this.message,
    this.onRetry,
    this.retryText = '다시 시도',
    this.onAction,
    this.actionText,
    this.iconSize = 64,
    this.compact = false,
  });

  /// 네트워크 오류
  const MGErrorWidget.network({
    super.key,
    this.message,
    this.onRetry,
    this.retryText = '다시 시도',
    this.iconSize = 64,
    this.compact = false,
  })  : type = MGErrorType.network,
        title = null,
        onAction = null,
        actionText = null;

  /// 서버 오류
  const MGErrorWidget.server({
    super.key,
    this.message,
    this.onRetry,
    this.retryText = '다시 시도',
    this.iconSize = 64,
    this.compact = false,
  })  : type = MGErrorType.server,
        title = null,
        onAction = null,
        actionText = null;

  /// 찾을 수 없음
  const MGErrorWidget.notFound({
    super.key,
    this.message,
    this.onAction,
    this.actionText = '홈으로',
    this.iconSize = 64,
    this.compact = false,
  })  : type = MGErrorType.notFound,
        title = null,
        onRetry = null,
        retryText = '';

  /// 권한 필요
  const MGErrorWidget.permission({
    super.key,
    this.message,
    this.onAction,
    this.actionText = '설정으로',
    this.iconSize = 64,
    this.compact = false,
  })  : type = MGErrorType.permission,
        title = null,
        onRetry = null,
        retryText = '';

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? type.defaultTitle;
    final effectiveMessage = message ?? type.defaultMessage;

    if (compact) {
      return _buildCompact(context, effectiveTitle, effectiveMessage);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: iconSize,
              color: type.color,
            ),
            MGSpacing.vMd,
            Text(
              effectiveTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            MGSpacing.vSm,
            Text(
              effectiveMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            MGSpacing.vLg,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  MGButton.primary(
                    label: retryText,
                    icon: Icons.refresh,
                    onPressed: onRetry,
                  ),
                if (onRetry != null && onAction != null)
                  const SizedBox(width: 12),
                if (onAction != null && actionText != null)
                  MGButton.secondary(
                    label: actionText!,
                    onPressed: onAction,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    String effectiveTitle,
    String effectiveMessage,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            type.icon,
            size: 32,
            color: type.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  effectiveTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  effectiveMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}

/// 인라인 오류 메시지
class MGErrorMessage extends StatelessWidget {
  final String message;
  final MGErrorType type;
  final VoidCallback? onDismiss;

  const MGErrorMessage({
    super.key,
    required this.message,
    this.type = MGErrorType.generic,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(type.icon, size: 20, color: type.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: type.color),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// 빈 상태 위젯
class MGEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onAction;
  final String? actionText;
  final double iconSize;

  const MGEmptyState({
    super.key,
    this.icon = Icons.inbox,
    required this.title,
    this.message,
    this.onAction,
    this.actionText,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.grey,
            ),
            MGSpacing.vMd,
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              MGSpacing.vSm,
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              MGSpacing.vLg,
              MGButton.primary(
                label: actionText!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 스낵바 표시 헬퍼
class MGSnackBar {
  MGSnackBar._();

  /// 성공 스낵바
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green, Icons.check_circle);
  }

  /// 오류 스낵바
  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red, Icons.error);
  }

  /// 경고 스낵바
  static void warning(BuildContext context, String message) {
    _show(context, message, Colors.orange, Icons.warning);
  }

  /// 정보 스낵바
  static void info(BuildContext context, String message) {
    _show(context, message, Colors.blue, Icons.info);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

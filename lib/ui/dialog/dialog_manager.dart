import 'package:flutter/material.dart';
import 'package:mg_common_game/ui/theme/theme_manager.dart';

/// 다이얼로그 스타일
enum DialogStyle {
  basic,
  success,
  warning,
  error,
  info,
}

/// 다이얼로그 옵션
class DialogOptions {
  final String title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? icon;
  final DialogStyle style;
  final bool barrierDismissible;
  final Color? backgroundColor;
  final double? borderRadius;

  const DialogOptions({
    required this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.style = DialogStyle.basic,
    this.barrierDismissible = true,
    this.backgroundColor,
    this.borderRadius,
  });

  /// 확인 다이얼로그
  static DialogOptions confirm({
    required String title,
    String? message,
    String confirmText = '확인',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return DialogOptions(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      style: DialogStyle.info,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 성공 다이얼로그
  static DialogOptions success({
    required String title,
    String? message,
    String confirmText = '확인',
    VoidCallback? onConfirm,
  }) {
    return DialogOptions(
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
      style: DialogStyle.success,
    );
  }

  /// 경고 다이얼로그
  static DialogOptions warning({
    required String title,
    String? message,
    String confirmText = '확인',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return DialogOptions(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      style: DialogStyle.warning,
    );
  }

  /// 에러 다이얼로그
  static DialogOptions error({
    required String title,
    String? message,
    String confirmText = '확인',
    VoidCallback? onConfirm,
  }) {
    return DialogOptions(
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
      style: DialogStyle.error,
    );
  }
}

/// 커스텀 다이얼로그
class CustomDialog extends StatelessWidget {
  final DialogOptions options;

  const CustomDialog({
    super.key,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    // 스타일별 색상 및 아이콘
    Color primaryColor;
    IconData? defaultIcon;

    switch (options.style) {
      case DialogStyle.success:
        primaryColor = colors.success;
        defaultIcon = Icons.check_circle;
        break;
      case DialogStyle.warning:
        primaryColor = colors.warning;
        defaultIcon = Icons.warning;
        break;
      case DialogStyle.error:
        primaryColor = colors.error;
        defaultIcon = Icons.error;
        break;
      case DialogStyle.info:
        primaryColor = colors.info;
        defaultIcon = Icons.info;
        break;
      default:
        primaryColor = colors.primary;
        defaultIcon = null;
    }

    return Dialog(
      backgroundColor: options.backgroundColor ?? colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(options.borderRadius ?? 16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            if (options.icon != null || defaultIcon != null)
              Icon(
                options.icon ?? defaultIcon,
                size: 48,
                color: primaryColor,
              ),

            if (options.icon != null || defaultIcon != null)
              const SizedBox(height: 16),

            // 제목
            Text(
              options.title,
              style: theme.toMaterialTheme().textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),

            // 메시지
            if (options.message != null) ...[
              const SizedBox(height: 12),
              Text(
                options.message!,
                style: theme.toMaterialTheme().textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // 버튼
            Row(
              children: [
                if (options.cancelText != null)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        options.onCancel?.call();
                      },
                      child: Text(options.cancelText!),
                    ),
                  ),

                if (options.cancelText != null)
                  const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      options.onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: options.style == DialogStyle.warning
                          ? colors.onBackground
                          : colors.onPrimary,
                    ),
                    child: Text(options.confirmText ?? '확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 다이얼로그 매니저
class DialogManager {
  // ============================================
  // 기본 다이얼로그 표시
  // ============================================

  static Future<T?> show<T>({
    required BuildContext context,
    required DialogOptions options,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: options.barrierDismissible,
      builder: (context) => CustomDialog(options: options),
    );
  }

  /// 확인 다이얼로그
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = '확인',
    String? cancelText,
  }) {
    return show<bool>(
      context: context,
      options: DialogOptions.confirm(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  /// 성공 다이얼로그
  static Future<void> success({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = '확인',
  }) {
    return show(
      context: context,
      options: DialogOptions.success(
        title: title,
        message: message,
        confirmText: confirmText,
      ),
    );
  }

  /// 경고 다이얼로그
  static Future<bool?> warning({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = '확인',
    String? cancelText,
  }) {
    return show<bool>(
      context: context,
      options: DialogOptions.warning(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  /// 에러 다이얼로그
  static Future<void> error({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = '확인',
  }) {
    return show(
      context: context,
      options: DialogOptions.error(
        title: title,
        message: message,
        confirmText: confirmText,
      ),
    );
  }

  // ============================================
  // 로딩 다이얼로그
  // ============================================

  static Future<T> showLoading<T>({
    required BuildContext context,
    required Future<T> Function() future,
    String message = '로딩 중...',
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(message: message),
    );

    try {
      final result = await future();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }

  /// 로딩 표시
  static void showLoadingDialog({
    required BuildContext context,
    String message = '로딩 중...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(message: message),
    );
  }

  /// 로딩 숨김
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // ============================================
  // 바텀 시트
  // ============================================

  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheetWrapper(
        builder: builder,
      ),
    );
  }
}

/// 로딩 다이얼로그
class _LoadingDialog extends StatelessWidget {
  final String message;

  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.toMaterialTheme().textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 바텀 시트 래퍼
class _BottomSheetWrapper extends StatelessWidget {
  final WidgetBuilder builder;

  const _BottomSheetWrapper({required this.builder});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Builder(builder: builder),
    );
  }
}

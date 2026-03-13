import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mg_common_game/ui/theme/theme_manager.dart';

/// 토스트 타입
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// 토스트 위치
enum ToastPosition {
  top,
  center,
  bottom,
}

/// 토스트 옵션
class ToastOptions {
  final String message;
  final ToastType type;
  final ToastPosition position;
  final Duration duration;
  final bool isDismissible;
  final Widget? icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;

  const ToastOptions({
    required this.message,
    this.type = ToastType.info,
    this.position = ToastPosition.top,
    this.duration = const Duration(seconds: 3),
    this.isDismissible = true,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  });
}

/// 토스트 위젯
class ToastWidget extends StatelessWidget {
  final ToastOptions options;
  final VoidCallback onDismiss;

  const ToastWidget({
    super.key,
    required this.options,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    // 타입별 색상 및 아이콘
    Color backgroundColor;
    Color textColor;
    IconData? defaultIcon;

    switch (options.type) {
      case ToastType.success:
        backgroundColor = colors.success;
        textColor = colors.onError;
        defaultIcon = Icons.check_circle;
        break;
      case ToastType.error:
        backgroundColor = colors.error;
        textColor = colors.onError;
        defaultIcon = Icons.error;
        break;
      case ToastType.warning:
        backgroundColor = colors.warning;
        textColor = colors.onBackground;
        defaultIcon = Icons.warning;
        break;
      case ToastType.info:
        backgroundColor = colors.info;
        textColor = colors.onError;
        defaultIcon = Icons.info;
        break;
    }

    final effectiveBackgroundColor = options.backgroundColor ?? backgroundColor;
    final effectiveTextColor = options.textColor ?? textColor;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          top: options.position == ToastPosition.top ? 16 : 0,
          bottom: options.position == ToastPosition.bottom ? 16 : 0,
        ),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              options.onTap?.call();
              if (options.isDismissible) {
                onDismiss();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: effectiveBackgroundColor,
                borderRadius: BorderRadius.circular(options.borderRadius ?? 12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (options.icon != null || defaultIcon != null)
                    Icon(
                      options.icon ?? defaultIcon,
                      color: effectiveTextColor,
                      size: 20,
                    ),

                  if (options.icon != null || defaultIcon != null)
                    const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      options.message,
                      style: TextStyle(
                        color: effectiveTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (options.isDismissible)
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(
                        Icons.close,
                        color: effectiveTextColor,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 토스트 매니저
class ToastManager {
  static final ToastManager _instance = ToastManager._();
  static ToastManager get instance => _instance;

  ToastManager._();

  OverlayEntry? _overlayEntry;
  Timer? _timer;

  /// 토스트 표시
  void show({
    required BuildContext context,
    required ToastOptions options,
  }) {
    // 기존 토스트 제거
    dismiss();

    // Overlay 생성
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        options: options,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_overlayEntry!);

    // 자동 제거 타이머
    _timer = Timer(options.duration, dismiss);
  }

  /// 간단한 메시지 토스트
  void showSimple({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      options: ToastOptions(
        message: message,
        type: type,
        position: position,
        duration: duration,
      ),
    );
  }

  /// 성공 토스트
  void success({
    required BuildContext context,
    required String message,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 2),
  }) {
    showSimple(
      context: context,
      message: message,
      type: ToastType.success,
      position: position,
      duration: duration,
    );
  }

  /// 에러 토스트
  void error({
    required BuildContext context,
    required String message,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSimple(
      context: context,
      message: message,
      type: ToastType.error,
      position: position,
      duration: duration,
    );
  }

  /// 경고 토스트
  void warning({
    required BuildContext context,
    required String message,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSimple(
      context: context,
      message: message,
      type: ToastType.warning,
      position: position,
      duration: duration,
    );
  }

  /// 정보 토스트
  void info({
    required BuildContext context,
    required String message,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSimple(
      context: context,
      message: message,
      type: ToastType.info,
      position: position,
      duration: duration,
    );
  }

  /// 토스트 제거
  void dismiss() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// 토스트 오버레이
class _ToastOverlay extends StatefulWidget {
  final ToastOptions options;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.options,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 위치별 애니메이션
    switch (widget.options.position) {
      case ToastPosition.top:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ));
        break;
      case ToastPosition.center:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ));
        break;
      case ToastPosition.bottom:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ));
        break;
    }

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.options.position == ToastPosition.top
        ? Alignment.topCenter
        : widget.options.position == ToastPosition.bottom
            ? Alignment.bottomCenter
            : Alignment.center;

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ToastWidget(
              options: widget.options,
              onDismiss: widget.onDismiss,
            ),
          ),
        ),
      ),
    );
  }
}

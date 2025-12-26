import 'package:flutter/material.dart';

/// Toast notification types
enum ToastType {
  info,
  success,
  warning,
  error,
}

/// Toast notification manager
class ToastManager {
  static final ToastManager _instance = ToastManager._internal();
  factory ToastManager() => _instance;
  ToastManager._internal();

  OverlayEntry? _currentToast;
  BuildContext? _context;

  /// Initialize with context (call in main widget)
  void initialize(BuildContext context) {
    _context = context;
  }

  /// Show a toast notification
  void show({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onTap,
  }) {
    if (_context == null) return;

    // Remove existing toast
    _currentToast?.remove();

    final overlay = Overlay.of(_context!);

    _currentToast = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onTap: onTap,
        onDismiss: () {
          _currentToast?.remove();
          _currentToast = null;
        },
        duration: duration,
      ),
    );

    overlay.insert(_currentToast!);
  }

  /// Show info toast
  void info(String message) {
    show(message: message, type: ToastType.info);
  }

  /// Show success toast
  void success(String message) {
    show(message: message, type: ToastType.success);
  }

  /// Show warning toast
  void warning(String message) {
    show(message: message, type: ToastType.warning);
  }

  /// Show error toast
  void error(String message) {
    show(message: message, type: ToastType.error);
  }

  /// Hide current toast
  void hide() {
    _currentToast?.remove();
    _currentToast = null;
  }
}

/// Toast widget
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.onTap,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case ToastType.info:
        return Colors.blueGrey.shade700;
      case ToastType.success:
        return Colors.green.shade600;
      case ToastType.warning:
        return Colors.orange.shade600;
      case ToastType.error:
        return Colors.red.shade600;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.info:
        return Icons.info_outline;
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
              _dismiss();
            },
            onHorizontalDragEnd: (_) => _dismiss(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

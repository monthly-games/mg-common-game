import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

/// Data class for a toast message
class ToastMessage {
  final String message;
  final Duration duration;
  final Color backgroundColor;
  final Color textColor;

  ToastMessage({
    required this.message,
    this.duration = const Duration(seconds: 2),
    this.backgroundColor = const Color(0xCC000000), // Semi-transparent black
    this.textColor = Colors.white,
  });
}

/// Singleton manager to handle toast requests
@singleton
class ToastManager {
  final _toastController = StreamController<ToastMessage>.broadcast();
  Stream<ToastMessage> get onShowToast => _toastController.stream;

  void show(
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color backgroundColor = const Color(0xCC000000),
    Color textColor = Colors.white,
  }) {
    _toastController.add(ToastMessage(
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
      textColor: textColor,
    ));
  }

  void dispose() {
    _toastController.close();
  }
}

/// Widget to place in the app's root Stack to render toasts
class GameToastOverlay extends StatefulWidget {
  final ToastManager manager;
  final Widget? child; // Optional, can wrap the app or just sit on top

  const GameToastOverlay({super.key, required this.manager, this.child});

  @override
  State<GameToastOverlay> createState() => _GameToastOverlayState();
}

class _GameToastOverlayState extends State<GameToastOverlay>
    with SingleTickerProviderStateMixin {
  final Queue<ToastMessage> _queue = Queue();
  Timer? _timer;
  bool _isVisible = false;
  ToastMessage? _currentToast;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    widget.manager.onShowToast.listen(_addToQueue);
  }

  void _addToQueue(ToastMessage toast) {
    _queue.add(toast);
    if (!_isVisible) {
      _showNext();
    }
  }

  void _showNext() {
    if (_queue.isEmpty) {
      _isVisible = false;
      return;
    }

    _isVisible = true;
    setState(() {
      _currentToast = _queue.removeFirst();
    });

    _animationController.forward();

    _timer = Timer(_currentToast!.duration, () async {
      await _animationController.reverse();
      _showNext();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Align(
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              );
            },
            child: _currentToast == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentToast!.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        _currentToast!.message,
                        style: TextStyle(
                            color: _currentToast!.textColor,
                            fontSize: 16,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal,
                            fontFamily:
                                'Pretendard' // Assuming generic or user pref
                            ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class AnimationManager {
  static final AnimationManager _instance = AnimationManager._();
  static AnimationManager get instance => _instance;

  AnimationManager._();

  final Map<String, AnimationController> _controllers = {};
  final Map<String, CurvedAnimation> _animations = {};

  AnimationController createController({
    required String id,
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final controller = AnimationController(vsync: vsync, duration: duration);
    _controllers[id] = controller;
    return controller;
  }

  CurvedAnimation createCurvedAnimation({
    required String id,
    required AnimationController controller,
    Curve curve = Curves.easeInOut,
  }) {
    final animation = CurvedAnimation(parent: controller, curve: curve);
    _animations[id] = animation;
    return animation;
  }

  Future<void> playAnimation(String id) async {
    final controller = _controllers[id];
    if (controller != null) {
      await controller.forward();
    }
  }

  void dispose(String id) {
    _controllers[id]?.dispose();
    _controllers.remove(id);
    _animations.remove(id);
  }

  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _animations.clear();
  }
}

class TransitionManager {
  static Widget buildTransition({
    required Widget child,
    required String type,
  }) {
    switch (type) {
      case 'fade':
        return FadeTransition(opaqueCurve: AlwaysStoppedAnimation(0), child: child);
      case 'scale':
        return ScaleTransition(scale: AlwaysStoppedAnimation(1), child: child);
      case 'slide':
        return SlideTransition(position: AlwaysStoppedAnimation(Offset.zero), child: child);
      default:
        return child;
    }
  }
}

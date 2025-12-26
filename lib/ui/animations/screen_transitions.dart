import 'package:flutter/material.dart';

/// Fade transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Slide from right transition
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideRightPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Slide from bottom transition
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideUpPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Scale transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Alignment alignment;

  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutBack),
            );
            return ScaleTransition(
              scale: animation.drive(tween),
              alignment: alignment,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// Rotation transition
class RotationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  RotationPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final rotationTween = Tween(begin: 0.5, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutBack),
            );
            final fadeTween = Tween(begin: 0.0, end: 1.0);
            return RotationTransition(
              turns: animation.drive(rotationTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Slide and fade combined transition
class SlideAndFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Offset slideBegin;

  SlideAndFadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.slideBegin = const Offset(0.0, 0.3),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween(
              begin: slideBegin,
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOut));
            final fadeTween = Tween(begin: 0.0, end: 1.0);
            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Hero-like expansion transition from a widget
class ExpansionPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Rect? sourceRect;

  ExpansionPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.sourceRect,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// No animation transition (instant)
class NoAnimationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  NoAnimationPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

/// Custom page transition builder for MaterialApp
class GamePageTransitionsBuilder extends PageTransitionsBuilder {
  final PageTransitionType type;

  const GamePageTransitionsBuilder({
    this.type = PageTransitionType.slideRight,
  });

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(opacity: animation, child: child);
      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      case PageTransitionType.none:
        return child;
    }
  }
}

enum PageTransitionType {
  fade,
  slideRight,
  slideUp,
  scale,
  none,
}

/// Navigation helper with transitions
class GameNavigator {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType transition = PageTransitionType.slideRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.push<T>(
      context,
      _buildRoute<T>(page, transition, duration),
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    PageTransitionType transition = PageTransitionType.fade,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.pushReplacement<T, TO>(
      context,
      _buildRoute<T>(page, transition, duration),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    PageTransitionType transition = PageTransitionType.fade,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      _buildRoute<T>(page, transition, duration),
      predicate,
    );
  }

  static PageRouteBuilder<T> _buildRoute<T>(
    Widget page,
    PageTransitionType transition,
    Duration duration,
  ) {
    switch (transition) {
      case PageTransitionType.fade:
        return FadePageRoute<T>(page: page, duration: duration);
      case PageTransitionType.slideRight:
        return SlideRightPageRoute<T>(page: page, duration: duration);
      case PageTransitionType.slideUp:
        return SlideUpPageRoute<T>(page: page, duration: duration);
      case PageTransitionType.scale:
        return ScalePageRoute<T>(page: page, duration: duration);
      case PageTransitionType.none:
        return NoAnimationPageRoute<T>(page: page);
    }
  }
}

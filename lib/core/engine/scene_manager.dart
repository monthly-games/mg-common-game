import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@singleton
class SceneManager {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> push<T>(Route<T> route) {
    return navigatorKey.currentState!.push(route);
  }

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }

  Future<T?> replace<T, TO>(Route<T> newRoute, {TO? result}) {
    return navigatorKey.currentState!.pushReplacement(newRoute, result: result);
  }

  Future<T?> replaceNamed<T, TO>(String routeName,
      {TO? result, Object? arguments}) {
    return navigatorKey.currentState!
        .pushReplacementNamed(routeName, result: result, arguments: arguments);
  }

  void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }

  void popUntil(bool Function(Route<dynamic>) predicate) {
    navigatorKey.currentState!.popUntil(predicate);
  }
}

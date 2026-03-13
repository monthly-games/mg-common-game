import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityManager {
  static final AccessibilityManager _instance = AccessibilityManager._();
  static AccessibilityManager get instance => _instance;

  AccessibilityManager._();

  bool _isScreenReaderEnabled = false;
  double _textScaleFactor = 1.0;
  bool _isHighContrast = false;

  Future<void> initialize() async {
  }

  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  double get textScaleFactor => _textScaleFactor;
  bool get isHighContrast => _isHighContrast;

  void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  void setScreenReaderEnabled(bool enabled) {
    _isScreenReaderEnabled = enabled;
  }

  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale.clamp(1.0, 3.0);
  }

  void setHighContrast(bool enabled) {
    _isHighContrast = enabled;
  }

  void dispose() {}
}

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Haptic feedback intensity
enum HapticIntensity {
  light,
  medium,
  heavy,
  selection,
}

/// Manages haptic (vibration) feedback
class HapticFeedbackManager {
  bool _enabled = true;
  bool? _hasVibrator;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  /// Check if device supports vibration
  Future<bool> hasVibrator() async {
    _hasVibrator ??= await Vibration.hasVibrator() ?? false;
    return _hasVibrator!;
  }

  /// Trigger haptic feedback
  Future<void> trigger({
    HapticIntensity intensity = HapticIntensity.light,
  }) async {
    if (!_enabled) return;

    // Try system haptic first (more reliable on some devices)
    switch (intensity) {
      case HapticIntensity.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticIntensity.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// Trigger vibration with custom duration
  Future<void> vibrate({int duration = 50}) async {
    if (!_enabled) return;
    if (!await hasVibrator()) return;

    await Vibration.vibrate(duration: duration);
  }

  /// Trigger pattern vibration
  Future<void> vibratePattern(List<int> pattern) async {
    if (!_enabled) return;
    if (!await hasVibrator()) return;

    await Vibration.vibrate(pattern: pattern);
  }

  // ============================================================
  // Common Haptic Patterns
  // ============================================================

  /// Button tap feedback
  Future<void> buttonTap() async {
    await trigger(intensity: HapticIntensity.light);
  }

  /// Success feedback
  Future<void> success() async {
    await trigger(intensity: HapticIntensity.medium);
  }

  /// Error feedback
  Future<void> error() async {
    await vibratePattern([0, 100, 50, 100]);
  }

  /// Warning feedback
  Future<void> warning() async {
    await trigger(intensity: HapticIntensity.heavy);
  }

  /// Level up / achievement feedback
  Future<void> celebration() async {
    await vibratePattern([0, 50, 50, 50, 50, 100]);
  }

  /// Coin collect feedback
  Future<void> collect() async {
    await trigger(intensity: HapticIntensity.selection);
  }

  /// Impact / collision feedback
  Future<void> impact() async {
    await trigger(intensity: HapticIntensity.heavy);
  }
}

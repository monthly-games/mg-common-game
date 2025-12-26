/// Feedback system exports
library feedback;

export 'haptic_feedback.dart';
export 'audio_feedback.dart';
export 'visual_feedback.dart';
export 'toast_notification.dart';

import 'haptic_feedback.dart';
import 'audio_feedback.dart';

/// Combined feedback manager for easy access
class FeedbackManager {
  final HapticFeedbackManager haptic = HapticFeedbackManager();
  final AudioFeedbackManager audio = AudioFeedbackManager();

  bool _enabled = true;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
    haptic.setEnabled(value);
    audio.setEnabled(value);
  }

  /// Initialize feedback system
  Future<void> initialize({
    String? buttonClick,
    String? success,
    String? error,
    String? levelUp,
    String? coinCollect,
  }) async {
    audio.registerSounds(
      buttonClick: buttonClick,
      success: success,
      error: error,
      levelUp: levelUp,
      coinCollect: coinCollect,
    );
    await audio.preload();
  }

  // ============================================================
  // Combined Feedback Methods
  // ============================================================

  /// Button tap with sound and haptic
  Future<void> buttonTap() async {
    if (!_enabled) return;
    await Future.wait([
      haptic.buttonTap(),
      audio.buttonClick(),
    ]);
  }

  /// Success feedback
  Future<void> success() async {
    if (!_enabled) return;
    await Future.wait([
      haptic.success(),
      audio.success(),
    ]);
  }

  /// Error feedback
  Future<void> error() async {
    if (!_enabled) return;
    await Future.wait([
      haptic.error(),
      audio.error(),
    ]);
  }

  /// Level up feedback
  Future<void> levelUp() async {
    if (!_enabled) return;
    await Future.wait([
      haptic.celebration(),
      audio.levelUp(),
    ]);
  }

  /// Coin collect feedback
  Future<void> coinCollect() async {
    if (!_enabled) return;
    await Future.wait([
      haptic.collect(),
      audio.coinCollect(),
    ]);
  }

  /// Impact/collision feedback
  Future<void> impact() async {
    if (!_enabled) return;
    await haptic.impact();
  }
}

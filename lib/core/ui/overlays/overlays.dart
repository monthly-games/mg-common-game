/// Game Overlay Components
///
/// Common overlay patterns for Flame games:
/// - PauseGameOverlay: Pause menu with resume/settings/quit
/// - SettingsGameOverlay: In-game settings with audio controls
/// - TutorialGameOverlay: Paginated tutorial overlay
/// - GameToast: Non-blocking toast notifications
///
/// Usage with FlameGame:
/// ```dart
/// GameWidget(
///   game: myGame,
///   overlayBuilderMap: {
///     'PauseGame': (context, game) => PauseGameOverlay(
///       game: game,
///       onResume: () => game.overlays.remove('PauseGame'),
///       onSettings: () => game.overlays.add('Settings'),
///       onQuit: () => Navigator.pop(context),
///     ),
///     'Settings': (context, game) => SettingsGameOverlay(
///       game: game,
///       onBack: () => game.overlays.remove('Settings'),
///     ),
///   },
/// )
/// ```
library overlays;

export 'pause_game_overlay.dart';
export 'settings_game_overlay.dart';
export 'tutorial_game_overlay.dart';
export 'game_toast.dart';

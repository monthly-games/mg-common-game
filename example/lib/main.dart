import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mg_common_game/core/engine/asset_manager.dart';
import 'package:mg_common_game/core/systems/save_system.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/core/engine/game_manager.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'features/auth/login_screen.dart';
import 'features/lobby/lobby_screen.dart';
import 'features/game/game_screen.dart';
import 'package:mg_common_game/core/ui/theme/game_theme.dart';
import 'pages/showcase_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initCoreSystems();
  runApp(const MgExampleApp());
}

Future<void> _initCoreSystems() async {
  final getIt = GetIt.I;

  // 1. EventBus (Already used by Scene/Engine)
  getIt.registerSingleton<EventBus>(EventBus());

  // 2. AssetManager
  getIt.registerSingleton<AssetManager>(AssetManager());

  // 3. SaveSystem
  final saveSystem = LocalSaveSystem();
  await saveSystem.init();
  getIt.registerSingleton<SaveSystem>(saveSystem);

  // 4. GameManager
  final eventBus = getIt<EventBus>();
  getIt.registerSingleton<GameManager>(GameManager(eventBus, saveSystem));
}

class MgExampleApp extends StatefulWidget {
  const MgExampleApp({super.key});

  @override
  State<MgExampleApp> createState() => _MgExampleAppState();
}

class _MgExampleAppState extends State<MgExampleApp> {
  MGAccessibilitySettings _accessibilitySettings =
      const MGAccessibilitySettings();

  void _updateAccessibilitySettings(MGAccessibilitySettings settings) {
    setState(() {
      _accessibilitySettings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MGAccessibilityProvider(
      settings: _accessibilitySettings,
      onSettingsChanged: _updateAccessibilitySettings,
      child: MaterialApp.router(
        title: 'Monthly Games Example',
        theme: GameTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/lobby', builder: (context, state) => const LobbyScreen()),
    GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
    GoRoute(path: '/showcase', builder: (context, state) => const ShowcaseHomePage()),
  ],
);

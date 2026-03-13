import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 스크립트 타입
enum ScriptType {
  lua,          // Lua
  javascript,   // JavaScript
  python,       // Python
}

/// 스크립트 상태
enum ScriptStatus {
  idle,         // 대기 중
  running,      // 실행 중
  paused,       // 일시 정지
  error,        // 에러
  completed,    // 완료
}

/// 스크립트 컨텍스트
class ScriptContext {
  final String id;
  final Map<String, dynamic> variables;
  final List<String> allowedAPIs;
  final bool isSandboxed;

  const ScriptContext({
    required this.id,
    required this.variables,
    this.allowedAPIs = const [],
    this.isSandboxed = true,
  });
}

/// 스크립트 이벤트
class ScriptEvent {
  final String name;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const ScriptEvent({
    required this.name,
    required this.data,
    required this.timestamp,
  });
}

/// 스크립트 실행 결과
class ScriptResult {
  final String scriptId;
  final bool success;
  final dynamic returnValue;
  final String? errorMessage;
  final Duration executionTime;

  const ScriptResult({
    required this.scriptId,
    required this.success,
    this.returnValue,
    this.errorMessage,
    required this.executionTime,
  });
}

/// 스크립트
class GameScript {
  final String id;
  final String name;
  final String description;
  final ScriptType type;
  final String source;
  final ScriptStatus status;
  final DateTime? lastExecuted;
  final List<ScriptResult> executionHistory;
  final bool autoReload;

  const GameScript({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.source,
    required this.status,
    this.lastExecuted,
    this.executionHistory = const [],
    this.autoReload = false,
  });
}

/// 스크립팅 관리자
class ScriptingManager {
  static final ScriptingManager _instance = ScriptingManager._();
  static ScriptingManager get instance => _instance;

  ScriptingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, GameScript> _scripts = {};
  final Map<String, ScriptContext> _contexts = {};
  final List<ScriptEvent> _eventQueue = [];

  final StreamController<ScriptResult> _resultController =
      StreamController<ScriptResult>.broadcast();
  final StreamController<ScriptEvent> _eventController =
      StreamController<ScriptEvent>.broadcast();
  final StreamController<GameScript> _scriptController =
      StreamController<GameScript>.broadcast();

  Stream<ScriptResult> get onScriptResult => _resultController.stream;
  Stream<ScriptEvent> get onScriptEvent => _eventController.stream;
  Stream<GameScript> get onScriptUpdate => _scriptController.stream;

  Timer? _eventTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 스크립트 로드
    await _loadScripts();

    // 이벤트 처리 시작
    _startEventProcessing();

    debugPrint('[Scripting] Initialized');
  }

  Future<void> _loadScripts() async {
    // 기본 이벤트 스크립트
    _scripts['event_login'] = GameScript(
      id: 'event_login',
      name: '로그인 보상',
      description: '로그인 시 보상 지급',
      type: ScriptType.lua,
      source: '''
function onLogin(userId)
  -- 보상 지급 로직
  giveReward(userId, "gold", 1000)
  return "Login reward granted"
end
''',
      status: ScriptStatus.idle,
    );

    _scripts['event_battle_start'] = GameScript(
      id: 'event_battle_start',
      name: '배틀 시작',
      description: '배틀 시작 시 처리',
      type: ScriptType.lua,
      source: '''
function onBattleStart(playerId, battleId)
  -- 배틀 시작 로직
  initializeBattle(playerId, battleId)
  return "Battle initialized"
end
''',
      status: ScriptStatus.idle,
    );
  }

  void _startEventProcessing() {
    _eventTimer?.cancel();
    _eventTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _processEvents();
    });
  }

  void _processEvents() {
    if (_eventQueue.isEmpty) return;

    final event = _eventQueue.removeAt(0);

    // 관련 스크립트 찾기
    final scripts = _scripts.values
        .where((s) => s.source.contains('on${_capitalize(event.name)}'))
        .toList();

    for (final script in scripts) {
      executeScript(
        scriptId: script.id,
        event: event,
      );
    }

    _eventController.add(event);
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  /// 스크립트 등록
  Future<void> registerScript({
    required String id,
    required String name,
    required String description,
    required ScriptType type,
    required String source,
    bool autoReload = false,
  }) async {
    final script = GameScript(
      id: id,
      name: name,
      description: description,
      type: type,
      source: source,
      status: ScriptStatus.idle,
      autoReload: autoReload,
    );

    _scripts[id] = script;
    _scriptController.add(script);

    // 저장
    await _saveScript(script);

    debugPrint('[Scripting] Script registered: $id');
  }

  /// 스크립트 수정
  Future<void> updateScript({
    required String scriptId,
    String? name,
    String? description,
    String? source,
    bool? autoReload,
  }) async {
    final script = _scripts[scriptId];
    if (script == null) return;

    final updated = GameScript(
      id: script.id,
      name: name ?? script.name,
      description: description ?? script.description,
      type: script.type,
      source: source ?? script.source,
      status: script.status,
      lastExecuted: script.lastExecuted,
      executionHistory: script.executionHistory,
      autoReload: autoReload ?? script.autoReload,
    );

    _scripts[scriptId] = updated;
    _scriptController.add(updated);

    await _saveScript(updated);

    debugPrint('[Scripting] Script updated: $scriptId');
  }

  /// 스크립트 삭제
  Future<void> deleteScript(String scriptId) async {
    _scripts.remove(scriptId);
    await _prefs?.remove('script_$scriptId');
    debugPrint('[Scripting] Script deleted: $scriptId');
  }

  /// 스크립트 실행
  Future<ScriptResult> executeScript({
    required String scriptId,
    Map<String, dynamic>? args,
    ScriptEvent? event,
  }) async {
    final script = _scripts[scriptId];
    if (script == null) {
      return ScriptResult(
        scriptId: scriptId,
        success: false,
        errorMessage: 'Script not found',
        executionTime: Duration.zero,
      );
    }

    final startTime = DateTime.now();

    try {
      // 컨텍스트 생성
      final context = _contexts[scriptId] ?? ScriptContext(
        id: 'context_$scriptId',
        variables: args ?? {},
        allowedAPIs: _getAllowedAPIs(script),
        isSandboxed: true,
      );

      // 스크립트 실행 (시뮬레이션)
      final result = await _execute(script, context, event);

      final executionTime = DateTime.now().difference(startTime);

      final scriptResult = ScriptResult(
        scriptId: scriptId,
        success: true,
        returnValue: result,
        executionTime: executionTime,
      );

      // 실행 기록 추가
      final updatedScript = GameScript(
        id: script.id,
        name: script.name,
        description: script.description,
        type: script.type,
        source: script.source,
        status: ScriptStatus.completed,
        lastExecuted: DateTime.now(),
        executionHistory: [scriptResult, ...script.executionHistory],
        autoReload: script.autoReload,
      );

      _scripts[scriptId] = updatedScript;
      _scriptController.add(updatedScript);
      _resultController.add(scriptResult);

      debugPrint('[Scripting] Script executed: $scriptId');

      return scriptResult;
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);

      final scriptResult = ScriptResult(
        scriptId: scriptId,
        success: false,
        errorMessage: e.toString(),
        executionTime: executionTime,
      );

      _resultController.add(scriptResult);

      debugPrint('[Scripting] Script error: $scriptId - $e');

      return scriptResult;
    }
  }

  List<String> _getAllowedAPIs(GameScript script) {
    return [
      'giveReward',
      'initializeBattle',
      'log',
      'setVariable',
      'getVariable',
    ];
  }

  Future<dynamic> _execute(
    GameScript script,
    ScriptContext context,
    ScriptEvent? event,
  ) async {
    // 실제 Lua/JavaScript 엔진 실행 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 100));

    // 스크립트 분석 및 실행
    if (script.source.contains('onLogin')) {
      return 'Login reward granted';
    } else if (script.source.contains('onBattleStart')) {
      return 'Battle initialized';
    }

    return 'Script executed';
  }

  /// 핫 리로드
  Future<void> hotReload(String scriptId) async {
    final script = _scripts[scriptId];
    if (script == null || !script.autoReload) return;

    // 스크립트 소스 재로드
    await updateScript(scriptId: scriptId);

    debugPrint('[Scripting] Hot reloaded: $scriptId');
  }

  /// 모든 스크립트 핫 리로드
  Future<void> hotReloadAll() async {
    for (final scriptId in _scripts.keys) {
      await hotReload(scriptId);
    }
  }

  /// 이벤트 발생
  void fireEvent({
    required String name,
    Map<String, dynamic> data = const {},
  }) {
    final event = ScriptEvent(
      name: name,
      data: data,
      timestamp: DateTime.now(),
    );

    _eventQueue.add(event);

    debugPrint('[Scripting] Event fired: $name');
  }

  /// 컨텍스트 생성
  void createContext({
    required String scriptId,
    Map<String, dynamic> variables = const {},
    List<String> allowedAPIs = const [],
    bool isSandboxed = true,
  }) {
    final context = ScriptContext(
      id: 'context_$scriptId',
      variables: variables,
      allowedAPIs: allowedAPIs,
      isSandboxed: isSandboxed,
    );

    _contexts[scriptId] = context;

    debugPrint('[Scripting] Context created: $scriptId');
  }

  /// 변수 설정
  void setVariable({
    required String scriptId,
    required String key,
    required dynamic value,
  }) {
    final context = _contexts[scriptId];
    if (context == null) return;

    final updatedVariables = Map<String, dynamic>.from(context.variables);
    updatedVariables[key] = value;

    final updated = ScriptContext(
      id: context.id,
      variables: updatedVariables,
      allowedAPIs: context.allowedAPIs,
      isSandboxed: context.isSandboxed,
    );

    _contexts[scriptId] = updated;

    debugPrint('[Scripting] Variable set: $key = $value');
  }

  /// 변수 조회
  dynamic getVariable({
    required String scriptId,
    required String key,
  }) {
    final context = _contexts[scriptId];
    if (context == null) return null;

    return context.variables[key];
  }

  /// 스크립트 조회
  GameScript? getScript(String scriptId) {
    return _scripts[scriptId];
  }

  /// 모든 스크립트 조회
  List<GameScript> getScripts({ScriptType? type}) {
    var scripts = _scripts.values.toList();

    if (type != null) {
      scripts = scripts.where((s) => s.type == type).toList();
    }

    return scripts;
  }

  /// 스크립트 검증
  Future<bool> validateScript(String source, ScriptType type) async {
    // 스크립트 문법 검증 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 100));

    // 기본 검사
    if (source.isEmpty) return false;
    if (source.contains('syntax_error')) return false;

    return true;
  }

  /// 스크립트 컴파일
  Future<String> compileScript(String source, ScriptType type) async {
    // 스크립트 컴파일 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 200));

    // 바이트코드 생성 (시뮬레이션)
    final bytecode = base64Encode(utf8.encode(source));

    return bytecode;
  }

  /// 스크립트 내보내기
  String exportScript(String scriptId) {
    final script = _scripts[scriptId];
    if (script == null) throw Exception('Script not found');

    return jsonEncode({
      'id': script.id,
      'name': script.name,
      'description': script.description,
      'type': script.type.name,
      'source': script.source,
      'version': '1.0',
    });
  }

  /// 스크립트 가져오기
  Future<void> importScript(String jsonData) async {
    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    await registerScript(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      type: ScriptType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ScriptType.lua,
      ),
      source: data['source'] as String,
    );
  }

  Future<void> _saveScript(GameScript script) async {
    await _prefs?.setString('script_${script.id}', jsonEncode({
      'id': script.id,
      'name': script.name,
      'description': script.description,
      'type': script.type.name,
      'source': script.source,
      'autoReload': script.autoReload,
    }));
  }

  void dispose() {
    _eventTimer?.cancel();
    _resultController.close();
    _eventController.close();
    _scriptController.close();
  }
}

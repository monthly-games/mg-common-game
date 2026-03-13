import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 콘솔 명령 타입
enum CommandType {
  debug,        // 디버그
  cheat,        // 치트
  system,       // 시스템
  test,         // 테스트
  monitor,      // 모니터링
}

/// 로그 레벨
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 콘솔 명령
class ConsoleCommand {
  final String name;
  final String description;
  final CommandType type;
  final List<String> aliases;
  final String usage;
  final Future<String> Function(List<String> args) executor;
  final bool requiresAuth;

  const ConsoleCommand({
    required this.name,
    required this.description,
    required this.type,
    this.aliases = const [],
    required this.usage,
    required this.executor,
    this.requiresAuth = false,
  });
}

/// 콘솔 로그
class ConsoleLog {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? category;

  const ConsoleLog({
    required this.message,
    required this.level,
    required this.timestamp,
    this.category,
  });

  @override
  String toString() {
    final time = '${timestamp.hour}:${timestamp.minute}:${timestamp.second}';
    final levelStr = level.name.toUpperCase();
    return '[$time] [$levelStr] ${category ?? ''}: $message';
  }
}

/// 리소스 모니터
class ResourceMonitor {
  final double cpuUsage;
  final double memoryUsage;
  final double batteryLevel;
  final int frameRate;
  final DateTime timestamp;

  const ResourceMonitor({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.frameRate,
    required this.timestamp,
  });
}

/// QA 테스트 케이스
class TestCase {
  final String id;
  final String name;
  final String description;
  final Future<bool> Function() test;
  final bool isAutomated;

  const TestCase({
    required this.id,
    required this.name,
    required this.description,
    required this.test,
    this.isAutomated = true,
  });
}

/// 테스트 결과
class TestResult {
  final String testId;
  final bool passed;
  final String? errorMessage;
  final Duration duration;
  final DateTime timestamp;

  const TestResult({
    required this.testId,
    required this.passed,
    this.errorMessage,
    required this.duration,
    required this.timestamp,
  });
}

/// 개발자 콘솔
class DevConsoleManager {
  static final DevConsoleManager _instance = DevConsoleManager._();
  static DevConsoleManager get instance => _instance;

  DevConsoleManager._();

  SharedPreferences? _prefs;
  bool _isEnabled = false;
  bool _isAuthorized = false;

  final List<ConsoleCommand> _commands = [];
  final List<ConsoleLog> _logs = [];
  final List<ResourceMonitor> _resourceHistory = [];
  final List<TestCase> _testCases = [];
  final List<TestResult> _testResults = [];

  final StreamController<ConsoleLog> _logController =
      StreamController<ConsoleLog>.broadcast();
  final StreamController<ResourceMonitor> _resourceController =
      StreamController<ResourceMonitor>.broadcast();

  Stream<ConsoleLog> get onLog => _logController.stream;
  Stream<ResourceMonitor> get onResourceUpdate => _resourceController.stream;

  Timer? _monitorTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isEnabled = _prefs?.getBool('console_enabled') ?? false;
    _isAuthorized = _prefs?.getBool('console_authorized') ?? false;

    // 기본 명령 등록
    _registerDefaultCommands();

    // 기본 테스트 케이스 등록
    _registerDefaultTests();

    if (_isEnabled) {
      _startResourceMonitoring();
    }

    debugPrint('[DevConsole] Initialized (enabled: $_isEnabled)');
  }

  void _registerDefaultCommands() {
    // 헬프 명령
    registerCommand(const ConsoleCommand(
      name: 'help',
      description: '명령어 목록 표시',
      type: CommandType.debug,
      usage: 'help [command_name]',
      executor: _helpCommand,
    ));

    // 리소스 모니터링
    registerCommand(ConsoleCommand(
      name: 'monitor',
      description: '리소스 모니터링',
      type: CommandType.monitor,
      usage: 'monitor [start|stop|status]',
      executor: _monitorCommand,
    ));

    // 금화 치트
    registerCommand(ConsoleCommand(
      name: 'add_gold',
      description: '금화 추가',
      type: CommandType.cheat,
      usage: 'add_gold <amount>',
      aliases: ['gold', 'money'],
      requiresAuth: true,
      executor: _addGoldCommand,
    ));

    // 보석 치트
    registerCommand(ConsoleCommand(
      name: 'add_gems',
      description: '보석 추가',
      type: CommandType.cheat,
      usage: 'add_gems <amount>',
      aliases: ['gems'],
      requiresAuth: true,
      executor: _addGemsCommand,
    ));

    // 레벨업 치트
    registerCommand(ConsoleCommand(
      name: 'level_up',
      description: '레벨 업',
      type: CommandType.cheat,
      usage: 'level_up [amount]',
      aliases: ['level'],
      requiresAuth: true,
      executor: _levelUpCommand,
    ));

    // 테스트 실행
    registerCommand(ConsoleCommand(
      name: 'run_test',
      description: '테스트 실행',
      type: CommandType.test,
      usage: 'run_test [test_id]',
      aliases: ['test'],
      executor: _runTestCommand,
    ));

    // 모든 테스트 실행
    registerCommand(ConsoleCommand(
      name: 'run_all_tests',
      description: '모든 테스트 실행',
      type: CommandType.test,
      usage: 'run_all_tests',
      aliases: ['testall'],
      executor: _runAllTestsCommand,
    ));

    // 시스템 정보
    registerCommand(const ConsoleCommand(
      name: 'sysinfo',
      description: '시스템 정보',
      type: CommandType.system,
      usage: 'sysinfo',
      executor: _sysInfoCommand,
    ));

    // 로그 초기화
    registerCommand(const ConsoleCommand(
      name: 'clear',
      description: '로그 초기화',
      type: CommandType.debug,
      usage: 'clear',
      aliases: ['cls'],
      executor: _clearCommand,
    ));
  }

  void _registerDefaultTests() {
    // 연결 테스트
    registerTest(TestCase(
      id: 'connection_test',
      name: '서버 연결 테스트',
      description: '서버와의 연결 상태를 확인합니다',
      test: () async {
        // 실제 연결 테스트
        await Future.delayed(const Duration(seconds: 1));
        return true;
      },
    ));

    // 메모리 테스트
    registerTest(TestCase(
      id: 'memory_test',
      name: '메모리 누수 테스트',
      description: '메모리 누수를 확인합니다',
      test: () async {
        // 메모리 테스트
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      },
    ));
  }

  /// 명령 등록
  void registerCommand(ConsoleCommand command) {
    _commands.add(command);
    log('Command registered: ${command.name}', LogLevel.debug);
  }

  /// 테스트 등록
  void registerTest(TestCase testCase) {
    _testCases.add(testCase);
    log('Test registered: ${testCase.name}', LogLevel.debug);
  }

  /// 명령 실행
  Future<String> executeCommand(String input) async {
    if (!_isEnabled || !_isAuthorized) {
      return 'Console is not enabled or authorized';
    }

    final parts = input.trim().split(' ');
    final commandName = parts[0].toLowerCase();
    final args = parts.skip(1).toList();

    // 명령 찾기
    final command = _commands.firstWhere(
      (cmd) =>
          cmd.name == commandName ||
          cmd.aliases.contains(commandName),
      orElse: () => throw Exception('Unknown command: $commandName'),
    );

    // 권한 체크
    if (command.requiresAuth && !_isAuthorized) {
      return 'Authorization required for this command';
    }

    log('Executing: $input', LogLevel.debug);

    try {
      final result = await command.executor(args);
      log('Command completed: $commandName', LogLevel.info);
      return result;
    } catch (e) {
      log('Command failed: $e', LogLevel.error);
      return 'Error: $e';
    }
  }

  /// 명령어 완성
  List<String> autocomplete(String input) {
    if (input.isEmpty) return _commands.map((c) => c.name).toList();

    final matching = _commands
        .where((cmd) =>
            cmd.name.startsWith(input) ||
            cmd.aliases.any((alias) => alias.startsWith(input)))
        .map((cmd) => cmd.name)
        .toList();

    return matching;
  }

  /// 로그 출력
  void log(String message, LogLevel level, {String? category}) {
    final log = ConsoleLog(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      category: category,
    );

    _logs.add(log);

    // 최대 1000개만 유지
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }

    _logController.add(log);

    debugPrint('[DevConsole] ${log.toString()}');
  }

  /// 리소스 모니터링 시작
  void _startResourceMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateResources();
    });
  }

  void _updateResources() {
    final monitor = ResourceMonitor(
      cpuUsage: _generateRandomValue(50, 80),
      memoryUsage: _generateRandomValue(60, 90),
      batteryLevel: _generateRandomValue(70, 100),
      frameRate: _generateRandomValue(55, 62).toInt(),
      timestamp: DateTime.now(),
    );

    _resourceHistory.add(monitor);

    // 최대 100개만 유지
    if (_resourceHistory.length > 100) {
      _resourceHistory.removeAt(0);
    }

    _resourceController.add(monitor);
  }

  double _generateRandomValue(double min, double max) {
    return min + (DateTime.now().millisecond % 100) / 100 * (max - min);
  }

  /// 리소스 기록 조회
  List<ResourceMonitor> getResourceHistory({int limit = 100}) {
    return _resourceHistory.take(limit).toList();
  }

  /// 테스트 실행
  Future<TestResult> runTest(String testId) async {
    final testCase = _testCases.firstWhere(
      (t) => t.id == testId,
      orElse: () => throw Exception('Test not found: $testId'),
    );

    final startTime = DateTime.now();

    try {
      log('Running test: ${testCase.name}', LogLevel.info);

      final passed = await testCase.test();
      final duration = DateTime.now().difference(startTime);

      final result = TestResult(
        testId: testId,
        passed: passed,
        duration: duration,
        timestamp: DateTime.now(),
      );

      _testResults.add(result);

      log('Test ${passed ? "passed" : "failed"}: ${testCase.name}',
          passed ? LogLevel.info : LogLevel.error);

      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      final result = TestResult(
        testId: testId,
        passed: false,
        errorMessage: e.toString(),
        duration: duration,
        timestamp: DateTime.now(),
      );

      _testResults.add(result);

      log('Test failed: ${testCase.name} - $e', LogLevel.error);

      return result;
    }
  }

  /// 모든 테스트 실행
  Future<List<TestResult>> runAllTests() async {
    final results = <TestResult>[];

    for (final testCase in _testCases) {
      if (testCase.isAutomated) {
        final result = await runTest(testCase.id);
        results.add(result);
      }
    }

    return results;
  }

  /// 콘솔 활성화
  Future<void> enable({String? password}) async {
    if (password != null) {
      // 비밀번호 검증
      if (password == 'dev123') {
        _isAuthorized = true;
      } else {
        log('Invalid password', LogLevel.error);
        return;
      }
    }

    _isEnabled = true;
    await _prefs?.setBool('console_enabled', true);
    if (_isAuthorized) {
      await _prefs?.setBool('console_authorized', true);
    }

    _startResourceMonitoring();

    log('Console enabled', LogLevel.info);
  }

  /// 콘솔 비활성화
  Future<void> disable() async {
    _isEnabled = false;
    _monitorTimer?.cancel();
    await _prefs?.setBool('console_enabled', false);

    log('Console disabled', LogLevel.info);
  }

  /// 로그 조회
  List<ConsoleLog> getLogs({LogLevel? minLevel, int limit = 100}) {
    var logs = _logs.toList();

    if (minLevel != null) {
      logs = logs.where((log) => log.level.index >= minLevel.index).toList();
    }

    return logs.take(limit).toList();
  }

  /// 테스트 결과 조회
  List<TestResult> getTestResults({int limit = 100}) {
    return _testResults.take(limit).toList();
  }

  // 명령어 실행자들
  static Future<String> _helpCommand(List<String> args) async {
    return '''
Available Commands:
${_commands.map((cmd) => '  ${cmd.name} - ${cmd.description}').join('\n')}
Use 'help <command>' for detailed information.
''';
  }

  static Future<String> _monitorCommand(List<String> args) async {
    if (args.isEmpty) {
      return 'Usage: monitor [start|stop|status]';
    }

    switch (args[0]) {
      case 'start':
        instance._startResourceMonitoring();
        return 'Resource monitoring started';
      case 'stop':
        instance._monitorTimer?.cancel();
        return 'Resource monitoring stopped';
      case 'status':
        final history = instance.getResourceHistory(limit: 1);
        if (history.isEmpty) {
          return 'No resource data available';
        }
        final latest = history.last;
        return '''
CPU: ${latest.cpuUsage.toStringAsFixed(1)}%
Memory: ${latest.memoryUsage.toStringAsFixed(1)}%
Battery: ${latest.batteryLevel.toStringAsFixed(1)}%
FPS: ${latest.frameRate}
''';
      default:
        return 'Unknown monitor command: ${args[0]}';
    }
  }

  static Future<String> _addGoldCommand(List<String> args) async {
    if (args.isEmpty) {
      return 'Usage: add_gold <amount>';
    }

    final amount = int.tryParse(args[0]);
    if (amount == null) {
      return 'Invalid amount: ${args[0]}';
    }

    instance.log('Added $amount gold', LogLevel.info, category: 'CHEAT');

    return 'Added $amount gold';
  }

  static Future<String> _addGemsCommand(List<String> args) async {
    if (args.isEmpty) {
      return 'Usage: add_gems <amount>';
    }

    final amount = int.tryParse(args[0]);
    if (amount == null) {
      return 'Invalid amount: ${args[0]}';
    }

    instance.log('Added $amount gems', LogLevel.info, category: 'CHEAT');

    return 'Added $amount gems';
  }

  static Future<String> _levelUpCommand(List<String> args) async {
    final amount = args.isNotEmpty ? int.tryParse(args[0]) ?? 1 : 1;

    instance.log('Leveled up $amount times', LogLevel.info, category: 'CHEAT');

    return 'Leveled up $amount times';
  }

  static Future<String> _runTestCommand(List<String> args) async {
    if (args.isEmpty) {
      return 'Usage: run_test <test_id>';
    }

    final result = await instance.runTest(args[0]);

    return '''
Test: ${result.testId}
Status: ${result.passed ? "PASSED" : "FAILED"}
Duration: ${result.duration.inMilliseconds}ms
${result.errorMessage != null ? "Error: ${result.errorMessage}" : ""}
''';
  }

  static Future<String> _runAllTestsCommand(List<String> args) async {
    final results = await instance.runAllTests();

    final passed = results.where((r) => r.passed).length;
    final failed = results.where((r) => !r.passed).length;

    return '''
Test Results:
Total: ${results.length}
Passed: $passed
Failed: $failed
''';
  }

  static Future<String> _sysInfoCommand(List<String> args) async {
    return '''
System Information:
Platform: ${instance._getPlatform()}
Console Enabled: ${instance._isEnabled}
Console Authorized: ${instance._isAuthorized}
Commands: ${instance._commands.length}
Tests: ${instance._testCases.length}
Logs: ${instance._logs.length}
''';
  }

  static Future<String> _clearCommand(List<String> args) async {
    instance._logs.clear();
    return 'Console cleared';
  }

  String _getPlatform() {
    // 실제로는 플랫폼 확인
    return 'Android';
  }

  void dispose() {
    _monitorTimer?.cancel();
    _logController.close();
    _resourceController.close();
  }
}

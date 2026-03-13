import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';

/// 수식 타입
enum FormulaType {
  arithmetic,    // 산술 연산
  exponential,    // 지수 연산
  logarithmic,    // 로그 연산
  piecewise,      // 구간별 함수
  lookupTable,    // 룩업 테이블
}

/// 수식 변수
class FormulaVariable {
  final String name;
  final double value;
  final String description;
  final double min;
  final double max;

  const FormulaVariable({
    required this.name,
    required this.value,
    required this.description,
    this.min = 0,
    this.max = double.maxFinite,
  });

  FormulaVariable copyWith({double? value}) {
    return FormulaVariable(
      name: name,
      value: value ?? this.value,
      description: description,
      min: min,
      max: max,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'description': description,
        'min': min,
        'max': max,
      };

  factory FormulaVariable.fromJson(Map<String, dynamic> json) => FormulaVariable(
        name: json['name'] as String,
        value: (json['value'] as num).toDouble(),
        description: json['description'] as String,
        min: (json['min'] as num?)?.toDouble() ?? 0,
        max: (json['max'] as num?)?.toDouble() ?? double.maxFinite,
      );
}

/// 수식 정의
class GameFormula {
  final String id;
  final String name;
  final String description;
  final FormulaType type;
  final String expression;
  final Map<String, double> parameters;
  final DateTime version;
  final bool isActive;

  const GameFormula({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.expression,
    required this.parameters,
    required this.version,
    this.isActive = true,
  });

  /// 수식 계산
  double evaluate(Map<String, double> variables) {
    final mergedParams = {...parameters, ...variables};

    switch (type) {
      case FormulaType.arithmetic:
        return _evaluateArithmetic(expression, mergedParams);

      case FormulaType.exponential:
        return _evaluateExponential(expression, mergedParams);

      case FormulaType.logarithmic:
        return _evaluateLogarithmic(expression, mergedParams);

      case FormulaType.piecewise:
        return _evaluatePiecewise(expression, mergedParams);

      case FormulaType.lookupTable:
        return _evaluateLookupTable(expression, mergedParams);

      default:
        return 0;
    }
  }

  double _evaluateArithmetic(String expr, Map<String, double> params) {
    // 간단한 산술 연산 평가
    String evalExpr = expr;
    for (final entry in params.entries) {
      evalExpr = evalExpr.replaceAll('${entry.key}', entry.value.toString());
    }

    try {
      // 안전한 계산 (실제로는 수식 파서 사용 권장)
      final result = _safeEval(evalExpr);
      return result;
    } catch (e) {
      return 0;
    }
  }

  double _evaluateExponential(String expr, Map<String, double> params) {
    final base = params['base'] ?? 2.0;
    final exponent = params['x'] ?? 1.0;
    return pow(base, exponent).toDouble();
  }

  double _evaluateLogarithmic(String expr, Map<String, double> params) {
    final x = params['x'] ?? 1.0;
    final base = params['base'] ?? 2.0;
    return log(x) / log(base);
  }

  double _evaluatePiecewise(String expr, Map<String, double> params) {
    // 구간별 함수
    final x = params['x'] ?? 0;

    if (x < 10) return x * 1.5;
    if (x < 20) return x * 1.2;
    return x;
  }

  double _evaluateLookupTable(String expr, Map<String, double> params) {
    // 룩업 테이블에서 값 찾기
    final x = params['x'] ?? 0;
    final index = x.clamp(0, 100).toInt();

    // 실제로는 룩업 테이블 데이터 사용
    return index.toDouble();
  }

  double _safeEval(String expr) {
    // 매우 단순한 계산만 지원 (보안을 위해)
    final tokens = expr.split(RegExp(r'([+\-*/])'));

    if (tokens.length == 1) {
      return double.tryParse(tokens[0]) ?? 0;
    }

    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'expression': expression,
        'parameters': parameters,
        'version': version.toIso8601String(),
        'isActive': isActive,
      };

  factory GameFormula.fromJson(Map<String, dynamic> json) => GameFormula(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: FormulaType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => FormulaType.arithmetic,
        ),
        expression: json['expression'] as String,
        parameters: (json['parameters'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        version: DateTime.parse(json['version'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );
}

/// 밸런스 시뮬레이션 결과
class BalanceSimulationResult {
  final String formulaId;
  final String scenarioName;
  final Map<String, double> inputs;
  final double output;
  final DateTime simulatedAt;

  const BalanceSimulationResult({
    required this.formulaId,
    required this.scenarioName,
    required this.inputs,
    required this.output,
    required this.simulatedAt,
  });

  /// 기준 비교
  bool meetsBaseline(double baseline) {
    return output >= baseline;
  }

  double differenceFromBaseline(double baseline) {
    return output - baseline;
  }
}

/// 밸런싱 매니저
class BalanceManager {
  static final BalanceManager _instance = BalanceManager._();
  static BalanceManager get instance => _instance;

  BalanceManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;

  final Map<String, GameFormula> _formulas = {};
  final Map<String, FormulaVariable> _variables = {};
  final List<BalanceSimulationResult> _simulations = [];

  final StreamController<GameFormula> _formulaController =
      StreamController<GameFormula>.broadcast();
  final StreamController<FormulaVariable> _variableController =
      StreamController<FormulaVariable>.broadcast();

  // Getters
  List<GameFormula> get formulas => _formulas.values.toList();
  List<FormulaVariable> get variables => _variables.values.toList();
  Stream<GameFormula> get onFormulaUpdate => _formulaController.stream;
  Stream<FormulaVariable> get onVariableUpdate => _variableController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 데이터 로드
    await _loadFormulas();
    await _loadVariables();

    // 기본 수식 등록
    _registerDefaultFormulas();

    debugPrint('[Balance] Initialized');
  }

  Future<void> _loadFormulas() async {
    final formulasJson = _prefs!.getStringList('balance_formulas');
    if (formulasJson != null) {
      for (final json in formulasJson) {
        final formula = GameFormula.fromJson(jsonDecode(json) as Map<String, dynamic>);
        _formulas[formula.id] = formula;
      }
    }
  }

  Future<void> _loadVariables() async {
    final varsJson = _prefs!.getString('balance_variables');
    if (varsJson != null) {
      final json = jsonDecode(varsJson) as Map<String, dynamic>;
      for (final entry in json.entries) {
        _variables[entry.key] = FormulaVariable.fromJson(entry.value as Map<String, dynamic>);
      }
    }
  }

  void _registerDefaultFormulas() {
    if (_formulas.isEmpty) {
      // 경험치 수식
      _formulas['exp_to_level'] = GameFormula(
        id: 'exp_to_level',
        name: '레벨별 경험치',
        description: '다음 레벨까지 필요한 경험치',
        type: FormulaType.exponential,
        expression: 'level * level * 100',
        parameters: {'level': 1.0},
        version: DateTime.now(),
      );

      // 보상 코인 수식
      _formulas['reward_coins'] = GameFormula(
        id: 'reward_coins',
        name: '퀘스트 보상 코인',
        description: '난이도에 따른 퀘스트 보상',
        type: FormulaType.arithmetic,
        expression: 'base_reward * (1 + difficulty * 0.5)',
        parameters: {
          'base_reward': 100.0,
          'difficulty': 1.0,
        },
        version: DateTime.now(),
      );

      // 승리 보너스 수식
      _formulas['win_bonus'] = GameFormula(
        id: 'win_bonus',
        name: '승리 보너스',
        description: '연속 승리에 따른 보너스',
        type: FormulaType.exponential,
        expression: 'base * (1.1 ^ win_streak)',
        parameters: {
          'base': 100.0,
          'win_streak': 1.0,
        },
        version: DateTime.now(),
      );
    }
  }

  // ============================================
  // 수식 관리
  // ============================================

  /// 수식 등록
  void registerFormula(GameFormula formula) {
    _formulas[formula.id] = formula;
    _formulaController.add(formula);

    debugPrint('[Balance] Formula registered: ${formula.name}');
  }

  /// 수식 업데이트
  Future<void> updateFormula(String formulaId, GameFormula updated) async {
    _formulas[formulaId] = updated;

    final formulasJson = _formulas.values.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs!.setStringList('balance_formulas', formulasJson);

    _formulaController.add(updated);

    // 애널리틱스
    AnalyticsManager.instance.trackEvent(
      name: 'formula_updated',
      category: EventCategory.engagement,
      properties: {
        'formula_id': formulaId,
      },
    );

    debugPrint('[Balance] Formula updated: $formulaId');
  }

  /// 수식 핫패치 (실시간 적용)
  Future<void> hotPatchFormula({
    required String formulaId,
    required String newExpression,
    Map<String, double>? newParameters,
  }) async {
    final existing = _formulas[formulaId];
    if (existing == null) return;

    final updated = GameFormula(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      type: existing.type,
      expression: newExpression,
      parameters: newParameters ?? existing.parameters,
      version: DateTime.now(),
    );

    await updateFormula(formulaId, updated);

    // 모든 클라이언트에 푸시 (실제로는 웹소켓 등)
    debugPrint('[Balance] Hot patch applied: $formulaId');
  }

  /// 수식 계산
  double calculate(String formulaId, Map<String, double> inputs) {
    final formula = _formulas[formulaId];
    if (formula == null) {
      debugPrint('[Balance] Formula not found: $formulaId');
      return 0;
    }

    return formula.evaluate(inputs);
  }

  // ============================================
  // 변수 관리
  // ============================================

  /// 변수 등록
  void registerVariable(FormulaVariable variable) {
    _variables[variable.name] = variable;
    _variableController.add(variable);

    debugPrint('[Balance] Variable registered: ${variable.name}');
  }

  /// 변수 값 업데이트
  Future<void> updateVariable(String name, double newValue) async {
    final existing = _variables[name];
    if (existing == null) return;

    final updated = existing.copyWith(value: newValue.clamp(existing.min, existing.max));
    _variables[name] = updated;

    final varsJson = jsonEncode(_variables);
    await _prefs!.setString('balance_variables', varsJson);

    _variableController.add(updated);

    debugPrint('[Balance] Variable updated: $name = $newValue');
  }

  /// 변수 값 가져오기
  FormulaVariable? getVariable(String name) {
    return _variables[name];
  }

  // ============================================
  // 시뮬레이션
  // ============================================

  /// 시뮬레이션 실행
  BalanceSimulationResult simulate({
    required String formulaId,
    required String scenarioName,
    required Map<String, double> inputs,
  }) {
    final output = calculate(formulaId, inputs);

    final result = BalanceSimulationResult(
      formulaId: formulaId,
      scenarioName: scenarioName,
      inputs: inputs,
      output: output,
      simulatedAt: DateTime.now(),
    );

    _simulations.add(result);

    // 애널리틱스
    AnalyticsManager.instance.trackEvent(
      name: 'balance_simulation',
      category: EventCategory.engagement,
      properties: {
        'formula_id': formulaId,
        'scenario': scenarioName,
        'output': output,
      },
    );

    return result;
  }

  /// 다중 시나리오 시뮬레이션
  List<BalanceSimulationResult> simulateScenarios({
    required String formulaId,
    required List<Map<String, double>> scenarios,
  }) {
    return scenarios.map((inputs) {
      return simulate(
        formulaId: formulaId,
        scenarioName: 'scenario_${scenarios.indexOf(inputs)}',
        inputs: inputs,
      );
    }).toList();
  }

  /// 밸런스 비교
  Map<String, dynamic> compareBalance({
    required String formulaId,
    required List<Map<String, double>> scenarios,
    required double baseline,
  }) {
    final results = simulateScenarios(formulaId: formulaId, scenarios: scenarios);

    int aboveBaseline = 0;
    int belowBaseline = 0;
    double totalDiff = 0;

    for (final result in results) {
      if (result.meetsBaseline(baseline)) {
        aboveBaseline++;
      } else {
        belowBaseline++;
      }
      totalDiff += result.differenceFromBaseline(baseline);
    }

    return {
      'formula_id': formulaId,
      'scenarios_tested': scenarios.length,
      'above_baseline': aboveBaseline,
      'below_baseline': belowBaseline,
      'baseline': baseline,
      'average_difference': totalDiff / scenarios.length,
      'pass_rate': aboveBaseline / scenarios.length,
    };
  }

  // ============================================
  // 편집기
  // ============================================

  /// 수식 편집기
  String buildFormula({
    required FormulaType type,
    required String baseValue,
    List<String> modifiers = const [],
  }) {
    switch (type) {
      case FormulaType.arithmetic:
        if (modifiers.isEmpty) return baseValue;
        return modifiers.join(' + ') + ' * $baseValue';

      case FormulaType.exponential:
        return '${modifiers.first} ^ $baseValue';

      case FormulaType.logarithmic:
        return 'log($baseValue) / log(${modifiers.first})';

      case FormulaType.piecewise:
        return 'if ($baseValue < 10) then $baseValue * 1.5 else $baseValue';

      case FormulaType.lookupTable:
        return 'lookup($baseValue)';
    }
  }

  /// 수식 검증
  bool validateFormula(String expression) {
    try {
      // 기본 문법 검사
      if (expression.isEmpty) return false;

      // 안전하지 않은 문자 검사
      final dangerous = ['eval', 'exec', 'import', 'os.', 'system'];
      for (final dangerousStr in dangerous) {
        if (expression.contains(dangerousStr)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // A/B 테스트 통합
  // ============================================

  /// A/B 테스트를 위한 수식 비교
  Future<Map<String, dynamic>> compareFormulasForAB({
    required String formulaAId,
    required String formulaBId,
    required Map<String, double> testInputs,
  }) async {
    final resultA = calculate(formulaAId, testInputs);
    final resultB = calculate(formulaBId, testInputs);

    return {
      'formula_a_id': formulaAId,
      'formula_b_id': formulaBId,
      'result_a': resultA,
      'result_b': resultB,
      'difference': resultB - resultA,
      'difference_percent': (resultB - resultA) / resultA * 100,
    };
  }

  // ============================================
  // 리포트
  // ============================================

  /// 밸런스 리포트 생성
  String generateBalanceReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== Game Balance Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln();

    buffer.writeln('Formulas (${_formulas.length}):');
    for (final formula in _formulas.values) {
      buffer.writeln('  ${formula.name} (${formula.id})');
      buffer.writeln('    Type: ${formula.type.name}');
      buffer.writeln('    Expression: ${formula.expression}');
      buffer.writeln('    Active: ${formula.isActive}');
      buffer.writeln();
    }

    buffer.writeln('Variables (${_variables.length}):');
    for (final variable in _variables.values) {
      buffer.writeln('  ${variable.name}: ${variable.value}');
      buffer.writeln('    ${variable.description}');
      buffer.writeln();
    }

    buffer.writeln('Recent Simulations (${_simulations.length}):');
    for (final sim in _simulations.take(10)) {
      buffer.writeln('  ${sim.scenarioName}: ${sim.output}');
    }

    return buffer.toString();
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _formulaController.close();
    _variableController.close();
  }

  bool get _isInitialized => _prefs != null;
}

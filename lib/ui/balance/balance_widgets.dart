import 'package:flutter/material.dart';
import 'package:mg_common_game/balance/balance_manager.dart';

/// 밸런스 시스템 대시보드
class BalanceDashboard extends StatefulWidget {
  const BalanceDashboard({super.key});

  @override
  State<BalanceDashboard> createState() => _BalanceDashboardState();
}

class _BalanceDashboardState extends State<BalanceDashboard> {
  final _balanceManager = BalanceManager.instance;
  List<GameFormula> _formulas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFormulas();
  }

  Future<void> _loadFormulas() async {
    setState(() => _loading = true);

    // 모든 수식 로드
    _formulas = _balanceManager.getAllFormulas();

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('밸런스 관리'),
        actions: [
          IconButton(
            onPressed: () => _showCreateFormulaDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsOverview(),
                Expanded(
                  child: _formulas.isEmpty
                      ? const Center(child: Text('등록된 수식이 없습니다'))
                      : ListView.builder(
                          itemCount: _formulas.length,
                          itemBuilder: (context, index) {
                            final formula = _formulas[index];
                            return FormulaCard(
                              formula: formula,
                              onTap: () => _showFormulaDetail(context, formula),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('전체 수식', '${_formulas.length}'),
          _buildStat('활성화', '${_formulas.where((f) => f.isActive).length}'),
          _buildStat('비활성화', '${_formulas.where((f) => !f.isActive).length}'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  void _showCreateFormulaDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormulaEditorScreen(),
      ),
    ).then((_) => _loadFormulas());
  }

  void _showFormulaDetail(BuildContext context, GameFormula formula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormulaDetailScreen(formula: formula),
      ),
    ).then((_) => _loadFormulas());
  }
}

/// 수식 카드
class FormulaCard extends StatelessWidget {
  final GameFormula formula;
  final VoidCallback? onTap;

  const FormulaCard({
    super.key,
    required this.formula,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formula.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(formula.id),
                      ],
                    ),
                  ),
                  _buildTypeChip(context),
                  if (!formula.isActive)
                    const Chip(
                      label: Text('비활성'),
                      backgroundColor: Colors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formula.expression,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: formula.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final typeInfo = _getTypeInfo(formula.type);

    return Chip(
      label: Text(typeInfo),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.blue.withOpacity(0.1),
    );
  }

  String _getTypeInfo(FormulaType type) {
    switch (type) {
      case FormulaType.arithmetic:
        return '산술';
      case FormulaType.exponential:
        return '지수';
      case FormulaType.logarithmic:
        return '로그';
      case FormulaType.piecewise:
        return '구간';
      case FormulaType.lookupTable:
        return '룩업';
    }
  }
}

/// 수식 편집 화면
class FormulaEditorScreen extends StatefulWidget {
  final GameFormula? existingFormula;

  const FormulaEditorScreen({super.key, this.existingFormula});

  @override
  State<FormulaEditorScreen> createState() => _FormulaEditorScreenState();
}

class _FormulaEditorScreenState extends State<FormulaEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _expressionController = TextEditingController();
  final _descriptionController = TextEditingController();

  FormulaType _selectedType = FormulaType.arithmetic;
  Map<String, FormulaVariable> _variables = {};

  @override
  void initState() {
    super.initState();

    if (widget.existingFormula != null) {
      _loadFormula(widget.existingFormula!);
    }
  }

  void _loadFormula(GameFormula formula) {
    _idController.text = formula.id;
    _nameController.text = formula.name;
    _expressionController.text = formula.expression;
    _descriptionController.text = formula.description;
    _selectedType = formula.type;
    _variables = Map.from(formula.variables);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingFormula == null ? '수식 생성' : '수식 편집'),
        actions: [
          TextButton(
            onPressed: _saveFormula,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '수식 ID',
                border: OutlineInputBorder(),
              ),
              enabled: widget.existingFormula == null,
              validator: (value) => value?.isEmpty ?? true ? '필수 항목' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '수식 이름',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '필수 항목' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FormulaType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '수식 타입',
                border: OutlineInputBorder(),
              ),
              items: FormulaType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeName(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expressionController,
              decoration: const InputDecoration(
                labelText: '수식',
                border: OutlineInputBorder(),
                helperText: '예: base * multiplier + bonus',
              ),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace'),
              validator: (value) => value?.isEmpty ?? true ? '필수 항목' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text('변수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._variables.entries.map((entry) {
              return VariableTile(
                name: entry.key,
                variable: entry.value,
                onRemove: () {
                  setState(() => _variables.remove(entry.key));
                },
              );
            }).toList(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showAddVariableDialog,
              icon: const Icon(Icons.add),
              label: const Text('변수 추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVariableDialog() {
    final nameController = TextEditingController();
    final defaultController = TextEditingController(text: '0');
    final minController = TextEditingController(text: '0');
    final maxController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변수 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '변수명'),
            ),
            TextField(
              controller: defaultController,
              decoration: const InputDecoration(labelText: '기본값'),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    decoration: const InputDecoration(labelText: '최소값'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    decoration: const InputDecoration(labelText: '최대값'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _variables[nameController.text] = FormulaVariable(
                  defaultValue: double.tryParse(defaultController.text) ?? 0,
                  min: double.tryParse(minController.text) ?? 0,
                  max: double.tryParse(maxController.text) ?? 100,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFormula() async {
    if (!_formKey.currentState!.validate()) return;

    final formula = GameFormula(
      id: _idController.text,
      name: _nameController.text,
      type: _selectedType,
      expression: _expressionController.text,
      variables: _variables,
      description: _descriptionController.text,
      tags: [],
    );

    await BalanceManager.instance.registerFormula(formula);

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  String _getTypeName(FormulaType type) {
    switch (type) {
      case FormulaType.arithmetic:
        return '산술';
      case FormulaType.exponential:
        return '지수';
      case FormulaType.logarithmic:
        return '로그';
      case FormulaType.piecewise:
        return '구간';
      case FormulaType.lookupTable:
        return '룩업';
    }
  }
}

/// 변수 타일
class VariableTile extends StatelessWidget {
  final String name;
  final FormulaVariable variable;
  final VoidCallback? onRemove;

  const VariableTile({
    super.key,
    required this.name,
    required this.variable,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          '기본값: ${variable.defaultValue}, 범위: ${variable.min} ~ ${variable.max}',
        ),
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete),
          color: Colors.red,
        ),
      ),
    );
  }
}

/// 수식 상세 화면
class FormulaDetailScreen extends StatefulWidget {
  final GameFormula formula;

  const FormulaDetailScreen({super.key, required this.formula});

  @override
  State<FormulaDetailScreen> createState() => _FormulaDetailScreenState();
}

class _FormulaDetailScreenState extends State<FormulaDetailScreen> {
  final _balanceManager = BalanceManager.instance;
  Map<String, double> _testInputs = {};
  double? _testResult;

  @override
  void initState() {
    super.initState();
    // 기본 테스트 값 설정
    for (final variable in widget.formula.variables.entries) {
      _testInputs[variable.key] = variable.value.defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.formula.name),
        actions: [
          IconButton(
            onPressed: () => _showHotPatchDialog(context),
            icon: const Icon(Icons.update),
            tooltip: '핫패치',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildTestSection(),
          const SizedBox(height: 24),
          _buildVariablesSection(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.formula.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('ID: ${widget.formula.id}'),
            const SizedBox(height: 8),
            Text('타입: ${_getTypeName(widget.formula.type)}'),
            const SizedBox(height: 8),
            Text('설명: ${widget.formula.description}'),
            const SizedBox(height: 16),
            const Text('수식:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                widget.formula.expression,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('수식 테스트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._testInputs.entries.map((entry) {
              final variable = widget.formula.variables[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      child: Slider(
                        value: entry.value,
                        min: variable?.min ?? 0,
                        max: variable?.max ?? 100,
                        divisions: 100,
                        label: entry.value.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() => _testInputs[entry.key] = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(entry.value.toStringAsFixed(2)),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runTest,
              child: const Text('계산 실행'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              Text(
                '결과: $_testResult',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVariablesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('변수 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...widget.formula.variables.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                subtitle: Text(
                  '기본값: ${entry.value.defaultValue}, 범위: ${entry.value.min} ~ ${entry.value.max}',
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _runTest() {
    final result = _balanceManager.calculate(widget.formula.id, _testInputs);
    setState(() => _testResult = result);
  }

  void _showHotPatchDialog(BuildContext context) {
    final expressionController = TextEditingController(text: widget.formula.expression);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('핫패치'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('수식을 즉시 업데이트합니다.'),
            const SizedBox(height: 16),
            TextField(
              controller: expressionController,
              decoration: const InputDecoration(
                labelText: '새 수식',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _balanceManager.hotPatchFormula(
                formulaId: widget.formula.id,
                newExpression: expressionController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('핫패치 완료')),
                );
              }
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }

  String _getTypeName(FormulaType type) {
    switch (type) {
      case FormulaType.arithmetic:
        return '산술';
      case FormulaType.exponential:
        return '지수';
      case FormulaType.logarithmic:
        return '로그';
      case FormulaType.piecewise:
        return '구간';
      case FormulaType.lookupTable:
        return '룩업';
    }
  }
}

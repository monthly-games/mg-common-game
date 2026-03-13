import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 템플릿 타입
enum TemplateType {
  page,           // 페이지
  widget,         // 위젯
  screen,         // 스크린
  service,        // 서비스
  model,          // 모델
  repository,     // 리포지토리
  controller,     // 컨트롤러
  middleware,     // 미들웨어
  state,          // 상태 관리
  test,           // 테스트
}

/// 코드 스타일
enum CodeStyle {
  material,       // 머테리얼
  cupertino,      // 커퍼티노
  custom,         // 커스텀
}

/// 템플릿 변수
class TemplateVariable {
  final String name;
  final String description;
  final String defaultValue;
  final bool required;

  const TemplateVariable({
    required this.name,
    required this.description,
    required this.defaultValue,
    this.required = true,
  });
}

/// 코드 템플릿
class CodeTemplate {
  final String templateId;
  final String name;
  final String description;
  final TemplateType type;
  final String content;
  final List<TemplateVariable> variables;
  final List<String> dependencies;
  final CodeStyle style;

  const CodeTemplate({
    required this.templateId,
    required this.name,
    required this.description,
    required this.type,
    required this.content,
    required this.variables,
    required this.dependencies,
    required this.style,
  });
}

/// 스캐폴딩 결과
class ScaffoldResult {
  final String projectId;
  final List<String> createdFiles;
  final List<String> errors;
  final DateTime createdAt;

  const ScaffoldResult({
    required this.projectId,
    required this.createdFiles,
    required this.errors,
    required this.createdAt,
  });

  /// 성공 여부
  bool get isSuccess => errors.isEmpty;
}

/// 파일 구조
class FileStructure {
  final String path;
  final String content;
  final String? templateId;

  const FileStructure({
    required this.path,
    required this.content,
    this.templateId,
  });
}

/// 프로젝트 설정
class ProjectConfig {
  final String projectName;
  final String organization;
  final String description;
  final CodeStyle defaultStyle;
  final List<String> enabledFeatures;
  final Map<String, dynamic> customConfig;

  const ProjectConfig({
    required this.projectName,
    required this.organization,
    required this.description,
    required this.defaultStyle,
    required this.enabledFeatures,
    required this.customConfig,
  });
}

/// 코드 생성 옵션
class CodeGenerationOptions {
  final bool addComments;
  final bool formatCode;
  final bool generateTests;
  final bool createDirectories;
  final String? outputPath;

  const CodeGenerationOptions({
    this.addComments = true,
    this.formatCode = true,
    this.generateTests = false,
    this.createDirectories = true,
    this.outputPath,
  });
}

/// 코드 템플릿 관리자
class CodeTemplateManager {
  static final CodeTemplateManager _instance =
      CodeTemplateManager._();
  static CodeTemplateManager get instance => _instance;

  CodeTemplateManager._();

  SharedPreferences? _prefs;

  final Map<String, CodeTemplate> _templates = {};
  final Map<String, ProjectConfig> _projects = {};

  final StreamController<String> _templateController =
      StreamController<String>.broadcast();
  final StreamController<ScaffoldResult> _scaffoldController =
      StreamController<ScaffoldResult>.broadcast();

  Stream<String> get onTemplateUpdate => _templateController.stream;
  Stream<ScaffoldResult> get onScaffoldComplete => _scaffoldController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 기본 템플릿 로드
    await _loadDefaultTemplates();

    debugPrint('[CodeTemplate] Initialized');
  }

  Future<void> _loadDefaultTemplates() async {
    // 페이지 템플릿
    _templates['page_material'] = CodeTemplate(
      templateId: 'page_material',
      name: '머테리얼 페이지',
      description: '머테리얼 디자인 페이지 템플릿',
      type: TemplateType.page,
      style: CodeStyle.material,
      variables: const [
        TemplateVariable(
          name: 'pageName',
          description: '페이지 이름',
          defaultValue: 'HomePage',
        ),
        TemplateVariable(
          name: 'appName',
          description: '앱 이름',
          defaultValue: 'MyApp',
        ),
      ],
      dependencies: ['package:flutter/material.dart'],
      content: _materialPageTemplate,
    );

    // 위젯 템플릿
    _templates['widget_stateful'] = CodeTemplate(
      templateId: 'widget_stateful',
      name: 'Stateful 위젯',
      description: '상태 관리 위젯 템플릿',
      type: TemplateType.widget,
      style: CodeStyle.material,
      variables: const [
        TemplateVariable(
          name: 'widgetName',
          description: '위젯 이름',
          defaultValue: 'MyWidget',
        ),
      ],
      dependencies: ['package:flutter/material.dart'],
      content: _statefulWidgetTemplate,
    );

    // 서비스 템플릿
    _templates['service_singleton'] = CodeTemplate(
      templateId: 'service_singleton',
      name: '싱글톤 서비스',
      description: '싱글톤 패턴 서비스 템플릿',
      type: TemplateType.service,
      style: CodeStyle.custom,
      variables: const [
        TemplateVariable(
          name: 'serviceName',
          description: '서비스 이름',
          defaultValue: 'MyService',
        ),
      ],
      dependencies: [],
      content: _singletonServiceTemplate,
    );

    // 모델 템플릿
    _templates['model_json'] = CodeTemplate(
      templateId: 'model_json',
      name: 'JSON 모델',
      description: 'JSON 직렬화 모델 템플릿',
      type: TemplateType.model,
      style: CodeStyle.custom,
      variables: const [
        TemplateVariable(
          name: 'modelName',
          description: '모델 이름',
          defaultValue: 'User',
        ),
      ],
      dependencies: ['dart:convert'],
      content: _jsonModelTemplate,
    );

    // 테스트 템플릿
    _templates['test_widget'] = CodeTemplate(
      templateId: 'test_widget',
      name: '위젯 테스트',
      description: '위젯 테스트 템플릿',
      type: TemplateType.test,
      style: CodeStyle.custom,
      variables: const [
        TemplateVariable(
          name: 'widgetName',
          description: '위젯 이름',
          defaultValue: 'MyWidget',
        ),
      ],
      dependencies: [
        'package:flutter_test/flutter_test.dart',
      ],
      content: _widgetTestTemplate,
    );
  }

  /// 템플릿 목록 조회
  List<CodeTemplate> getTemplates({TemplateType? type}) {
    final templates = _templates.values.toList();

    if (type != null) {
      return templates.where((t) => t.type == type).toList();
    }

    return templates;
  }

  /// 템플릿 조회
  CodeTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }

  /// 코드 생성
  String generateCode({
    required String templateId,
    required Map<String, String> variables,
  }) {
    final template = _templates[templateId];
    if (template == null) {
      throw TemplateNotFoundException('Template not found: $templateId');
    }

    // 필수 변수 체크
    for (final variable in template.variables) {
      if (variable.required && !variables.containsKey(variable.name)) {
        throw VariableMissingException(
          'Required variable missing: ${variable.name}',
        );
      }
    }

    // 변수 치환
    var code = template.content;

    for (final entry in variables.entries) {
      final placeholder = '\${{${entry.key}}}';
      code = code.replaceAll(placeholder, entry.value);
    }

    return code;
  }

  /// 파일 스캐폴딩
  Future<ScaffoldResult> scaffoldProject({
    required ProjectConfig config,
    required List<FileStructure> files,
    CodeGenerationOptions options = const CodeGenerationOptions(),
  }) async {
    final projectId = 'project_${DateTime.now().millisecondsSinceEpoch}';
    final createdFiles = <String>[];
    final errors = <String>[];

    for (final file in files) {
      try {
        // 경로 생성
        final path = _buildPath(config.projectName, file.path);

        // 디렉토리 생성
        if (options.createDirectories) {
          final directory = path.substring(0, path.lastIndexOf('/'));
          // 실제로는 디렉토리 생성 로직
        }

        // 파일 생성
        createdFiles.add(path);

        // 테스트 파일 생성
        if (options.generateTests && file.templateId != null) {
          final testPath = path.replaceAll('.dart', '_test.dart');
          final testTemplate = _getTestTemplateForType(file.templateId!);
          if (testTemplate != null) {
            createdFiles.add(testPath);
          }
        }

      } catch (e) {
        errors.add('Error creating ${file.path}: $e');
      }
    }

    final result = ScaffoldResult(
      projectId: projectId,
      createdFiles: createdFiles,
      errors: errors,
      createdAt: DateTime.now(),
    );

    _scaffoldController.add(result);

    // 프로젝트 저장
    _projects[projectId] = config;

    return result;
  }

  String _buildPath(String projectName, String relativePath) {
    return 'lib/$relativePath';
  }

  CodeTemplate? _getTestTemplateForType(String templateId) {
    switch (templateId) {
      case 'widget_stateful':
        return _templates['test_widget'];
      default:
        return null;
    }
  }

  /// 커스텀 템플릿 추가
  Future<void> addTemplate(CodeTemplate template) async {
    _templates[template.templateId] = template;
    _templateController.add(template.templateId);

    await _saveTemplates();
  }

  /// 템플릿 제거
  Future<void> removeTemplate(String templateId) async {
    _templates.remove(templateId);

    await _saveTemplates();
  }

  /// 템플릿 내보내기
  String exportTemplate(String templateId) {
    final template = _templates[templateId];
    if (template == null) {
      throw TemplateNotFoundException('Template not found: $templateId');
    }

    return jsonEncode({
      'templateId': template.templateId,
      'name': template.name,
      'description': template.description,
      'type': template.type.name,
      'content': template.content,
      'variables': template.variables.map((v) => {
        'name': v.name,
        'description': v.description,
        'defaultValue': v.defaultValue,
        'required': v.required,
      }).toList(),
      'dependencies': template.dependencies,
    });
  }

  /// 템플릿 가져오기
  Future<void> importTemplate(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      final template = CodeTemplate(
        templateId: data['templateId'] as String,
        name: data['name'] as String,
        description: data['description'] as String,
        type: TemplateType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => TemplateType.custom,
        ),
        content: data['content'] as String,
        variables: (data['variables'] as List)
            .map((v) => TemplateVariable(
              name: v['name'] as String,
              description: v['description'] as String,
              defaultValue: v['defaultValue'] as String,
              required: v['required'] as bool? ?? true,
            ))
            .toList(),
        dependencies: List<String>.from(data['dependencies'] ?? []),
        style: CodeStyle.custom,
      );

      await addTemplate(template);
    } catch (e) {
      throw TemplateImportException('Failed to import template: $e');
    }
  }

  /// 프로젝트 설정 조회
  ProjectConfig? getProject(String projectId) {
    return _projects[projectId];
  }

  Future<void> _saveTemplates() async {
    // 템플릿 저장
    debugPrint('[CodeTemplate] Templates saved');
  }

  // 템플릿 내용 상수들
  static const String _materialPageTemplate = '''
import 'package:flutter/material.dart';

class \${pageName} extends StatelessWidget {
  const \${pageName}({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\${appName}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Hello, World!'),
          ],
        ),
      ),
    );
  }
}
''';

  static const String _statefulWidgetTemplate = '''
import 'package:flutter/material.dart';

class \${widgetName} extends StatefulWidget {
  const \${widgetName}({Key? key}) : super(key: key);

  @override
  State<\${widgetName}> createState() => _\${widgetName}State();
}

class _\${widgetName}State extends State<\${widgetName}> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Your widget code here
    );
  }
}
''';

  static const String _singletonServiceTemplate = '''
class \${serviceName} {
  static final \${serviceName} _instance = \${serviceName}._();
  static \${serviceName} get instance => _instance;

  \${serviceName}._();

  // Your service code here
}
''';

  static const String _jsonModelTemplate = '''
import 'dart:convert';

class \${modelName} {
  final String id;
  final Map<String, dynamic> data;

  \${modelName}({
    required this.id,
    required this.data,
  });

  factory \${modelName}.fromJson(Map<String, dynamic> json) {
    return \${modelName}(
      id: json['id'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
''';

  static const String _widgetTestTemplate = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:\${appName}/\${widgetName}.dart';

void main() {
  group('\${widgetName} Tests', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: \${widgetName}(),
        ),
      );

      expect(find.byType(\${widgetName}), findsOneWidget);
    });
  });
}
''';
}

/// 템플릿 예외
class TemplateNotFoundException implements Exception {
  final String message;
  TemplateNotFoundException(this.message);

  @override
  String toString() => 'TemplateNotFoundException: $message';
}

class VariableMissingException implements Exception {
  final String message;
  VariableMissingException(this.message);

  @override
  String toString() => 'VariableMissingException: $message';
}

class TemplateImportException implements Exception {
  final String message;
  TemplateImportException(this.message);

  @override
  String toString() => 'TemplateImportException: $message';
}

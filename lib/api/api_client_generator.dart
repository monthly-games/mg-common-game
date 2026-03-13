import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// HTTP 메서드
enum HTTPMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options,
}

/// API 엔드포인트
class APIEndpoint {
  final String name;
  final String path;
  final HTTPMethod method;
  final String description;
  final Map<String, dynamic>? pathParams;
  final Map<String, dynamic>? queryParams;
  final Map<String, dynamic>? headers;
  final dynamic body;
  final String? responseType;

  const APIEndpoint({
    required this.name,
    required this.path,
    required this.method,
    required this.description,
    this.pathParams,
    this.queryParams,
    this.headers,
    this.body,
    this.responseType,
  });
}

/// API 스펙
class APISpec {
  final String specId;
  final String name;
  final String version;
  final String baseUrl;
  final List<APIEndpoint> endpoints;
  final Map<String, dynamic> securitySchemes;
  final Map<String, dynamic>? definitions;

  const APISpec({
    required this.specId,
    required this.name,
    required this.version,
    required this.baseUrl,
    required this.endpoints,
    required this.securitySchemes,
    this.definitions,
  });
}

/// 생성된 API 클라이언트
class GeneratedAPIClient {
  final String clientId;
  final String code;
  final String language;
  final APISpec spec;
  final DateTime generatedAt;

  const GeneratedAPIClient({
    required this.clientId,
    required this.code,
    required this.language,
    required this.spec,
    required this.generatedAt,
  });
}

/// API 요청 옵션
class APIRequestOptions {
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParams;
  final Duration? timeout;
  final bool retryOnFailure;
  final int maxRetries;

  const APIRequestOptions({
    this.headers,
    this.queryParams,
    this.timeout,
    this.retryOnFailure = false,
    this.maxRetries = 3,
  });
}

/// API 응답
class APIResponse<T> {
  final int statusCode;
  final T? data;
  final String? errorMessage;
  final Map<String, String>? headers;
  final DateTime timestamp;

  const APIResponse({
    required this.statusCode,
    this.data,
    this.errorMessage,
    this.headers,
    required this.timestamp,
  });

  /// 성공 여부
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// API 클라이언트 생성기 관리자
class APIClientGenerator {
  static final APIClientGenerator _instance =
      APIClientGenerator._();
  static APIClientGenerator get instance => _instance;

  APIClientGenerator._();

  SharedPreferences? _prefs;

  final Map<String, APISpec> _specs = {};
  final Map<String, GeneratedAPIClient> _clients = {};

  final StreamController<String> _specController =
      StreamController<String>.broadcast();
  final StreamController<GeneratedAPIClient> _clientController =
      StreamController<GeneratedAPIClient>.broadcast();

  Stream<String> get onSpecUpdate => _specController.stream;
  Stream<GeneratedAPIClient> get onClientGenerated => _clientController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 기본 스펙 로드
    await _loadDefaultSpecs();

    debugPrint('[APIClientGenerator] Initialized');
  }

  Future<void> _loadDefaultSpecs() async {
    // 샘플 API 스펙
    _specs['user_api'] = APISpec(
      specId: 'user_api',
      name: 'User API',
      version: '1.0.0',
      baseUrl: 'https://api.example.com/v1',
      endpoints: [
        APIEndpoint(
          name: 'getUser',
          path: '/users/{userId}',
          method: HTTPMethod.get,
          description: '사용자 정보 조회',
          pathParams: {'userId': 'string'},
        ),
        APIEndpoint(
          name: 'createUser',
          path: '/users',
          method: HTTPMethod.post,
          description: '사용자 생성',
        ),
        APIEndpoint(
          name: 'updateUser',
          path: '/users/{userId}',
          method: HTTPMethod.put,
          description: '사용자 정보 수정',
          pathParams: {'userId': 'string'},
        ),
        APIEndpoint(
          name: 'deleteUser',
          path: '/users/{userId}',
          method: HTTPMethod.delete,
          description: '사용자 삭제',
          pathParams: {'userId': 'string'},
        ),
      ],
      securitySchemes: {
        'bearerAuth': {'type': 'http', 'scheme': 'bearer'},
      },
    );
  }

  /// OpenAPI/Swagger 스펙에서 로드
  Future<APISpec?> loadFromOpenAPI(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseOpenAPISpec(json, url);
      }
    } catch (e) {
      debugPrint('[APIClientGenerator] Error loading OpenAPI: $e');
    }

    return null;
  }

  /// OpenAPI 스펙 파싱
  APISpec _parseOpenAPISpec(Map<String, dynamic> json, String sourceUrl) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    final servers = json['servers'] as List? ?? [];
    final paths = json['paths'] as Map<String, dynamic>? ?? {};
    const baseUrl = 'https://api.example.com';

    // 서버 URL 추출
    if (servers.isNotEmpty) {
      // baseUrl = servers[0]['url'];
    }

    // 엔드포인트 파싱
    final endpoints = <APIEndpoint>[];

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final pathItem = pathEntry.value as Map<String, dynamic>;

      for (final methodEntry in pathItem.entries) {
        final method = _parseHTTPMethod(methodEntry.key);
        if (method == null) continue;

        final operation = methodEntry.value as Map<String, dynamic>;

        final endpoint = APIEndpoint(
          name: operation['operationId'] as String? ?? _generateOperationId(path, method),
          path: path,
          method: method,
          description: operation['description'] as String? ?? operation['summary'] as String? ?? '',
        );

        endpoints.add(endpoint);
      }
    }

    return APISpec(
      specId: 'spec_${DateTime.now().millisecondsSinceEpoch}',
      name: info['title'] as String? ?? 'API',
      version: info['version'] as String? ?? '1.0.0',
      baseUrl: baseUrl,
      endpoints: endpoints,
      securitySchemes: json['components']?['securitySchemes'] as Map<String, dynamic>? ?? {},
    );
  }

  HTTPMethod? _parseHTTPMethod(String method) {
    switch (method.toLowerCase()) {
      case 'get':
        return HTTPMethod.get;
      case 'post':
        return HTTPMethod.post;
      case 'put':
        return HTTPMethod.put;
      case 'patch':
        return HTTPMethod.patch;
      case 'delete':
        return HTTPMethod.delete;
      case 'head':
        return HTTPMethod.head;
      case 'options':
        return HTTPMethod.options;
      default:
        return null;
    }
  }

  String _generateOperationId(String path, HTTPMethod method) {
    return '${method.name}_${path.replaceAll('/', '_')}';
  }

  /// Dart API 클라이언트 생성
  Future<GeneratedAPIClient> generateDartClient({
    required String specId,
    String? clientName,
  }) async {
    final spec = _specs[specId];
    if (spec == null) {
      throw SpecNotFoundException('Spec not found: $specId');
    }

    final code = _generateDartCode(spec, clientName);

    final client = GeneratedAPIClient(
      clientId: 'client_${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      language: 'dart',
      spec: spec,
      generatedAt: DateTime.now(),
    );

    _clients[client.clientId] = client;
    _clientController.add(client);

    return client;
  }

  /// Dart 코드 생성
  String _generateDartCode(APISpec spec, String? clientName) {
    final className = clientName ?? '${spec.name.replaceAll(' ', '')}Client';

    final buffer = StringBuffer();

    // 헤더
    buffer.writeln("import 'dart:async';");
    buffer.writeln("import 'dart:convert';");
    buffer.writeln("import 'package:http/http.dart' as http;");
    buffer.writeln();

    // 클래스 선언
    buffer.writeln("class $className {");
    buffer.writeln("  final String baseUrl;");
    buffer.writeln("  final String? apiKey;");
    buffer.writeln();

    // 생성자
    buffer.writeln("  $className({");
    buffer.writeln("    required this.baseUrl,");
    buffer.writeln("    this.apiKey,");
    buffer.writeln("  });");
    buffer.writeln();

    // 헤더 메서드
    buffer.writeln("  Map<String, String> _getHeaders() {");
    buffer.writeln("    final headers = <String, String>{");
    buffer.writeln("      'Content-Type': 'application/json',");
    buffer.writeln("      'Accept': 'application/json',");
    buffer.writeln("    };");
    buffer.writeln("    if (apiKey != null) {");
    buffer.writeln("      headers['Authorization'] = 'Bearer \$apiKey';");
    buffer.writeln("    }");
    buffer.writeln("    return headers;");
    buffer.writeln("  }");
    buffer.writeln();

    // 엔드포인트 메서드 생성
    for (final endpoint in spec.endpoints) {
      _generateEndpointMethod(buffer, className, endpoint);
    }

    buffer.writeln("}");

    return buffer.toString();
  }

  void _generateEndpointMethod(
    StringBuffer buffer,
    String className,
    APIEndpoint endpoint,
  ) {
    final methodName = endpoint.name;
    final returnType = 'Future<Map<String, dynamic>>';

    // 메서드 시그니처
    buffer.write("  $returnType $methodName(");

    // 경로 파라미터
    if (endpoint.pathParams != null && endpoint.pathParams!.isNotEmpty) {
      final params = endpoint.pathParams!.entries.map((e) => 'required ${e.value} ${e.key}').join(', ');
      buffer.write(params);
    }

    // 쿼리 파라미터
    if (endpoint.queryParams != null && endpoint.queryParams!.isNotEmpty) {
      if (endpoint.pathParams != null && endpoint.pathParams!.isNotEmpty) {
        buffer.write(', ');
      }
      final params = endpoint.queryParams!.entries.map((e) => '${e.value}? ${e.key}').join(', ');
      buffer.write(params);
    }

    // 요청 바디
    if (endpoint.body != null) {
      if (endpoint.pathParams != null || endpoint.queryParams != null) {
        buffer.write(', ');
      }
      buffer.write('Map<String, dynamic>? body');
    }

    buffer.writeln(') async {');

    // URL 빌드
    var path = endpoint.path;
    if (endpoint.pathParams != null) {
      for (final entry in endpoint.pathParams!.entries) {
        path = path.replaceAll('\${{${entry.key}}}', '\${${entry.key}}');
      }
    }

    buffer.writeln("    var url = '\$baseUrl\$path';");

    // 쿼리 파라미터 추가
    if (endpoint.queryParams != null && endpoint.queryParams!.isNotEmpty) {
      buffer.writeln("    final params = {");
      for (final entry in endpoint.queryParams!.entries) {
        buffer.writeln("      if (${entry.key} != null: '${entry.key}': \${${entry.key}},");
      }
      buffer.writeln("    };");
      buffer.writeln("    if (params.isNotEmpty) {");
      buffer.writeln("      final queryString = params.entries");
      buffer.writeln("          .map((e) => '\${e.key}=\${e.value}')");
      buffer.writeln("          .join('&');");
      buffer.writeln("      url += '?\$queryString';");
      buffer.writeln("    }");
    }

    buffer.writeln();

    // 요청 전송
    buffer.write("    final response = await http.");
    buffer.write(endpoint.method.name.toUpperCase());
    buffer.writeln("(");
    buffer.writeln("      Uri.parse(url),");
    buffer.writeln("      headers: _getHeaders(),");

    if (endpoint.body != null) {
      buffer.writeln("      body: jsonEncode(body),");
    }

    buffer.writeln("    );");
    buffer.writeln();

    // 응답 처리
    buffer.writeln("    if (response.statusCode >= 200 && response.statusCode < 300) {");
    buffer.writeln("      return jsonDecode(response.body) as Map<String, dynamic>;");
    buffer.writeln("    } else {");
    buffer.writeln("      throw Exception('Failed to $methodName: \${response.statusCode}');");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
  }

  /// API 스펙 목록 조회
  List<APISpec> getSpecs() {
    return _specs.values.toList();
  }

  /// API 스펙 조회
  APISpec? getSpec(String specId) {
    return _specs[specId];
  }

  /// API 스펙 추가
  Future<void> addSpec(APISpec spec) async {
    _specs[spec.specId] = spec;
    _specController.add(spec.specId);

    await _saveSpecs();
  }

  /// API 스펙 제거
  Future<void> removeSpec(String specId) async {
    _specs.remove(specId);

    await _saveSpecs();
  }

  /// 생성된 클라이언트 조회
  List<GeneratedAPIClient> getClients() {
    return _clients.values.toList();
  }

  /// 런타임 API 클라이언트
  RuntimeAPIClient createRuntimeClient(String specId) {
    final spec = _specs[specId];
    if (spec == null) {
      throw SpecNotFoundException('Spec not found: $specId');
    }

    return RuntimeAPIClient(spec: spec);
  }

  Future<void> _saveSpecs() async {
    // 스펙 저장
    debugPrint('[APIClientGenerator] Specs saved');
  }
}

/// 런타임 API 클라이언트
class RuntimeAPIClient {
  final APISpec spec;
  String? apiKey;

  RuntimeAPIClient({
    required this.spec,
    this.apiKey,
  });

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
    };
  }

  Future<APIResponse<Map<String, dynamic>>> request({
    required String endpointName,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
    dynamic body,
    APIRequestOptions? options,
  }) async {
    final endpoint = spec.endpoints.firstWhere(
      (e) => e.name == endpointName,
      orElse: () => throw EndpointNotFoundException('Endpoint not found: $endpointName'),
    );

    // URL 빌드
    var path = endpoint.path;
    if (pathParams != null) {
      for (final entry in pathParams.entries) {
        path = path.replaceAll('\${{${entry.key}}}', entry.value.toString());
      }
    }

    var url = '${spec.baseUrl}$path';

    // 쿼리 파라미터
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      url += '?$queryString';
    }

    // 요청 전송
    late http.Response response;

    switch (endpoint.method) {
      case HTTPMethod.get:
        response = await http.get(
          Uri.parse(url),
          headers: {..._getHeaders(), ...?options?.headers},
        ).timeout(options?.timeout ?? const Duration(seconds: 30));
        break;

      case HTTPMethod.post:
        response = await http.post(
          Uri.parse(url),
          headers: {..._getHeaders(), ...?options?.headers},
          body: body != null ? jsonEncode(body) : null,
        ).timeout(options?.timeout ?? const Duration(seconds: 30));
        break;

      case HTTPMethod.put:
        response = await http.put(
          Uri.parse(url),
          headers: {..._getHeaders(), ...?options?.headers},
          body: body != null ? jsonEncode(body) : null,
        ).timeout(options?.timeout ?? const Duration(seconds: 30));
        break;

      case HTTPMethod.delete:
        response = await http.delete(
          Uri.parse(url),
          headers: {..._getHeaders(), ...?options?.headers},
        ).timeout(options?.timeout ?? const Duration(seconds: 30));
        break;

      default:
        throw UnimplementedError('Method ${endpoint.method} not implemented');
    }

    // 응답 처리
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return APIResponse<Map<String, dynamic>>(
        statusCode: response.statusCode,
        data: data as Map<String, dynamic>,
        timestamp: DateTime.now(),
      );
    } else {
      return APIResponse<Map<String, dynamic>>(
        statusCode: response.statusCode,
        errorMessage: response.body,
        timestamp: DateTime.now(),
      );
    }
  }
}

/// 예외
class SpecNotFoundException implements Exception {
  final String message;
  SpecNotFoundException(this.message);

  @override
  String toString() => 'SpecNotFoundException: $message';
}

class EndpointNotFoundException implements Exception {
  final String message;
  EndpointNotFoundException(this.message);

  @override
  String toString() => 'EndpointNotFoundException: $message';
}

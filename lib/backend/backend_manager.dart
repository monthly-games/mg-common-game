import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// API 버전
enum APIVersion {
  v1,
  v2,
  v3,
}

/// HTTP 메서드
enum HTTPMethod {
  get,
  post,
  put,
  patch,
  delete,
}

/// 요청 상태
enum RequestStatus {
  pending,
  loading,
  success,
  error,
  canceled,
}

/// API 응답
class APIResponse<T> {
  final int? statusCode;
  final T? data;
  final String? errorMessage;
  final RequestStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const APIResponse({
    this.statusCode,
    this.data,
    this.errorMessage,
    required this.status,
    this.metadata,
    required this.timestamp,
  });

  factory APIResponse.success({
    required int statusCode,
    required T data,
    Map<String, dynamic>? metadata,
  }) {
    return APIResponse(
      statusCode: statusCode,
      data: data,
      status: RequestStatus.success,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }

  factory APIResponse.error({
    required int statusCode,
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return APIResponse(
      statusCode: statusCode,
      errorMessage: errorMessage,
      status: RequestStatus.error,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }

  bool get isSuccess => status == RequestStatus.success;
  bool get isError => status == RequestStatus.error;
}

/// API 요청
class APIRequest {
  final String path;
  final HTTPMethod method;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParams;
  final dynamic body;
  final APIVersion version;
  final Duration? timeout;

  const APIRequest({
    required this.path,
    required this.method,
    this.headers,
    this.queryParams,
    this.body,
    this.version = APIVersion.v1,
    this.timeout,
  });

  Uri buildUri(String baseUrl) {
    final pathWithVersion = '/api/${version.name}$path';

    final queryString = queryParams != null && queryParams!.isNotEmpty
        ? '?${queryParams!.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    return Uri.parse('$baseUrl$pathWithVersion$queryString');
  }

  String get mimeType {
    switch (method) {
      case HTTPMethod.get:
      case HTTPMethod.delete:
        return 'text/plain';
      case HTTPMethod.post:
      case HTTPMethod.put:
      case HTTPMethod.patch:
        return 'application/json';
    }
  }
}

/// GraphQL 쿼리
class GraphQLQuery {
  final String query;
  final Map<String, dynamic>? variables;
  final String? operationName;

  const GraphQLQuery({
    required this.query,
    this.variables,
    this.operationName,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        if (variables != null) 'variables': variables,
        if (operationName != null) 'operationName': operationName,
      };
}

/// GraphQL 응답
class GraphQLResponse<T> {
  final T? data;
  final Map<String, dynamic>? errors;
  final bool isSuccess;

  const GraphQLResponse({
    this.data,
    this.errors,
    required this.isSuccess,
  });

  factory GraphQLResponse.success(T data) {
    return GraphQLResponse(
      data: data,
      isSuccess: true,
    );
  }

  factory GraphQLResponse.error(Map<String, dynamic> errors) {
    return GraphQLResponse(
      errors: errors,
      isSuccess: false,
    );
  }
}

/// WebSocket 메시지
class WebSocketMessage {
  final String type;
  final Map<String, dynamic>? data;
  final String? messageId;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    this.data,
    this.messageId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'messageId': messageId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WebSocketMessage.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return WebSocketMessage(
      type: map['type'] as String,
      data: map['data'] as Map<String, dynamic>?,
      messageId: map['messageId'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// 백엔드 관리자
class BackendManager {
  static final BackendManager _instance = BackendManager._();
  static BackendManager get instance => _instance;

  BackendManager._();

  String _baseUrl = 'https://api.example.com';
  String _graphqlUrl = 'https://api.example.com/graphql';
  String _websocketUrl = 'wss://api.example.com/ws';

  String? _accessToken;
  Map<String, String> _defaultHeaders = {};

  final StreamController<APIResponse> _responseController =
      StreamController<APIResponse>.broadcast();
  final StreamController<WebSocketMessage> _wsMessageController =
      StreamController<WebSocketMessage>.broadcast();

  Stream<APIResponse> get onResponse => _responseController.stream;
  Stream<WebSocketMessage> get onWebSocketMessage => _wsMessageController.stream;

  WebSocketChannel? _wsChannel;
  bool _isWebSocketConnected = false;

  /// 초기화
  Future<void> initialize({
    required String baseUrl,
    String? graphqlUrl,
    String? websocketUrl,
    String? accessToken,
  }) async {
    _baseUrl = baseUrl;
    _graphqlUrl = graphqlUrl ?? '$baseUrl/graphql';
    _websocketUrl = websocketUrl ?? '$baseUrl/ws'.replaceFirst('https', 'wss').replaceFirst('http', 'ws');
    _accessToken = accessToken;

    _defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };

    debugPrint('[Backend] Initialized: $_baseUrl');
  }

  /// 액세스 토큰 설정
  void setAccessToken(String token) {
    _accessToken = token;
    _defaultHeaders['Authorization'] = 'Bearer $token';
    debugPrint('[Backend] Access token updated');
  }

  /// 기본 헤더 설정
  void setDefaultHeaders(Map<String, String> headers) {
    _defaultHeaders = {..._defaultHeaders, ...headers};
  }

  /// RESTful API 호출
  Future<APIResponse<T>> request<T>({
    required APIRequest apiRequest,
    required T Function(dynamic data) parser,
  }) async {
    try {
      final uri = apiRequest.buildUri(_baseUrl);
      final headers = {..._defaultHeaders, ...?apiRequest.headers};

      debugPrint('[Backend] ${apiRequest.method.name.toUpperCase()}: $uri');

      late http.Response response;

      switch (apiRequest.method) {
        case HTTPMethod.get:
          response = await http.get(
            uri,
            headers: headers,
          ).timeout(apiRequest.timeout ?? const Duration(seconds: 30));
          break;
        case HTTPMethod.post:
          response = await http.post(
            uri,
            headers: headers,
            body: apiRequest.body != null ? jsonEncode(apiRequest.body) : null,
          ).timeout(apiRequest.timeout ?? const Duration(seconds: 30));
          break;
        case HTTPMethod.put:
          response = await http.put(
            uri,
            headers: headers,
            body: apiRequest.body != null ? jsonEncode(apiRequest.body) : null,
          ).timeout(apiRequest.timeout ?? const Duration(seconds: 30));
          break;
        case HTTPMethod.patch:
          response = await http.patch(
            uri,
            headers: headers,
            body: apiRequest.body != null ? jsonEncode(apiRequest.body) : null,
          ).timeout(apiRequest.timeout ?? const Duration(seconds: 30));
          break;
        case HTTPMethod.delete:
          response = await http.delete(
            uri,
            headers: headers,
          ).timeout(apiRequest.timeout ?? const Duration(seconds: 30));
          break;
      }

      final apiResponse = response.statusCode >= 200 && response.statusCode < 300
          ? APIResponse.success(
              statusCode: response.statusCode,
              data: parser(jsonDecode(utf8.decode(response.bodyBytes))),
            )
          : APIResponse.error(
              statusCode: response.statusCode,
              errorMessage: _parseErrorMessage(response.body),
            );

      _responseController.add(apiResponse);

      return apiResponse;
    } catch (e) {
      debugPrint('[Backend] Request error: $e');

      final errorResponse = APIResponse.error(
        statusCode: 500,
        errorMessage: e.toString(),
      );

      _responseController.add(errorResponse);

      return errorResponse;
    }
  }

  String _parseErrorMessage(dynamic body) {
    try {
      final json = jsonDecode(body as String) as Map<String, dynamic>;
      return json['message'] as String? ?? 'Unknown error';
    } catch (_) {
      return 'Failed to parse error message';
    }
  }

  /// GET 요청
  Future<APIResponse<T>> get<T>({
    required String path,
    Map<String, dynamic>? queryParams,
    required T Function(dynamic data) parser,
    APIVersion version = APIVersion.v1,
  }) {
    return request(
      apiRequest: APIRequest(
        path: path,
        method: HTTPMethod.get,
        queryParams: queryParams,
        version: version,
      ),
      parser: parser,
    );
  }

  /// POST 요청
  Future<APIResponse<T>> post<T>({
    required String path,
    required Map<String, dynamic> body,
    required T Function(dynamic data) parser,
    Map<String, dynamic>? queryParams,
    APIVersion version = APIVersion.v1,
  }) {
    return request(
      apiRequest: APIRequest(
        path: path,
        method: HTTPMethod.post,
        body: body,
        queryParams: queryParams,
        version: version,
      ),
      parser: parser,
    );
  }

  /// PUT 요청
  Future<APIResponse<T>> put<T>({
    required String path,
    required Map<String, dynamic> body,
    required T Function(dynamic data) parser,
    APIVersion version = APIVersion.v1,
  }) {
    return request(
      apiRequest: APIRequest(
        path: path,
        method: HTTPMethod.put,
        body: body,
        version: version,
      ),
      parser: parser,
    );
  }

  /// DELETE 요청
  Future<APIResponse<T>> delete<T>({
    required String path,
    required T Function(dynamic data) parser,
    APIVersion version = APIVersion.v1,
  }) {
    return request(
      apiRequest: APIRequest(
        path: path,
        method: HTTPMethod.delete,
        version: version,
      ),
      parser: parser,
    );
  }

  /// GraphQL 쿼리 실행
  Future<GraphQLResponse<T>> query<T>({
    required GraphQLQuery graphQLQuery,
    required T Function(dynamic data) parser,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_graphqlUrl),
        headers: _defaultHeaders,
        body: jsonEncode(graphQLQuery.toJson()),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['errors'] == null) {
        final parsedData = parser(data['data']);
        return GraphQLResponse.success(parsedData);
      } else {
        return GraphQLResponse.error(data['errors'] as Map<String, dynamic>? ?? {});
      }
    } catch (e) {
      debugPrint('[Backend] GraphQL error: $e');
      return GraphQLResponse.error({'error': e.toString()});
    }
  }

  /// GraphQL 뮤테이션 실행
  Future<GraphQLResponse<T>> mutate<T>({
    required String mutation,
    Map<String, dynamic>? variables,
    required T Function(dynamic data) parser,
  }) {
    return query(
      graphQLQuery: GraphQLQuery(
        query: mutation,
        variables: variables,
      ),
      parser: parser,
    );
  }

  /// WebSocket 연결
  Future<void> connectWebSocket() async {
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(_websocketUrl));

      _wsChannel!.stream.listen(
        (message) {
          final wsMessage = WebSocketMessage.fromJson(message as String);
          _wsMessageController.add(wsMessage);
        },
        onError: (error) {
          debugPrint('[Backend] WebSocket error: $error');
          _isWebSocketConnected = false;
        },
        onDone: () {
          debugPrint('[Backend] WebSocket closed');
          _isWebSocketConnected = false;
        },
      );

      _isWebSocketConnected = true;
      debugPrint('[Backend] WebSocket connected');
    } catch (e) {
      debugPrint('[Backend] WebSocket connection failed: $e');
      _isWebSocketConnected = false;
    }
  }

  /// WebSocket 연결 해제
  Future<void> disconnectWebSocket() async {
    await _wsChannel?.sink.close();
    _isWebSocketConnected = false;
    debugPrint('[Backend] WebSocket disconnected');
  }

  /// WebSocket 메시지 전송
  void sendWebSocketMessage(WebSocketMessage message) {
    if (!_isWebSocketConnected || _wsChannel == null) {
      debugPrint('[Backend] WebSocket not connected');
      return;
    }

    final json = jsonEncode(message.toJson());
    _wsChannel!.sink.add(json);
  }

  /// WebSocket 연결 상태
  bool get isWebSocketConnected => _isWebSocketConnected;

  /// 요청 취소 지원
  final Map<String, Timer> _pendingRequests = {};

  void cancelRequest(String requestId) {
    _pendingRequests[requestId]?.cancel();
    _pendingRequests.remove(requestId);
    debugPrint('[Backend] Request canceled: $requestId');
  }

  void cancelAllRequests() {
    for (final timer in _pendingRequests.values) {
      timer.cancel();
    }
    _pendingRequests.clear();
    debugPrint('[Backend] All requests canceled');
  }

  /// 요청 재시도 로직
  Future<APIResponse<T>> requestWithRetry<T>({
    required APIRequest apiRequest,
    required T Function(dynamic data) parser,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      final response = await request(
        apiRequest: apiRequest,
        parser: parser,
      );

      if (response.isSuccess || response.statusCode != 500) {
        return response;
      }

      attempts++;
      if (attempts < maxRetries) {
        debugPrint('[Backend] Retrying... ($attempts/$maxRetries)');
        await Future.delayed(retryDelay * attempts);
      }
    }

    return APIResponse.error(
      statusCode: 500,
      errorMessage: 'Max retries exceeded',
    );
  }

  /// 요청 캐싱
  final Map<String, _CacheEntry> _cache = {};

  Future<APIResponse<T>> requestWithCache<T>({
    required String cacheKey,
    required APIRequest apiRequest,
    required T Function(dynamic data) parser,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    // 캐시 확인
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null &&
        DateTime.now().isBefore(cachedEntry.expiresAt)) {
      debugPrint('[Backend] Cache hit: $cacheKey');
      return cachedEntry.response as APIResponse<T>;
    }

    // 요청 실행
    final response = await request(
      apiRequest: apiRequest,
      parser: parser,
    );

    // 성공 시 캐시 저장
    if (response.isSuccess) {
      _cache[cacheKey] = _CacheEntry(
        response: response,
        expiresAt: DateTime.now().add(cacheDuration),
      );
    }

    return response;
  }

  /// 캐시 지우기
  void clearCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
      debugPrint('[Backend] Cache cleared: $key');
    } else {
      _cache.clear();
      debugPrint('[Backend] All cache cleared');
    }
  }

  /// 배치 요청 처리
  Future<List<APIResponse>> batchRequest<T>({
    required List<APIRequest> requests,
    required T Function(dynamic data) parser,
  }) async {
    final futures = requests.map((request) =>
        request(apiRequest: request, parser: parser));

    final responses = await Future.wait(futures);
    return responses;
  }

  void dispose() {
    disconnectWebSocket();
    cancelAllRequests();
    clearCache();
    _responseController.close();
    _wsMessageController.close();
  }
}

/// 캐시 엔트리
class _CacheEntry {
  final APIResponse response;
  final DateTime expiresAt;

  const _CacheEntry({
    required this.response,
    required this.expiresAt,
  });
}

/// API 버저닝 관리자
class APIVersionManager {
  final Map<APIVersion, String> _versionPaths = {
    APIVersion.v1: '/api/v1',
    APIVersion.v2: '/api/v2',
    APIVersion.v3: '/api/v3',
  };

  String getVersionPath(APIVersion version) {
    return _versionPaths[version] ?? _versionPaths[APIVersion.v1]!;
  }

  APIVersion? detectVersion(String path) {
    for (final entry in _versionPaths.entries) {
      if (path.startsWith(entry.value)) {
        return entry.key;
      }
    }
    return null;
  }
}

/// 마이그레이션 관리자
class MigrationManager {
  final List<Migration> _migrations = [];
  final Set<String> _appliedMigrations = {};

  void registerMigration(Migration migration) {
    _migrations.add(migration);
    _migrations.sort((a, b) => a.version.compareTo(b.version));
  }

  Future<void> migrate({String? targetVersion}) async {
    for (final migration in _migrations) {
      if (_appliedMigrations.contains(migration.version)) continue;
      if (targetVersion != null &&
          migration.version.compareTo(targetVersion) > 0) continue;

      debugPrint('[Migration] Applying: ${migration.version}');
      await migration.up();
      _appliedMigrations.add(migration.version);
    }
  }

  Future<void> rollback(String version) async {
    final migration = _migrations.firstWhere(
      (m) => m.version == version,
      orElse: () => throw Exception('Migration not found: $version'),
    );

    debugPrint('[Migration] Rolling back: $version');
    await migration.down();
    _appliedMigrations.remove(version);
  }
}

/// 마이그레이션
class Migration {
  final String version;
  final String description;
  final Future<void> Function() up;
  final Future<void> Function() down;

  const Migration({
    required this.version,
    required this.description,
    required this.up,
    required this.down,
  });
}

/// 인터셉터
class RequestInterceptor {
  final bool Function(APIRequest) onRequest;
  final void Function(APIResponse) onResponse;
  final void Function(dynamic error) onError;

  const RequestInterceptor({
    required this.onRequest,
    required this.onResponse,
    required this.onError,
  });
}

/// 인터셉터 체인
class InterceptorChain {
  final List<RequestInterceptor> _interceptors = [];

  void addInterceptor(RequestInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  bool processRequest(APIRequest request) {
    for (final interceptor in _interceptors) {
      if (!interceptor.onRequest(request)) {
        return false;
      }
    }
    return true;
  }

  void processResponse(APIResponse response) {
    for (final interceptor in _interceptors) {
      interceptor.onResponse(response);
    }
  }

  void processError(dynamic error) {
    for (final interceptor in _interceptors) {
      interceptor.onError(error);
    }
  }
}

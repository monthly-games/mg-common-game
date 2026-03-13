import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, String>? headers;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.headers,
  });

  /// Create success response
  factory ApiResponse.success({
    required T data,
    int? statusCode,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      headers: headers,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required String error,
    int? statusCode,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
      headers: headers,
    );
  }

  /// Create from HTTP response
  factory ApiResponse.fromHttpResponse(
    http.Response response,
    T Function(dynamic) dataParser,
  ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        final data = dataParser(jsonData);
        return ApiResponse.success(
          data: data,
          statusCode: response.statusCode,
          headers: response.headers,
        );
      } else {
        return ApiResponse.error(
          error: response.body,
          statusCode: response.statusCode,
          headers: response.headers,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        error: 'Failed to parse response: $e',
        statusCode: response.statusCode,
        headers: response.headers,
      );
    }
  }
}

/// API request configuration
class ApiConfig {
  final String baseUrl;
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final bool enableLogging;
  final int maxRetries;

  const ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.defaultHeaders = const {},
    this.enableLogging = true,
    this.maxRetries = 3,
  });
}

/// API request options
class ApiOptions {
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParameters;
  final Duration? timeout;
  final int? maxRetries;

  const ApiOptions({
    this.headers,
    this.queryParameters,
    this.timeout,
    this.maxRetries,
  });
}

/// REST API client
class ApiClient {
  static ApiClient? _instance;
  late ApiConfig _config;
  final Map<String, String> _authHeaders = {};

  /// Get singleton instance
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  ApiClient._internal();

  /// Initialize the API client
  void initialize(ApiConfig config) {
    _config = config;
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authHeaders['Authorization'] = 'Bearer $token';
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authHeaders.remove('Authorization');
  }

  /// Make GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    ApiOptions? options,
    required T Function(dynamic) dataParser,
  }) async {
    return _makeRequest<T>(
      method: 'GET',
      path: path,
      options: options,
      dataParser: dataParser,
    );
  }

  /// Make POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    ApiOptions? options,
    required T Function(dynamic) dataParser,
  }) async {
    return _makeRequest<T>(
      method: 'POST',
      path: path,
      body: body,
      options: options,
      dataParser: dataParser,
    );
  }

  /// Make PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    ApiOptions? options,
    required T Function(dynamic) dataParser,
  }) async {
    return _makeRequest<T>(
      method: 'PUT',
      path: path,
      body: body,
      options: options,
      dataParser: dataParser,
    );
  }

  /// Make PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    ApiOptions? options,
    required T Function(dynamic) dataParser,
  }) async {
    return _makeRequest<T>(
      method: 'PATCH',
      path: path,
      body: body,
      options: options,
      dataParser: dataParser,
    );
  }

  /// Make DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    ApiOptions? options,
    required T Function(dynamic) dataParser,
  }) async {
    return _makeRequest<T>(
      method: 'DELETE',
      path: path,
      options: options,
      dataParser: dataParser,
    );
  }

  /// Make HTTP request with retry logic
  Future<ApiResponse<T>> _makeRequest<T>({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    ApiOptions? options,
    required T Function(dynamic) dataParser,
  }) async {
    final maxRetries = options?.maxRetries ?? _config.maxRetries;
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        final response = await _executeRequest(
          method: method,
          path: path,
          body: body,
          options: options,
        );

        return ApiResponse.fromHttpResponse(response, dataParser);
      } catch (e) {
        attempts++;

        if (attempts > maxRetries) {
          return ApiResponse.error(
            error: 'Request failed after $attempts attempts: $e',
          );
        }

        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      }
    }

    return ApiResponse.error(error: 'Unknown error');
  }

  /// Execute HTTP request
  Future<http.Response> _executeRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    ApiOptions? options,
  }) async {
    final uri = _buildUri(path, options?.queryParameters);
    final headers = _buildHeaders(options?.headers);
    final timeout = options?.timeout ?? _config.timeout;

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers).timeout(timeout);
        break;
      case 'POST':
        response = await http
            .post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        break;
      case 'PUT':
        response = await http
            .put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        break;
      case 'PATCH':
        response = await http
            .patch(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers).timeout(timeout);
        break;
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    if (_config.enableLogging) {
      _logRequest(method, uri, body, response);
    }

    return response;
  }

  /// Build URI with query parameters
  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final queryString = queryParameters != null && queryParameters.isNotEmpty
        ? '?${queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    return Uri.parse('$_config baseUrl$path$queryString');
  }

  /// Build headers with auth and defaults
  Map<String, String> _buildHeaders(Map<String, String>? additionalHeaders) {
    return {
      'Content-Type': 'application/json',
      ..._config.defaultHeaders,
      ..._authHeaders,
      ...?additionalHeaders,
    };
  }

  /// Log request and response
  void _logRequest(
    String method,
    Uri uri,
    dynamic body,
    http.Response response,
  ) {
    print('🌐 API Request:');
    print('  Method: $method');
    print('  URL: $uri');
    if (body != null) {
      print('  Body: ${jsonEncode(body)}');
    }
    print('  Response Status: ${response.statusCode}');
    print('  Response Body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
  }

  // ==================== Multipart Request ====================

  /// Upload file with multipart request
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    String filePath,
    String fieldName, {
    Map<String, String>? fields,
    ApiOptions? options,
    required T Function(dynamic) dataParser,
  }) async {
    final uri = _buildUri(path, options?.queryParameters);
    final headers = _buildHeaders(options?.headers);
    final timeout = options?.timeout ?? _config.timeout;

    // Remove Content-Type to let the client set it with boundary
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);

    return ApiResponse.fromHttpResponse(response, dataParser);
  }

  // ==================== Batch Requests ====================

  /// Execute multiple requests concurrently
  Future<List<ApiResponse<T>>> batch<T>({
    required List<Future<ApiResponse<T>>> requests,
    bool failOnError = false,
  }) async {
    try {
      final results = await Future.wait(requests, eagerError: failOnError);
      return results;
    } catch (e) {
      if (failOnError) {
        rethrow;
      }
      return [];
    }
  }
}

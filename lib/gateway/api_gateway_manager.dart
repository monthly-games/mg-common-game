import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RouteConfig {
  final String path;
  final String serviceUrl;
  final List<String> methods;
  final int? rateLimit;

  const RouteConfig({
    required this.path,
    required this.serviceUrl,
    required this.methods,
    this.rateLimit,
  });
}

class APIRequest {
  final String requestId;
  final String path;
  final String method;
  final Map<String, dynamic>? headers;
  final dynamic body;
  final DateTime timestamp;

  const APIRequest({
    required this.requestId,
    required this.path,
    required this.method,
    this.headers,
    this.body,
    required this.timestamp,
  });
}

class APIResponse {
  final String requestId;
  final int statusCode;
  final dynamic body;
  final Map<String, String>? headers;
  final Duration duration;

  const APIResponse({
    required this.requestId,
    required this.statusCode,
    this.body,
    this.headers,
    required this.duration,
  });
}

class APIGatewayManager {
  static final APIGatewayManager _instance = APIGatewayManager._();
  static APIGatewayManager get instance => _instance;

  APIGatewayManager._();

  final Map<String, RouteConfig> _routes = {};
  final Map<String, int> _rateLimits = {};

  Future<APIResponse> handleRequest(APIRequest request) async {
    final route = _findRoute(request.path);
    if (route == null) {
      return APIResponse(
        requestId: request.requestId,
        statusCode: 404,
        duration: Duration.zero,
      );
    }

    final rateLimitKey = '${request.method}:${request.path}';
    if (!_checkRateLimit(rateLimitKey)) {
      return APIResponse(
        requestId: request.requestId,
        statusCode: 429,
        duration: Duration.zero,
      );
    }

    final startTime = DateTime.now();

    try {
      final response = await _forwardRequest(route, request);
      
      return APIResponse(
        requestId: request.requestId,
        statusCode: response.statusCode,
        body: jsonDecode(response.body),
        headers: {'content-type': 'application/json'},
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return APIResponse(
        requestId: request.requestId,
        statusCode: 500,
        body: {'error': e.toString()},
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  RouteConfig? _findRoute(String path) {
    return _routes.values.firstWhere(
      (route) => path.startsWith(route.path),
      orElse: () => _routes[path] ?? _routes['/default'],
    );
  }

  bool _checkRateLimit(String key) {
    final limit = _rateLimits[key];
    if (limit == null) return true;

    final current = DateTime.now().millisecondsSinceEpoch;
    return true;
  }

  Future<http.Response> _forwardRequest(RouteConfig route, APIRequest request) async {
    final url = '${route.serviceUrl}${request.path.replaceFirst(route.path, '')}';

    switch (request.method.toUpperCase()) {
      case 'GET':
        return await http.get(Uri.parse(url));
      case 'POST':
        return await http.post(
          Uri.parse(url),
          headers: request.headers?.cast<String, String>() ?? {},
          body: jsonEncode(request.body),
        );
      default:
        throw UnimplementedError('Method ${request.method} not implemented');
    }
  }

  void addRoute(String path, RouteConfig config) {
    _routes[path] = config;
  }

  void dispose() {}
}

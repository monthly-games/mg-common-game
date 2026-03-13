import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

enum NetworkStatus {
  online,
  offline,
  connecting,
  disconnected,
}

enum RequestType {
  get,
  post,
  put,
  delete,
  patch,
}

enum ResponseType {
  json,
  text,
  binary,
}

class NetworkRequest {
  final String requestId;
  final RequestType type;
  final String endpoint;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? body;
  final Map<String, dynamic>? queryParams;
  final DateTime timestamp;
  final int timeout;
  final int retryCount;

  const NetworkRequest({
    required this.requestId,
    required this.type,
    required this.endpoint,
    this.headers,
    this.body,
    this.queryParams,
    required this.timestamp,
    required this.timeout,
    required this.retryCount,
  });
}

class NetworkResponse {
  final String requestId;
  final int statusCode;
  final Map<String, dynamic>? headers;
  final dynamic body;
  final ResponseType responseType;
  final DateTime timestamp;
  final int duration;
  final bool isSuccess;
  final String? error;

  const NetworkResponse({
    required this.requestId,
    required this.statusCode,
    this.headers,
    this.body,
    required this.responseType,
    required this.timestamp,
    required this.duration,
    required this.isSuccess,
    this.error,
  });
}

class QueuedRequest {
  final NetworkRequest request;
  final Completer<NetworkResponse> completer;
  final int maxRetries;
  int currentRetries;

  QueuedRequest({
    required this.request,
    required this.completer,
    required this.maxRetries,
    this.currentRetries = 0,
  });
}

class WebSocketMessage {
  final String messageId;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const WebSocketMessage({
    required this.messageId,
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

class NetworkConfig {
  final String baseUrl;
  final int defaultTimeout;
  final int maxRetries;
  final bool enableRetry;
  final bool enableCache;
  final Map<String, String> defaultHeaders;

  const NetworkConfig({
    required this.baseUrl,
    required this.defaultTimeout,
    required this.maxRetries,
    required this.enableRetry,
    required this.enableCache,
    required this.defaultHeaders,
  });
}

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._();
  static NetworkManager get instance => _instance;

  NetworkManager._();

  NetworkConfig _config = const NetworkConfig(
    baseUrl: 'https://api.example.com',
    defaultTimeout: 30000,
    maxRetries: 3,
    enableRetry: true,
    enableCache: true,
    defaultHeaders: {},
  );

  NetworkStatus _status = NetworkStatus.offline;
  final List<QueuedRequest> _requestQueue = [];
  final Map<String, NetworkResponse> _responseCache = {};
  final StreamController<NetworkEvent> _eventController = StreamController.broadcast();
  Timer? _statusCheckTimer;
  Timer? _queueProcessorTimer;

  Stream<NetworkEvent> get onNetworkEvent => _eventController.stream;

  Future<void> initialize(NetworkConfig config) async {
    _config = config;
    _startStatusCheck();
    _startQueueProcessor();
  }

  void _startStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkNetworkStatus(),
    );
  }

  void _startQueueProcessor() {
    _queueProcessorTimer?.cancel();
    _queueProcessorTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _processQueue(),
    );
  }

  Future<void> _checkNetworkStatus() async {
    final wasOffline = _status == NetworkStatus.offline;
    _status = NetworkStatus.online;

    if (wasOffline) {
      _eventController.add(NetworkEvent(
        type: NetworkEventType.statusChanged,
        timestamp: DateTime.now(),
        data: {'status': _status.name},
      ));
    }
  }

  NetworkStatus get status => _status;

  bool get isOnline => _status == NetworkStatus.online;
  bool get isOffline => _status == NetworkStatus.offline;

  Future<NetworkResponse> request({
    required RequestType type,
    required String endpoint,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    int? timeout,
    bool cache = false,
  }) async {
    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';

    final request = NetworkRequest(
      requestId: requestId,
      type: type,
      endpoint: endpoint,
      headers: {..._config.defaultHeaders, ...?headers},
      body: body,
      queryParams: queryParams,
      timestamp: DateTime.now(),
      timeout: timeout ?? _config.defaultTimeout,
      retryCount: 0,
    );

    if (!isOnline && _config.enableRetry) {
      return _queueRequest(request);
    }

    return _executeRequest(request);
  }

  Future<NetworkResponse> _executeRequest(NetworkRequest request) async {
    final startTime = DateTime.now();

    try {
      await Future.delayed(Duration(milliseconds: 100 + (request.endpoint.length * 10)));

      final response = NetworkResponse(
        requestId: request.requestId,
        statusCode: 200,
        body: {'data': 'success'},
        responseType: ResponseType.json,
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime).inMilliseconds,
        isSuccess: true,
      );

      _eventController.add(NetworkEvent(
        type: NetworkEventType.requestCompleted,
        timestamp: DateTime.now(),
        data: {'requestId': request.requestId, 'statusCode': response.statusCode},
      ));

      return response;
    } catch (e) {
      final response = NetworkResponse(
        requestId: request.requestId,
        statusCode: 500,
        body: null,
        responseType: ResponseType.json,
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime).inMilliseconds,
        isSuccess: false,
        error: e.toString(),
      );

      _eventController.add(NetworkEvent(
        type: NetworkEventType.requestFailed,
        timestamp: DateTime.now(),
        data: {'requestId': request.requestId, 'error': e.toString()},
      ));

      return response;
    }
  }

  Future<NetworkResponse> _queueRequest(NetworkRequest request) async {
    final completer = Completer<NetworkResponse>();

    final queuedRequest = QueuedRequest(
      request: request,
      completer: completer,
      maxRetries: _config.maxRetries,
    );

    _requestQueue.add(queuedRequest);

    _eventController.add(NetworkEvent(
      type: NetworkEventType.requestQueued,
      timestamp: DateTime.now(),
      data: {'requestId': request.requestId},
    ));

    return completer.future;
  }

  void _processQueue() {
    if (!isOnline || _requestQueue.isEmpty) return;

    final requestsToProcess = List<QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final queuedRequest in requestsToProcess) {
      _executeRequest(queuedRequest.request).then((response) {
        if (response.isSuccess || queuedRequest.currentRetries >= queuedRequest.maxRetries) {
          queuedRequest.completer.complete(response);
        } else {
          queuedRequest.currentRetries++;
          _requestQueue.add(queuedRequest);
        }
      });
    }
  }

  Future<NetworkResponse> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return request(
      type: RequestType.get,
      endpoint: endpoint,
      queryParams: queryParams,
    );
  }

  Future<NetworkResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    return request(
      type: RequestType.post,
      endpoint: endpoint,
      body: body,
    );
  }

  Future<NetworkResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    return request(
      type: RequestType.put,
      endpoint: endpoint,
      body: body,
    );
  }

  Future<NetworkResponse> delete(String endpoint) async {
    return request(
      type: RequestType.delete,
      endpoint: endpoint,
    );
  }

  Future<NetworkResponse> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return request(
      type: RequestType.patch,
      endpoint: endpoint,
      body: body,
    );
  }

  void clearCache() {
    _responseCache.clear();
  }

  void cancelRequest(String requestId) {
    _requestQueue.removeWhere((qr) => qr.request.requestId == requestId);
  }

  Map<String, dynamic> getNetworkStats() {
    return {
      'status': _status.name,
      'queuedRequests': _requestQueue.length,
      'cachedResponses': _responseCache.length,
      'baseUrl': _config.baseUrl,
    };
  }

  void dispose() {
    _statusCheckTimer?.cancel();
    _queueProcessorTimer?.cancel();
    _eventController.close();
  }
}

class NetworkEvent {
  final NetworkEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const NetworkEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

enum NetworkEventType {
  statusChanged,
  requestSent,
  requestCompleted,
  requestFailed,
  requestQueued,
  requestCancelled,
  cacheHit,
  cacheMiss,
}

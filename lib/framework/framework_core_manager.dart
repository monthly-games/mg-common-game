import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 서비스 라이프사이클
enum ServiceLifecycle {
  initializing,   // 초기화 중
  initialized,    // 초기화됨
  starting,       // 시작 중
  started,        // 시작됨
  stopping,       // 중지 중
  stopped,        // 중지됨
  error,          // 에러
}

/// 의존성 주입 범위
enum DIScope {
  singleton,      // 싱글톤
  transient,      // 일시적 (매번 생성)
  scoped,         // 범위 내 싱글톤
}

/// 서비스 메타데이터
class ServiceMetadata {
  final String serviceName;
  final String version;
  final String description;
  final List<String> dependencies;
  final ServiceLifecycle lifecycle;
  final DateTime? lastStarted;
  final DateTime? lastStopped;
  final Map<String, dynamic>? config;

  const ServiceMetadata({
    required this.serviceName,
    required this.version,
    required this.description,
    required this.dependencies,
    required this.lifecycle,
    this.lastStarted,
    this.lastStopped,
    this.config,
  });
}

/// 서비스 등록정보
class ServiceRegistration {
  final String serviceName;
  final Type serviceType;
  final Type? implementationType;
  final DIScope scope;
  final Object? instance;
  final FactoryFunction? factory;
  final Map<String, dynamic>? parameters;

  const ServiceRegistration({
    required this.serviceName,
    required this.serviceType,
    this.implementationType,
    required this.scope,
    this.instance,
    this.factory,
    this.parameters,
  });
}

/// 팩토리 함수 타입
typedef FactoryFunction = Object Function();

/// 이벤트 버스 메시지
class EventMessage {
  final String eventId;
  final String eventType;
  final dynamic data;
  final DateTime timestamp;
  final String? source;
  final Map<String, dynamic>? metadata;

  EventMessage({
    required this.eventType,
    required this.data,
    this.source,
    this.metadata,
  }) : eventId = 'evt_${DateTime.now().millisecondsSinceEpoch}',
       timestamp = DateTime.now();
}

/// 이벤트 구독
class EventSubscription {
  final String subscriptionId;
  final String eventType;
  final Function(dynamic) callback;
  final bool async;

  const EventSubscription({
    required this.subscriptionId,
    required this.eventType,
    required this.callback,
    this.async = false,
  });
}

/// 미들웨어
class Middleware {
  final String name;
  final Future<dynamic> Function(
    String serviceName,
    String methodName,
    dynamic Function() next,
  ) handler;

  const Middleware({
    required this.name,
    required this.handler,
  });
}

/// 상태 컨테이너
class StateContainer<T> {
  final String stateId;
  T _state;
  final List<VoidCallback> _listeners = [];

  StateContainer({
    required String stateId,
    required T initialState,
  }) : stateId = stateId,
      _state = initialState;

  T get state => _state;

  void update(T newState) {
    _state = newState;
    _notifyListeners();
  }

  void subscribe(VoidCallback listener) {
    _listeners.add(listener);
  }

  void unsubscribe(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void dispose() {
    _listeners.clear();
  }
}

/// 서비스 디스커버리
class ServiceDiscovery {
  final Map<String, String> _serviceLocations = {};
  final Map<String, DateTime> _lastHeartbeats = {};

  void registerService(String serviceName, String location) {
    _serviceLocations[serviceName] = location;
    _lastHeartbeats[serviceName] = DateTime.now();
  }

  String? getServiceLocation(String serviceName) {
    return _serviceLocations[serviceName];
  }

  void heartbeat(String serviceName) {
    _lastHeartbeats[serviceName] = DateTime.now();
  }

  bool isServiceAvailable(String serviceName) {
    final lastHeartbeat = _lastHeartbeats[serviceName];
    if (lastHeartbeat == null) return false;

    final elapsed = DateTime.now().difference(lastHeartbeat);
    return elapsed.inSeconds < 30; // 30초 내 하트비트
  }

  List<String> getAvailableServices() {
    return _serviceLocations.entries
        .where((e) => isServiceAvailable(e.key))
        .map((e) => e.key)
        .toList();
  }
}

/// 프레임워크 코어 관리자
class FrameworkCoreManager {
  static final FrameworkCoreManager _instance =
      FrameworkCoreManager._();
  static FrameworkCoreManager get instance => _instance;

  FrameworkCoreManager._();

  SharedPreferences? _prefs;

  // 의존성 주입 컨테이너
  final Map<String, ServiceRegistration> _services = {};
  final Map<Type, ServiceRegistration> _servicesByType = {};

  // 이벤트 버스
  final Map<String, List<EventSubscription>> _subscriptions = {};
  final StreamController<EventMessage> _eventController =
      StreamController<EventMessage>.broadcast();

  // 상태 관리
  final Map<String, StateContainer> _stateContainers = {};

  // 미들웨어
  final List<Middleware> _middlewares = [];

  // 서비스 디스커버리
  final ServiceDiscovery _serviceDiscovery = ServiceDiscovery();

  // 로깅
  final List<String> _logs = [];
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  Stream<EventMessage> get onEvent => _eventController.stream;
  Stream<String> get onLog => _logController.stream;

  bool _isInitialized = false;

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // 코어 미들웨어 등록
    _registerCoreMiddleware();

    // 이벤트 버스 시작
    _startEventBus();

    _isInitialized = true;

    log('Framework initialized');

    // 프레임워크 시작 이벤트
    emit(EventMessage(
      eventType: 'framework.started',
      data: {'timestamp': DateTime.now().toIso8601String()},
      source: 'FrameworkCore',
    ));
  }

  void _registerCoreMiddleware() {
    // 로깅 미들웨어
    useMiddleware(Middleware(
      name: 'Logging',
      handler: (serviceName, methodName, next) async {
        log('[$serviceName] Calling: $methodName');
        final result = await next();
        log('[$serviceName] Completed: $methodName');
        return result;
      },
    ));

    // 에러 처리 미들웨어
    useMiddleware(Middleware(
      name: 'ErrorHandling',
      handler: (serviceName, methodName, next) async {
        try {
          return await next();
        } catch (e, stackTrace) {
          log('[$serviceName] Error in $methodName: $e');
          developer.log(
            'Error in $serviceName.$methodName',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      },
    ));

    // 성능 모니터링 미들웨어
    useMiddleware(Middleware(
      name: 'Performance',
      handler: (serviceName, methodName, next) async {
        final stopwatch = Stopwatch()..start();
        final result = await next();
        stopwatch.stop();

        if (stopwatch.elapsedMilliseconds > 100) {
          log('[$serviceName] Slow operation: $methodName (${stopwatch.elapsedMilliseconds}ms)');
        }

        return result;
      },
    ));
  }

  void _startEventBus() {
    // 이벤트 버스 처리
  }

  /// 의존성 주입: 서비스 등록
  void registerService<T>({
    required String serviceName,
    required Type serviceType,
    Type? implementationType,
    DIScope scope = DIScope.singleton,
    Object? instance,
    FactoryFunction? factory,
    Map<String, dynamic>? parameters,
  }) {
    final registration = ServiceRegistration(
      serviceName: serviceName,
      serviceType: serviceType,
      implementationType: implementationType,
      scope: scope,
      instance: instance,
      factory: factory,
      parameters: parameters,
    );

    _services[serviceName] = registration;
    _servicesByType[serviceType] = registration;

    log('Service registered: $serviceName (${serviceType})');
  }

  /// 의존성 주입: 서비스 조회
  T getService<T>({String? serviceName}) {
    ServiceRegistration? registration;

    if (serviceName != null) {
      registration = _services[serviceName];
    } else {
      registration = _servicesByType[T];
    }

    if (registration == null) {
      throw ServiceNotFoundException(
        'Service not found: ${serviceName ?? T.toString()}',
      );
    }

    return _resolveService<T>(registration);
  }

  T _resolveService<T>(ServiceRegistration registration) {
    switch (registration.scope) {
      case DIScope.singleton:
        if (registration.instance != null) {
          return registration.instance as T;
        }

        final instance = registration.factory?.call() ??
            _createInstance(registration);

        // 캐싱
        _services[registration.serviceName] = ServiceRegistration(
          serviceName: registration.serviceName,
          serviceType: registration.serviceType,
          implementationType: registration.implementationType,
          scope: registration.scope,
          instance: instance,
          factory: registration.factory,
          parameters: registration.parameters,
        );

        return instance as T;

      case DIScope.transient:
        return registration.factory?.call() as T ??
            _createInstance(registration) as T;

      case DIScope.scoped:
        // 실제로는 현재 범위 컨텍스트에서 조회
        return registration.factory?.call() as T ??
            _createInstance(registration) as T;
    }
  }

  Object _createInstance(ServiceRegistration registration) {
    // 실제로는 리플렉션 사용하여 인스턴스 생성
    // 여기서는 간단한 예시
    throw UnimplementedError(
      'Factory function required for ${registration.serviceName}',
    );
  }

  /// 서비스 제거
  void unregisterService(String serviceName) {
    _services.remove(serviceName);

    log('Service unregistered: $serviceName');
  }

  /// 이벤트 발행
  void emit(EventMessage event) {
    _eventController.add(event);

    final subscriptions = _subscriptions[event.eventType] ?? [];

    for (final subscription in subscriptions) {
      if (subscription.async) {
        Future.microtask(() => subscription.callback(event.data));
      } else {
        subscription.callback(event.data);
      }
    }

    log('Event emitted: ${event.eventType}');
  }

  /// 이벤트 구독
  EventSubscription subscribe({
    required String eventType,
    required Function(dynamic) callback,
    bool async = false,
  }) {
    final subscription = EventSubscription(
      subscriptionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      eventType: eventType,
      callback: callback,
      async: async,
    );

    _subscriptions.putIfAbsent(eventType, () => []).add(subscription);

    log('Subscribed to: $eventType');

    return subscription;
  }

  /// 이벤트 구독 취소
  void unsubscribe(EventSubscription subscription) {
    _subscriptions[subscription.eventType]?.remove(subscription);

    log('Unsubscribed from: ${subscription.eventType}');
  }

  /// 미들웨어 추가
  void useMiddleware(Middleware middleware) {
    _middlewares.add(middleware);

    log('Middleware added: ${middleware.name}');
  }

  /// 미들웨어 실행
  Future<dynamic> _executeMiddleware({
    required String serviceName,
    required String methodName,
    required dynamic Function() operation,
  }) async {
    dynamic Function() next = operation;

    // 미들웨어 체인 역순 실행
    for (final middleware in _middlewares.reversed) {
      final currentNext = next;
      next = () => middleware.handler(
        serviceName,
        methodName,
        currentNext,
      );
    }

    return await next();
  }

  /// 상태 컨테이너 생성
  StateContainer<T> createState<T>({
    required String stateId,
    required T initialState,
  }) {
    final container = StateContainer(
      stateId: stateId,
      initialState: initialState,
    );

    _stateContainers[stateId] = container;

    log('State created: $stateId');

    return container;
  }

  /// 상태 조회
  T? getState<T>(String stateId) {
    return _stateContainers[stateId]?.state as T?;
  }

  /// 상태 업데이트
  void updateState<T>(String stateId, T newState) {
    _stateContainers[stateId]?.update(newState);
  }

  /// 서비스 디스커버리
  ServiceDiscovery get serviceDiscovery => _serviceDiscovery;

  /// 로깅
  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';

    _logs.add(logEntry);
    _logController.add(logEntry);

    // 개발 모드에서만 콘솔 출력
    if (_isDebugMode()) {
      debugPrint(logEntry);
    }
  }

  /// 로그 조회
  List<String> getLogs({int limit = 100}) {
    return _logs.take(limit).toList();
  }

  /// 디버그 모드
  bool _isDebugMode() {
    return kDebugMode;
  }

  /// 서비스 메타데이터
  List<ServiceMetadata> getServiceMetadata() {
    return _services.entries.map((entry) {
      final registration = entry.value;

      return ServiceMetadata(
        serviceName: registration.serviceName,
        version: '1.0.0',
        description: '${registration.serviceType}',
        dependencies: [],
        lifecycle: ServiceLifecycle.initialized,
      );
    }).toList();
  }

  /// 상태 관리자
  Map<String, dynamic> getFrameworkState() {
    return {
      'isInitialized': _isInitialized,
      'services': _services.keys.toList(),
      'subscriptions': _subscriptions.entries.map((e) =>
        '${e.key}: ${e.value.length}').toList(),
      'stateContainers': _stateContainers.keys.toList(),
      'middlewares': _middlewares.map((m) => m.name).toList(),
      'logsCount': _logs.length,
    };
  }

  /// 리소스 정리
  Future<void> dispose() async {
    // 모든 상태 컨테이너 정리
    for (final container in _stateContainers.values) {
      container.dispose();
    }

    // 컨트롤러 정리
    await _eventController.close();
    await _logController.close();

    _isInitialized = false;

    log('Framework disposed');
  }
}

/// 서비스 찾을 수 없음 예외
class ServiceNotFoundException implements Exception {
  final String message;
  ServiceNotFoundException(this.message);

  @override
  String toString() => 'ServiceNotFoundException: $message';
}

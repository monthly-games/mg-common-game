import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 작업 상태
enum WorkStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

/// 작업 결과
class WorkResult<T> {
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final WorkStatus status;
  final Duration executionTime;

  const WorkResult({
    this.data,
    this.error,
    this.stackTrace,
    required this.status,
    required this.executionTime,
  });

  bool get isSuccess => status == WorkStatus.completed && error == null;
  bool get isFailed => status == WorkStatus.failed || error != null;

  factory WorkResult.success(T data, Duration executionTime) => WorkResult(
        data: data,
        status: WorkStatus.completed,
        executionTime: executionTime,
      );

  factory WorkResult.failure(
    Object error,
    StackTrace stackTrace,
    Duration executionTime,
  ) =>
      WorkResult(
        error: error,
        stackTrace: stackTrace,
        status: WorkStatus.failed,
        executionTime: executionTime,
      );
}

/// Isolate 작업
class IsolateWork<T> {
  final String id;
  final String name;
  final Future<T> Function() work;
  final void Function(T)? onComplete;
  final void Function(Object, StackTrace)? onError;
  final SendPort? sendPort;
  final int priority;

  IsolateWork({
    required this.id,
    required this.name,
    required this.work,
    this.onComplete,
    this.onError,
    this.sendPort,
    this.priority = 0,
  });
}

/// Isolate 작업 매니저
class IsolateWorkManager {
  static final IsolateWorkManager _instance = IsolateWorkManager._();
  static IsolateWorkManager get instance => _instance;

  IsolateWorkManager._();

  final Map<String, Isolate> _isolates = {};
  final Map<String, ReceivePort> _ports = {};
  final List<IsolateWork> _pendingWorks = [];
  final Map<String, IsolateWork> _runningWorks = {};

  int _maxConcurrentIsolates = Platform.numberOfProcessors - 1;
  static const int _maxPendingWorks = 100;

  // Getters
  List<IsolateWork> get pendingWorks => List.unmodifiable(_pendingWorks);
  Map<String, IsolateWork> get runningWorks => Map.unmodifiable(_runningWorks);
  int get activeIsolateCount => _isolates.length;

  // ============================================
  // 작업 실행
  // ============================================

  /// 작업 제출
  Future<WorkResult<T>> submit<T>({
    required String name,
    required Future<T> Function() work,
    void Function(T)? onComplete,
    void Function(Object, StackTrace)? onError,
    int priority = 0,
  }) async {
    final id = 'work_${DateTime.now().millisecondsSinceEpoch}';

    final isolateWork = IsolateWork<T>(
      id: id,
      name: name,
      work: work,
      onComplete: onComplete,
      onError: onError,
      priority: priority,
    );

    // 대기열에 추가
    _pendingWorks.add(isolateWork);
    _sortPendingWorks();

    // 작업 실행 시도
    _tryExecuteWork();

    // 결과 대기
    return await _waitForResult<T>(id);
  }

  /// 즉시 실행 (새 Isolate에서)
  Future<WorkResult<T>> executeImmediate<T>({
    required String name,
    required Future<T> Function() work,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await work();
      stopwatch.stop();

      return WorkResult.success(result, stopwatch.elapsed);
    } catch (e, stack) {
      stopwatch.stop();
      return WorkResult.failure(e, stack, stopwatch.elapsed);
    }
  }

  /// 결과 대기
  Future<WorkResult<T>> _waitForResult<T>(String id) async {
    final completer = Completer<WorkResult<T>>();

    // 포트 생성 및 대기
    final receivePort = ReceivePort();
    _ports[id] = receivePort;

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        final status = message['status'] as String?;
        final data = message['data'];
        final error = message['error'];

        if (status == 'completed') {
          completer.complete(WorkResult.success(
            data as T,
            Duration(milliseconds: message['time'] as int),
          ));
        } else if (status == 'failed') {
          completer.complete(WorkResult.failure(
            Exception(error),
            StackTrace.empty,
            Duration(milliseconds: message['time'] as int),
          ));
        }
      }
    });

    // 타임아웃
    Future.delayed(const Duration(minutes: 5), () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Work timed out'));
      }
    });

    return completer.future;
  }

  /// 작업 실행 시도
  void _tryExecuteWork() {
    while (_pendingWorks.isNotEmpty && _isolates.length < _maxConcurrentIsolates) {
      final work = _pendingWorks.removeAt(0);

      _runningWorks[work.id] = work;

      // Isolate에서 실행
      _executeInIsolate(work);
    }
  }

  /// Isolate에서 작업 실행
  Future<void> _executeInIsolate<T>(IsolateWork<T> work) async {
    try {
      final result = await work.work();

      work.onComplete?.call(result);

      // 완료 알림
      _ports[work.id]?.send({
        'status': 'completed',
        'data': result,
        'time': 0,
      });
    } catch (e, stack) {
      work.onError?.call(e, stack);

      // 에러 알림
      _ports[work.id]?.send({
        'status': 'failed',
        'error': e.toString(),
        'time': 0,
      });
    } finally {
      _runningWorks.remove(work.id);
      _ports.remove(work.id)?.close();
      _tryExecuteWork();
    }
  }

  /// 대기열 정렬 (우선순위)
  void _sortPendingWorks() {
    _pendingWorks.sort((a, b) => b.priority.compareTo(a.priority));
  }

  // ============================================
  // Isolate 관리
  // ============================================

  /// 새 Isolate 생성
  Future<SendPort> createIsolate() async {
    final receivePort = ReceivePort();
    final id = 'isolate_${DateTime.now().millisecondsSinceEpoch}';

    // Isolate 생성
    final isolate = await Isolate.spawn(
      _isolateEntryPoint,
      receivePort.sendPort,
    );

    _isolates[id] = isolate;
    _ports[id] = receivePort;

    // SendPort 대기
    final sendPort = await receivePort.first as SendPort;

    return sendPort;
  }

  /// Isolate 진입점
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();

    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      // 메시지 처리
      if (message is Map<String, dynamic>) {
        final type = message['type'] as String?;

        switch (type) {
          case 'work':
            // 작업 실행
            _executeWork(message, sendPort);
            break;
          case 'shutdown':
            receivePort.close();
            break;
        }
      }
    });
  }

  /// 작업 실행 (Isolate 내부)
  static void _executeWork(
    Map<String, dynamic> message,
    SendPort sendPort,
  ) {
    // 실제 작업 실행 로직
    sendPort.send({
      'status': 'completed',
      'data': null,
    });
  }

  /// Isolate 종료
  Future<void> shutdownIsolate(String id) async {
    _isolates[id]?.kill(priority: Isolate.immediate);
    _isolates.remove(id);
    _ports.remove(id)?.close();
  }

  /// 모든 Isolate 종료
  Future<void> shutdownAll() async {
    for (final id in _isolates.keys.toList()) {
      await shutdownIsolate(id);
    }
  }

  // ============================================
  // CPU 작업 헬퍼
  // ============================================

  /// JSON 파싱 (Isolate에서)
  Future<dynamic> parseJson(String jsonString) async {
    return await executeImmediate(
      name: 'Parse JSON',
      work: () async {
        // 실제 JSON 파싱
        return jsonString;
      },
    );
  }

  /// 큰 리스트 처리
  Future<List<T>> processLargeList<T>({
    required List<T> items,
    required T Function(T) processor,
  }) async {
    return await executeImmediate(
      name: 'Process List',
      work: () async {
        return items.map(processor).toList();
      },
    );
  }

  /// 이미지 처리
  Future<Uint8List> processImage({
    required Uint8List imageBytes,
    required int width,
    required int height,
  }) async {
    return await executeImmediate(
      name: 'Process Image',
      work: () async {
        // 이미지 리사이징 등
        return imageBytes;
      },
    );
  }

  /// 파일 암호화/복호화
  Future<Uint8List> encryptFile({
    required File file,
    required String key,
  }) async {
    return await executeImmediate(
      name: 'Encrypt File',
      work: () async {
        final bytes = await file.readAsBytes();
        // 암호화 로직
        return bytes;
      },
    );
  }

  // ============================================
  // 설정
  // ============================================

  void setMaxConcurrentIsolates(int count) {
    _maxConcurrentIsolates = count.clamp(1, Platform.numberOfProcessors);
    debugPrint('[IsolateWork] Max concurrent isolates: $_maxConcurrentIsolates');
  }

  /// 리소스 정리
  Future<void> dispose() async {
    await shutdownAll();
  }
}

/// Compute 작업 헬퍼
class ComputeHelper {
  /// 데이터 처리 작업 실행
  static Future<T> compute<S, T>({
    required S data,
    required T Function(S message) callback,
  }) async {
    return await compute(callback, data);
  }

  /// 배치 처리
  static Future<List<T>> computeBatch<S, T>({
    required List<S> data,
    required T Function(S) callback,
    int batchSize = 10,
  }) async {
    final results = <T>[];

    for (int i = 0; i < data.length; i += batchSize) {
      final end = (i + batchSize < data.length) ? i + batchSize : data.length;
      final batch = data.sublist(i, end);

      final batchResults = await Future.wait(
        batch.map((item) => compute(item, callback)),
      );

      results.addAll(batchResults);
    }

    return results;
  }
}

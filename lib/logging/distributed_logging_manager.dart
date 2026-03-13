import 'dart:async';
import 'package:flutter/material.dart';

class TraceSpan {
  final String traceId;
  final String spanId;
  final String parentSpanId;
  final String operationName;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> tags;

  const TraceSpan({
    required this.traceId,
    required this.spanId,
    this.parentSpanId,
    required this.operationName,
    required this.startTime,
    required this.endTime,
    required this.tags,
  });

  Duration get duration => endTime.difference(startTime);
}

class DistributedLogger {
  static final DistributedLogger _instance = DistributedLogger._();
  static DistributedLogger get instance => _instance;

  DistributedLogger._();

  final Map<String, TraceSpan> _traces = {};
  final StreamController<TraceSpan> _controller = StreamController.broadcast();

  Stream<TraceSpan> get onTrace => _controller.stream;

  String startTrace({
    required String operationName,
    String? parentTraceId,
    Map<String, dynamic>? tags,
  }) {
    final traceId = 'trace_${DateTime.now().millisecondsSinceEpoch}';
    final spanId = 'span_${DateTime.now().millisecondsSinceEpoch}';

    final span = TraceSpan(
      traceId: traceId,
      spanId: spanId,
      parentSpanId: parentTraceId,
      operationName: operationName,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      tags: tags ?? {},
    );

    _traces[traceId] = span;

    return traceId;
  }

  void endTrace(String traceId) {
    final span = _traces[traceId];
    if (span == null) return;

    final updated = TraceSpan(
      traceId: span.traceId,
      spanId: span.spanId,
      parentSpanId: span.parentSpanId,
      operationName: span.operationName,
      startTime: span.startTime,
      endTime: DateTime.now(),
      tags: span.tags,
    );

    _traces[traceId] = updated;
    _controller.add(updated);
  }

  List<TraceSpan> getTraces() {
    return _traces.values.toList();
  }

  void dispose() {
    _controller.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 데이터 파티션 타입
enum PartitionType {
  day,
  month,
  year,
}

/// 데이터 타입
enum DataType {
  event,
  metric,
  log,
  error,
  transaction,
}

/// 전송 모드
enum TransmissionMode {
  streaming,    // 실시간 전송
  batch,        // 일괄 전송
  hybrid,       // 혼합 모드
}

/// 데이터 품질
enum DataQuality {
  high,      // 즉시 전송
  medium,    // 배치 전송
  low,       // 샘플링 후 전송
}

/// BigQuery 로우
class BigQueryRow {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String insertId;

  BigQueryRow({
    required this.data,
    DateTime? timestamp,
    String? insertId,
  })  : timestamp = timestamp ?? DateTime.now(),
        insertId = insertId ?? '${timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}_${data.hashCode}';

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'insertId': insertId,
      };
}

/// 데이터 배치
class DataBatch {
  final String batchId;
  final List<BigQueryRow> rows;
  final DataType type;
  final DateTime createdAt;
  final int maxBatchSize;

  DataBatch({
    required this.type,
    this.maxBatchSize = 500,
    String? batchId,
    DateTime? createdAt,
  })  : batchId = batchId ?? 'batch_${DateTime.now().millisecondsSinceEpoch}',
        createdAt = createdAt ?? DateTime.now(),
        rows = [];

  bool get isFull => rows.length >= maxBatchSize;
  bool get isEmpty => rows.isEmpty;

  void addRow(BigQueryRow row) {
    if (!isFull) {
      rows.add(row);
    }
  }

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'type': type.name,
        'rows': rows.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

/// 파티션 메타데이터
class PartitionMetadata {
  final String tableId;
  final PartitionType type;
  final DateTime partitionDate;
  final int rowCount;
  final long sizeBytes;

  const PartitionMetadata({
    required this.tableId,
    required this.type,
    required this.partitionDate,
    required this.rowCount,
    required this.sizeBytes,
  });
}

/// 스트리밍 insert 결과
class StreamingInsertResult {
  final String batchId;
  final int successCount;
  final int failureCount;
  final List<String> errorMessages;

  const StreamingInsertResult({
    required this.batchId,
    required this.successCount,
    required this.failureCount,
    this.errorMessages = const [],
  });

  bool get isSuccessful => failureCount == 0;
}

/// 데이터 웨어하우스 관리자
class DataWarehouseManager {
  static final DataWarehouseManager _instance = DataWarehouseManager._();
  static DataWarehouseManager get instance => _instance;

  DataWarehouseManager._();

  SharedPreferences? _prefs;
  String? _projectId;
  String? _datasetId;

  final Map<DataType, DataBatch> _batches = {};
  final List<BigQueryRow> _pendingRows = [];

  TransmissionMode _transmissionMode = TransmissionMode.hybrid;
  Timer? _batchTimer;
  Timer? _cleanupTimer;

  final StreamController<StreamingInsertResult> _insertController =
      StreamController<StreamingInsertResult>.broadcast();
  final StreamController<Map<String, dynamic>> _queryController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<StreamingInsertResult> get onInsertResult => _insertController.stream;
  Stream<Map<String, dynamic>> get onQueryResult => _queryController.stream;

  int _totalRowsSent = 0;
  int _totalBytesSent = 0;
  double _totalCost = 0.0;

  /// 초기화
  Future<void> initialize({
    required String projectId,
    required String datasetId,
    TransmissionMode mode = TransmissionMode.hybrid,
  }) async {
    _prefs = await SharedPreferences.getInstance();
    _projectId = projectId;
    _datasetId = datasetId;
    _transmissionMode = mode;

    // 배치 초기화
    for (final type in DataType.values) {
      _batches[type] = DataBatch(type: type);
    }

    // 타이머 시작
    _startBatchTimer();
    _startCleanupTimer();

    // 통계 로드
    await _loadStatistics();

    debugPrint('[DataWarehouse] Initialized: $projectId.$datasetId');
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      flushBatches();
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupOldPartitions();
    });
  }

  Future<void> _loadStatistics() async {
    _totalRowsSent = _prefs?.getInt('dw_total_rows') ?? 0;
    _totalBytesSent = _prefs?.getInt('dw_total_bytes') ?? 0;
    _totalCost = _prefs?.getDouble('dw_total_cost') ?? 0.0;
  }

  Future<void> _saveStatistics() async {
    await _prefs?.setInt('dw_total_rows', _totalRowsSent);
    await _prefs?.setInt('dw_total_bytes', _totalBytesSent);
    await _prefs?.setDouble('dw_total_cost', _totalCost);
  }

  /// 이벤트 데이터 삽입
  void insertEvent({
    required String eventName,
    required Map<String, dynamic> eventData,
    String? userId,
    DataQuality quality = DataQuality.medium,
  }) {
    _insertRow(
      type: DataType.event,
      data: {
        'event_name': eventName,
        'event_data': eventData,
        if (userId != null) 'user_id': userId,
      },
      quality: quality,
    );
  }

  /// 메트릭 데이터 삽입
  void insertMetric({
    required String metricName,
    required double value,
    Map<String, dynamic>? labels,
    DataQuality quality = DataQuality.high,
  }) {
    _insertRow(
      type: DataType.metric,
      data: {
        'metric_name': metricName,
        'value': value,
        if (labels != null) 'labels': labels,
      },
      quality: quality,
    );
  }

  /// 로그 데이터 삽입
  void insertLog({
    required String level,
    required String message,
    Map<String, dynamic>? context,
    DataQuality quality = DataQuality.low,
  }) {
    _insertRow(
      type: DataType.log,
      data: {
        'level': level,
        'message': message,
        if (context != null) 'context': context,
      },
      quality: quality,
    );
  }

  /// 에러 데이터 삽입
  void insertError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
    DataQuality quality = DataQuality.high,
  }) {
    _insertRow(
      type: DataType.error,
      data: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
        if (context != null) 'context': context,
      },
      quality: quality,
    );
  }

  /// 트랜잭션 데이터 삽입
  void insertTransaction({
    required String transactionId,
    required String transactionType,
    required double amount,
    String? currency,
    Map<String, dynamic>? metadata,
    DataQuality quality = DataQuality.high,
  }) {
    _insertRow(
      type: DataType.transaction,
      data: {
        'transaction_id': transactionId,
        'transaction_type': transactionType,
        'amount': amount,
        if (currency != null) 'currency': currency,
        if (metadata != null) 'metadata': metadata,
      },
      quality: quality,
    );
  }

  void _insertRow({
    required DataType type,
    required Map<String, dynamic> data,
    required DataQuality quality,
  }) {
    final row = BigQueryRow(data: data);

    switch (_transmissionMode) {
      case TransmissionMode.streaming:
        if (quality == DataQuality.high) {
          _streamingInsert([row], type);
        } else {
          _addToBatch(type, row);
        }
        break;
      case TransmissionMode.batch:
        _addToBatch(type, row);
        break;
      case TransmissionMode.hybrid:
        if (quality == DataQuality.high) {
          _streamingInsert([row], type);
        } else {
          _addToBatch(type, row);
        }
        break;
    }
  }

  void _addToBatch(DataType type, BigQueryRow row) {
    final batch = _batches[type]!;
    batch.addRow(row);

    if (batch.isFull) {
      flushBatch(type);
    }
  }

  /// 스트리밍 insert
  Future<StreamingInsertResult> _streamingInsert(
    List<BigQueryRow> rows,
    DataType type,
  ) async {
    final batchId = 'streaming_${DateTime.now().millisecondsSinceEpoch}';
    int successCount = 0;
    int failureCount = 0;
    final List<String> errorMessages = [];

    try {
      // 실제 BigQuery API 호출 (시뮬레이션)
      await Future.delayed(const Duration(milliseconds: 100));

      successCount = rows.length;

      // 통계 업데이트
      _totalRowsSent += successCount;
      _totalBytesSent += _calculateBytes(rows);
      _totalCost += _calculateCost(successCount);

      await _saveStatistics();

      debugPrint('[DataWarehouse] Streaming insert: $successCount rows');
    } catch (e) {
      failureCount = rows.length;
      errorMessages.add(e.toString());
      debugPrint('[DataWarehouse] Streaming insert error: $e');
    }

    final result = StreamingInsertResult(
      batchId: batchId,
      successCount: successCount,
      failureCount: failureCount,
      errorMessages: errorMessages,
    );

    _insertController.add(result);

    return result;
  }

  /// 배치 flush
  Future<void> flushBatch(DataType type) async {
    final batch = _batches[type]!;
    if (batch.isEmpty) return;

    final result = await _streamingInsert(batch.rows, type);

    // 배치 초기화
    _batches[type] = DataBatch(type: type);
  }

  /// 모든 배치 flush
  Future<void> flushBatches() async {
    for (final type in DataType.values) {
      await flushBatch(type);
    }
  }

  /// 쿼리 실행
  Future<List<Map<String, dynamic>>> executeQuery({
    required String query,
    Map<String, dynamic>? parameters,
    int timeoutMs = 30000,
  }) async {
    try {
      debugPrint('[DataWarehouse] Query: $query');

      // 실제 BigQuery API 호출 (시뮬레이션)
      await Future.delayed(const Duration(milliseconds: 500));

      // 샘플 결과 반환
      final results = [
        {
          'event_name': 'app_open',
          'event_count': 1250,
          'date': DateTime.now().toIso8601String(),
        },
        {
          'event_name': 'purchase',
          'event_count': 85,
          'date': DateTime.now().toIso8601String(),
        },
      ];

      _queryController.add({'query': query, 'results': results});

      return results;
    } catch (e) {
      debugPrint('[DataWarehouse] Query error: $e');
      return [];
    }
  }

  /// 파티션 조회
  Future<List<PartitionMetadata>> getPartitions({
    required String tableId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      PartitionMetadata(
        tableId: tableId,
        type: PartitionType.day,
        partitionDate: DateTime.now(),
        rowCount: 1000000,
        sizeBytes: 1024 * 1024 * 100, // 100MB
      ),
    ];
  }

  /// 파티션 생성
  Future<void> createPartition({
    required String tableId,
    required PartitionType type,
    required DateTime date,
  }) async {
    debugPrint('[DataWarehouse] Creating partition: $tableId ${date.toIso8601String()}');

    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 파티션 삭제
  Future<void> deletePartition({
    required String tableId,
    required DateTime partitionDate,
  }) async {
    debugPrint('[DataWarehouse] Deleting partition: $tableId ${partitionDate.toIso8601String()}');

    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 오래된 파티션 정리
  Future<void> _cleanupOldPartitions() async {
    final retentionDays = await getRetentionDays();
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    debugPrint('[DataWarehouse] Cleaning up partitions older than $cutoffDate');

    // 실제로는 파티션 목록 조회 후 삭제
  }

  /// 데이터 보존 기간
  Future<int> getRetentionDays() async {
    return _prefs?.getInt('dw_retention_days') ?? 90;
  }

  /// 데이터 보존 기간 설정
  Future<void> setRetentionDays(int days) async {
    await _prefs?.setInt('dw_retention_days', days);
    debugPrint('[DataWarehouse] Retention set to $days days');
  }

  /// 샘플링 비율
  double getSamplingRate({
    DataType? type,
    DataQuality? quality,
  }) {
    // 품질별 샘플링 비율
    switch (quality) {
      case DataQuality.high:
        return 1.0; // 100%
      case DataQuality.medium:
        return 0.1; // 10%
      case DataQuality.low:
        return 0.01; // 1%
      default:
        return 1.0;
    }
  }

  /// 비용 계산
  double _calculateCost(int rowCount) {
    // BigQuery 스트리밍 insert 비용
    // TB당 $1.00 (실제 가격은 다를 수 있음)
    final costPerRow = 0.000001; // 약 $1/1M rows
    return rowCount * costPerRow;
  }

  /// 바이트 수 계산
  int _calculateBytes(List<BigQueryRow> rows) {
    return rows.fold<int>(
        0,
        (sum, row) => sum + jsonEncode(row.data).length);
  }

  /// 통계 정보 조회
  Map<String, dynamic> getStatistics() {
    return {
      'total_rows_sent': _totalRowsSent,
      'total_bytes_sent': _totalBytesSent,
      'total_cost': _totalCost,
      'transmission_mode': _transmissionMode.name,
      'pending_rows': _batches.values.fold<int>(
          0, (sum, batch) => sum + batch.rows.length),
    };
  }

  /// 전송 모드 변경
  void setTransmissionMode(TransmissionMode mode) {
    _transmissionMode = mode;
    debugPrint('[DataWarehouse] Transmission mode: ${mode.name}');
  }

  /// 테이블 스키마 생성
  Map<String, dynamic> createSchema({
    required List<Map<String, String>> fields,
  }) {
    return {
      'fields': fields.map((field) => {
        'name': field['name'],
        'type': field['type'],
        'mode': field['mode'] ?? 'NULLABLE',
      }).toList(),
    };
  }

  /// 테이블 생성
  Future<void> createTable({
    required String tableId,
    required Map<String, dynamic> schema,
    PartitionType? partitionType,
    int? partitionExpirationMs,
  }) async {
    debugPrint('[DataWarehouse] Creating table: $tableId');

    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(seconds: 1));
  }

  /// 테이블 삭제
  Future<void> deleteTable(String tableId) async {
    debugPrint('[DataWarehouse] Deleting table: $tableId');

    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 테이블 존재 여부 확인
  Future<bool> tableExists(String tableId) async {
    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// 데이터 내보내기
  Future<String> exportData({
    required String query,
    required String format, // CSV, JSON, Avro
    required String destinationUri,
  }) async {
    debugPrint('[DataWarehouse] Exporting data to $destinationUri');

    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(seconds: 2));

    return destinationUri;
  }

  /// 데이터 가져오기
  Future<void> importData({
    required String tableId,
    required String sourceUri,
    required String format, // CSV, JSON, Avro
  }) async {
    debugPrint('[DataWarehouse] Importing data from $sourceUri');

    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(seconds: 3));
  }

  /// 작업 상태 확인
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    // 실제 BigQuery API 호출 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'jobId': jobId,
      'status': 'DONE',
      'creationTime': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _batchTimer?.cancel();
    _cleanupTimer?.cancel();
    flushBatches();
    _insertController.close();
    _queryController.close();
  }
}

/// BigQuery 쿼리 빌더
class QueryBuilder {
  final List<String> _selectFields = [];
  final List<String> _fromTables = [];
  final List<String> _whereConditions = [];
  final List<String> _groupByFields = [];
  final List<String> _orderByFields = [];
  int? _limit;
  int? _offset;

  QueryBuilder select(List<String> fields) {
    _selectFields.addAll(fields);
    return this;
  }

  QueryBuilder from(String table) {
    _fromTables.add(table);
    return this;
  }

  QueryBuilder where(String condition) {
    _whereConditions.add(condition);
    return this;
  }

  QueryBuilder groupBy(List<String> fields) {
    _groupByFields.addAll(fields);
    return this;
  }

  QueryBuilder orderBy(String field, {bool ascending = true}) {
    _orderByFields.add('$field ${ascending ? "ASC" : "DESC"}');
    return this;
  }

  QueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  QueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  String build() {
    final buffer = StringBuffer();

    // SELECT
    buffer.write('SELECT ');
    buffer.write(_selectFields.isEmpty ? '*' : _selectFields.join(', '));

    // FROM
    buffer.write(' FROM ');
    buffer.write(_fromTables.join(', '));

    // WHERE
    if (_whereConditions.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(_whereConditions.join(' AND '));
    }

    // GROUP BY
    if (_groupByFields.isNotEmpty) {
      buffer.write(' GROUP BY ');
      buffer.write(_groupByFields.join(', '));
    }

    // ORDER BY
    if (_orderByFields.isNotEmpty) {
      buffer.write(' ORDER BY ');
      buffer.write(_orderByFields.join(', '));
    }

    // LIMIT
    if (_limit != null) {
      buffer.write(' LIMIT $_limit');
    }

    // OFFSET
    if (_offset != null) {
      buffer.write(' OFFSET $_offset');
    }

    return buffer.toString();
  }
}

/// 비용 최적화 매니저
class CostOptimizationManager {
  final DataWarehouseManager _dw = DataWarehouseManager.instance;

  /// 배치 크기 최적화
  int optimizeBatchSize(DataType type, int currentBatchSize) {
    // 스트리밍 insert는 최대 10,000 rows 제한
    const maxStreamingSize = 10000;
    const recommendedBatchSize = 500;

    if (currentBatchSize > maxStreamingSize) {
      return maxStreamingSize;
    }

    return recommendedBatchSize;
  }

  /// 전송 빈도 최적화
  Duration optimizeTransmissionFrequency(DataQuality quality) {
    switch (quality) {
      case DataQuality.high:
        return const Duration(seconds: 10); // 실시간
      case DataQuality.medium:
        return const Duration(minutes: 5); // 5분
      case DataQuality.low:
        return const Duration(hours: 1); // 1시간
    }
  }

  /// 데이터 파티셔닝 전략
  List<String> recommendPartitioning(String tableId) {
    return [
      'DATE(timestamp)',
      'user_id',
      'event_name',
    ];
  }

  /// 클러스터링 전략
  List<String> recommendClustering(String tableId) {
    return [
      'event_name',
      'timestamp',
    ];
  }
}

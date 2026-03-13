import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 서버 상태
enum ServerStatus {
  starting,       // 시작 중
  running,        // 실행 중
  stopping,       // 중지 중
  stopped,        // 중지됨
  error,          // 에러
  maintenance,    // 점검 중
}

/// 노드 역할
enum NodeRole {
  master,         // 마스터
  worker,         // 워커
  database,       // 데이터베이스
  cache,          // 캐시
  loadBalancer,   // 로드 밸런서
}

/// 서버 노드
class ServerNode {
  final String id;
  final String name;
  final String host;
  final int port;
  final NodeRole role;
  final ServerStatus status;
  final double cpuUsage; // 0.0 - 1.0
  final double memoryUsage; // 0.0 - 1.0
  final int activeConnections;
  final int maxConnections;
  final DateTime? lastHeartbeat;
  final Map<String, dynamic> metadata;

  const ServerNode({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.role,
    required this.status,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.activeConnections,
    required this.maxConnections,
    this.lastHeartbeat,
    required this.metadata,
  });

  /// 사용 가능 여부
  bool get isAvailable =>
      status == ServerStatus.running &&
      activeConnections < maxConnections &&
      cpuUsage < 0.9 &&
      memoryUsage < 0.9;

  /// 연결 가능 여부
  bool get canAcceptConnection => activeConnections < maxConnections;

  /// 부하 비율
  double get loadRatio =>
      maxConnections > 0 ? activeConnections / maxConnections : 0.0;
}

/// 로드 밸런싱 규칙
enum LoadBalancingStrategy {
  roundRobin,     // 라운드 로빈
  leastConnections, // 최소 연결
  weighted,        // 가중치 기반
  ipHash,         // IP 해시
  random,         // 랜덤
}

/// 클러스터
class Cluster {
  final String id;
  final String name;
  final String description;
  final List<ServerNode> nodes;
  final LoadBalancingStrategy strategy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Cluster({
    required this.id,
    required this.name,
    required this.description,
    required this.nodes,
    required this.strategy,
    required this.createdAt,
    this.updatedAt,
  });

  /// 활성 노드
  List<ServerNode> get activeNodes =>
      nodes.where((n) => n.status == ServerStatus.running).toList();

  /// 사용 가능 노드
  List<ServerNode> get availableNodes =>
      nodes.where((n) => n.isAvailable).toList();

  /// 총 용량
  int get totalCapacity =>
      nodes.fold<int>(0, (sum, n) => sum + n.maxConnections);

  /// 현재 사용량
  int get currentUsage =>
      nodes.fold<int>(0, (sum, n) => sum + n.activeConnections);

  /// 클러스터 부하
  double get clusterLoad =>
      totalCapacity > 0 ? currentUsage / totalCapacity : 0.0;
}

/// 스케일링 정책
class ScalingPolicy {
  final String id;
  final String name;
  final int minNodes;
  final int maxNodes;
  final double scaleUpThreshold; // CPU/메모리 임계값
  final double scaleDownThreshold;
  final Duration cooldown; // 스케일링 대기 시간
  final DateTime? lastScaled;

  const ScalingPolicy({
    required this.id,
    required this.name,
    required this.minNodes,
    required this.maxNodes,
    required this.scaleUpThreshold,
    required this.scaleDownThreshold,
    required this.cooldown,
    this.lastScaled,
  });

  /// 스케일업 가능 여부
  bool get canScaleUp {
    if (lastScaled == null) return true;
    return DateTime.now().difference(lastScaled!) > cooldown;
  }
}

/// 장애 복구 계획
class FailoverPlan {
  final String clusterId;
  final Map<String, String> failoverMap; // nodeId -> backupNodeId
  final bool autoFailover;
  final Duration detectionTimeout;
  final int maxRetries;

  const FailoverPlan({
    required this.clusterId,
    required this.failoverMap,
    required this.autoFailover,
    required this.detectionTimeout,
    required this.maxRetries,
  });
}

/// 서버 클러스터링 관리자
class ServerClusteringManager {
  static final ServerClusteringManager _instance =
      ServerClusteringManager._();
  static ServerClusteringManager get instance => _instance;

  ServerClusteringManager._();

  SharedPreferences? _prefs;

  final Map<String, Cluster> _clusters = {};
  final Map<String, ScalingPolicy> _scalingPolicies = {};
  final Map<String, FailoverPlan> _failoverPlans = {};

  final StreamController<Cluster> _clusterController =
      StreamController<Cluster>.broadcast();
  final StreamController<ServerNode> _nodeController =
      StreamController<ServerNode>.broadcast();
  final StreamController<ServerStatus> _statusController =
      StreamController<ServerStatus>.broadcast();

  Stream<Cluster> get onClusterUpdate => _clusterController.stream;
  Stream<ServerNode> get onNodeUpdate => _nodeController.stream;
  Stream<ServerStatus> get onStatusChange => _statusController.stream;

  Timer? _healthCheckTimer;
  Timer? _scalingTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 기본 클러스터 로드
    await _loadDefaultClusters();

    // 헬스 체크 시작
    _startHealthCheck();

    // 오토 스케일링 시작
    _startAutoScaling();

    debugPrint('[ServerClustering] Initialized');
  }

  Future<void> _loadDefaultClusters() async {
    // 게임 서버 클러스터
    _clusters['game_cluster'] = Cluster(
      id: 'game_cluster',
      name: '게임 서버 클러스터',
      description: '게임 로직 처리를 위한 서버 클러스터',
      nodes: [
        ServerNode(
          id: 'node_1',
          name: '게임 서버 1',
          host: '192.168.1.10',
          port: 8080,
          role: NodeRole.worker,
          status: ServerStatus.running,
          cpuUsage: 0.45,
          memoryUsage: 0.62,
          activeConnections: 450,
          maxConnections: 1000,
          lastHeartbeat: DateTime.now(),
          metadata: {},
        ),
        ServerNode(
          id: 'node_2',
          name: '게임 서버 2',
          host: '192.168.1.11',
          port: 8080,
          role: NodeRole.worker,
          status: ServerStatus.running,
          cpuUsage: 0.52,
          memoryUsage: 0.58,
          activeConnections: 520,
          maxConnections: 1000,
          lastHeartbeat: DateTime.now(),
          metadata: {},
        ),
        ServerNode(
          id: 'node_3',
          name: '게임 서버 3',
          host: '192.168.1.12',
          port: 8080,
          role: NodeRole.worker,
          status: ServerStatus.running,
          cpuUsage: 0.38,
          memoryUsage: 0.55,
          activeConnections: 380,
          maxConnections: 1000,
          lastHeartbeat: DateTime.now(),
          metadata: {},
        ),
      ],
      strategy: LoadBalancingStrategy.leastConnections,
      createdAt: DateTime.now(),
    );

    // 스케일링 정책
    _scalingPolicies['game_cluster'] = const ScalingPolicy(
      id: 'scaling_game',
      name: '게임 서버 스케일링',
      minNodes: 2,
      maxNodes: 10,
      scaleUpThreshold: 0.7,
      scaleDownThreshold: 0.3,
      cooldown: Duration(minutes: 5),
    );

    // 장애 복구 계획
    _failoverPlans['game_cluster'] = const FailoverPlan(
      clusterId: 'game_cluster',
      failoverMap: {
        'node_1': 'node_2',
        'node_2': 'node_3',
        'node_3': 'node_1',
      },
      autoFailover: true,
      detectionTimeout: Duration(seconds: 30),
      maxRetries: 3,
    );
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkNodeHealth();
    });
  }

  void _startAutoScaling() {
    _scalingTimer?.cancel();
    _scalingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _checkAutoScaling();
    });
  }

  /// 노드 헬스 체크
  void _checkNodeHealth() {
    for (final cluster in _clusters.values) {
      for (final node in cluster.nodes) {
        final isHealthy = _checkHeartbeat(node);

        if (!isHealthy && node.status == ServerStatus.running) {
          // 장애 감지
          _handleNodeFailure(cluster.id, node.id);
        } else if (isHealthy && node.status != ServerStatus.running) {
          // 복구
          _handleNodeRecovery(cluster.id, node);
        }

        // 메트릭 업데이트 (시뮬레이션)
        _updateNodeMetrics(cluster.id, node);
      }
    }
  }

  /// 하트비트 체크
  bool _checkHeartbeat(ServerNode node) {
    if (node.lastHeartbeat == null) return false;

    final elapsed = DateTime.now().difference(node.lastHeartbeat!);
    return elapsed.inSeconds < 30; // 30초 이내 응답
  }

  /// 노드 장애 처리
  void _handleNodeFailure(String clusterId, String nodeId) {
    final cluster = _clusters[clusterId];
    if (cluster == null) return;

    final node = cluster.nodes.firstWhere((n) => n.id == nodeId);
    final failoverPlan = _failoverPlans[clusterId];

    final failed = ServerNode(
      id: node.id,
      name: node.name,
      host: node.host,
      port: node.port,
      role: node.role,
      status: ServerStatus.error,
      cpuUsage: node.cpuUsage,
      memoryUsage: node.memoryUsage,
      activeConnections: 0,
      maxConnections: node.maxConnections,
      lastHeartbeat: node.lastHeartbeat,
      metadata: node.metadata,
    );

    _updateNodeInCluster(clusterId, failed);

    // 오토 장애 복구
    if (failoverPlan != null && failoverPlan.autoFailover) {
      _performFailover(clusterId, nodeId, failoverPlan);
    }

    debugPrint('[ServerClustering] Node failed: $nodeId');

    _statusController.add(ServerStatus.error);
  }

  /// 장애 복구
  void _performFailover(
    String clusterId,
    String failedNodeId,
    FailoverPlan plan,
  ) {
    final backupNodeId = plan.failoverMap[failedNodeId];
    if (backupNodeId == null) return;

    final cluster = _clusters[clusterId];
    if (cluster == null) return;

    final backupNode = cluster.nodes.firstWhere((n) => n.id == backupNodeId);

    // 백업 노드로 트래픽 재라우팅 (시뮬레이션)
    debugPrint('[ServerClustering] Failover: $failedNodeId -> $backupNodeId');
  }

  /// 노드 복구 처리
  void _handleNodeRecovery(String clusterId, ServerNode node) {
    final recovered = ServerNode(
      id: node.id,
      name: node.name,
      host: node.host,
      port: node.port,
      role: node.role,
      status: ServerStatus.running,
      cpuUsage: node.cpuUsage,
      memoryUsage: node.memoryUsage,
      activeConnections: node.activeConnections,
      maxConnections: node.maxConnections,
      lastHeartbeat: DateTime.now(),
      metadata: node.metadata,
    );

    _updateNodeInCluster(clusterId, recovered);

    debugPrint('[ServerClustering] Node recovered: ${node.id}');

    _statusController.add(ServerStatus.running);
  }

  /// 노드 메트릭 업데이트
  void _updateNodeMetrics(String clusterId, ServerNode node) {
    // 실제 환경에서는 모니터링 시스템에서 메트릭 수집
    final random = Random();
    final updatedCpu = (node.cpuUsage + (random.nextDouble() * 0.2 - 0.1))
        .clamp(0.0, 1.0);
    final updatedMemory = (node.memoryUsage + (random.nextDouble() * 0.2 - 0.1))
        .clamp(0.0, 1.0);

    final updated = ServerNode(
      id: node.id,
      name: node.name,
      host: node.host,
      port: node.port,
      role: node.role,
      status: node.status,
      cpuUsage: updatedCpu,
      memoryUsage: updatedMemory,
      activeConnections: node.activeConnections,
      maxConnections: node.maxConnections,
      lastHeartbeat: DateTime.now(),
      metadata: node.metadata,
    );

    _updateNodeInCluster(clusterId, updated);
    _nodeController.add(updated);
  }

  /// 오토 스케일링 체크
  void _checkAutoScaling() {
    for (final clusterId in _clusters.keys) {
      final policy = _scalingPolicies[clusterId];
      if (policy == null) continue;

      final cluster = _clusters[clusterId];
      if (cluster == null) continue;

      final avgCpu = cluster.activeNodes.isEmpty
          ? 0.0
          : cluster.activeNodes
                  .map((n) => n.cpuUsage)
                  .reduce((a, b) => a + b) / cluster.activeNodes.length;

      final avgMemory = cluster.activeNodes.isEmpty
          ? 0.0
          : cluster.activeNodes
                  .map((n) => n.memoryUsage)
                  .reduce((a, b) => a + b) / cluster.activeNodes.length;

      final avgLoad = (avgCpu + avgMemory) / 2;

      // 스케일업
      if (avgLoad > policy.scaleUpThreshold &&
          cluster.nodes.length < policy.maxNodes &&
          policy.canScaleUp) {
        _scaleUp(clusterId);
      }

      // 스케일다운
      if (avgLoad < policy.scaleDownThreshold &&
          cluster.nodes.length > policy.minNodes &&
          policy.canScaleUp) {
        _scaleDown(clusterId);
      }
    }
  }

  /// 스케일업
  Future<void> _scaleUp(String clusterId) async {
    final cluster = _clusters[clusterId];
    if (cluster == null) return;

    final newNode = ServerNode(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
      name: '게임 서버 ${cluster.nodes.length + 1}',
      host: '192.168.1.${100 + cluster.nodes.length}',
      port: 8080,
      role: NodeRole.worker,
      status: ServerStatus.starting,
      cpuUsage: 0.0,
      memoryUsage: 0.0,
      activeConnections: 0,
      maxConnections: 1000,
      lastHeartbeat: DateTime.now(),
      metadata: {},
    );

    final updated = Cluster(
      id: cluster.id,
      name: cluster.name,
      description: cluster.description,
      nodes: [...cluster.nodes, newNode],
      strategy: cluster.strategy,
      createdAt: cluster.createdAt,
      updatedAt: DateTime.now(),
    );

    _clusters[clusterId] = updated;
    _clusterController.add(updated);

    // 정책 업데이트
    final policy = _scalingPolicies[clusterId];
    if (policy != null) {
      _scalingPolicies[clusterId] = ScalingPolicy(
        id: policy.id,
        name: policy.name,
        minNodes: policy.minNodes,
        maxNodes: policy.maxNodes,
        scaleUpThreshold: policy.scaleUpThreshold,
        scaleDownThreshold: policy.scaleDownThreshold,
        cooldown: policy.cooldown,
        lastScaled: DateTime.now(),
      );
    }

    debugPrint('[ServerClustering] Scaled up: $clusterId');

    _statusController.add(ServerStatus.starting);
  }

  /// 스케일다운
  Future<void> _scaleDown(String clusterId) async {
    final cluster = _clusters[clusterId];
    if (cluster == null || cluster.nodes.length <= 2) return;

    // 가장 유휴한 노드 선택
    final sortedNodes = cluster.nodes.toList()
      ..sort((a, b) => a.activeConnections.compareTo(b.activeConnections));

    final nodeToRemove = sortedNodes.first;

    final updatedNodes = cluster.nodes.where((n) => n.id != nodeToRemove.id).toList();

    final updated = Cluster(
      id: cluster.id,
      name: cluster.name,
      description: cluster.description,
      nodes: updatedNodes,
      strategy: cluster.strategy,
      createdAt: cluster.createdAt,
      updatedAt: DateTime.now(),
    );

    _clusters[clusterId] = updated;
    _clusterController.add(updated);

    // 정책 업데이트
    final policy = _scalingPolicies[clusterId];
    if (policy != null) {
      _scalingPolicies[clusterId] = ScalingPolicy(
        id: policy.id,
        name: policy.name,
        minNodes: policy.minNodes,
        maxNodes: policy.maxNodes,
        scaleUpThreshold: policy.scaleUpThreshold,
        scaleDownThreshold: policy.scaleDownThreshold,
        cooldown: policy.cooldown,
        lastScaled: DateTime.now(),
      );
    }

    debugPrint('[ServerClustering] Scaled down: $clusterId');

    _statusController.add(ServerStatus.stopping);
  }

  /// 클러스터 내 노드 업데이트
  void _updateNodeInCluster(String clusterId, ServerNode updatedNode) {
    final cluster = _clusters[clusterId];
    if (cluster == null) return;

    final updatedNodes = cluster.nodes.map((n) {
      return n.id == updatedNode.id ? updatedNode : n;
    }).toList();

    final updated = Cluster(
      id: cluster.id,
      name: cluster.name,
      description: cluster.description,
      nodes: updatedNodes,
      strategy: cluster.strategy,
      createdAt: cluster.createdAt,
      updatedAt: DateTime.now(),
    );

    _clusters[clusterId] = updated;
    _clusterController.add(updated);
  }

  /// 로드 밸런싱 - 서버 선택
  ServerNode? selectServer(String clusterId, String? clientIp) {
    final cluster = _clusters[clusterId];
    if (cluster == null) return null;

    final availableNodes = cluster.availableNodes;
    if (availableNodes.isEmpty) return null;

    switch (cluster.strategy) {
      case LoadBalancingStrategy.roundRobin:
        // 순차 선택
        return availableNodes.first;

      case LoadBalancingStrategy.leastConnections:
        // 최소 연결 기반
        final sorted = availableNodes.toList()
          ..sort((a, b) => a.activeConnections.compareTo(b.activeConnections));
        return sorted.first;

      case LoadBalancingStrategy.weighted:
        // 가중치 기반 (CPU/메모리 고려)
        final sorted = availableNodes.toList()
          ..sort((a, b) =>
              ((a.cpuUsage + a.memoryUsage) / 2)
                  .compareTo((b.cpuUsage + b.memoryUsage) / 2));
        return sorted.first;

      case LoadBalancingStrategy.ipHash:
        // IP 해시
        if (clientIp != null) {
          final hash = clientIp.hashCode;
          final index = hash % availableNodes.length;
          return availableNodes[index];
        }
        return availableNodes.first;

      case LoadBalancingStrategy.random:
        // 랜덤
        return availableNodes[Random().nextInt(availableNodes.length)];

      default:
        return availableNodes.first;
    }
  }

  /// 클러스터 생성
  Future<Cluster> createCluster({
    required String name,
    required String description,
    required List<ServerNode> nodes,
    LoadBalancingStrategy strategy = LoadBalancingStrategy.leastConnections,
  }) async {
    final clusterId = 'cluster_${DateTime.now().millisecondsSinceEpoch}';
    final cluster = Cluster(
      id: clusterId,
      name: name,
      description: description,
      nodes: nodes,
      strategy: strategy,
      createdAt: DateTime.now(),
    );

    _clusters[clusterId] = cluster;
    _clusterController.add(cluster);

    // 기본 스케일링 정책 생성
    _scalingPolicies[clusterId] = const ScalingPolicy(
      id: 'scaling_$clusterId',
      name: '$name 스케일링',
      minNodes: 2,
      maxNodes: 10,
      scaleUpThreshold: 0.7,
      scaleDownThreshold: 0.3,
      cooldown: Duration(minutes: 5),
    );

    debugPrint('[ServerClustering] Cluster created: $name');

    return cluster;
  }

  /// 노드 추가
  Future<void> addNode({
    required String clusterId,
    required String name,
    required String host,
    required int port,
    required NodeRole role,
  }) async {
    final cluster = _clusters[clusterId];
    if (cluster == null) return;

    final node = ServerNode(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      host: host,
      port: port,
      role: role,
      status: ServerStatus.starting,
      cpuUsage: 0.0,
      memoryUsage: 0.0,
      activeConnections: 0,
      maxConnections: 1000,
      lastHeartbeat: DateTime.now(),
      metadata: {},
    );

    final updated = Cluster(
      id: cluster.id,
      name: cluster.name,
      description: cluster.description,
      nodes: [...cluster.nodes, node],
      strategy: cluster.strategy,
      createdAt: cluster.createdAt,
      updatedAt: DateTime.now(),
    );

    _clusters[clusterId] = updated;
    _clusterController.add(updated);

    debugPrint('[ServerClustering] Node added: $name');
  }

  /// 노드 제거
  Future<void> removeNode({
    required String clusterId,
    required String nodeId,
  }) async {
    final cluster = _clusters[clusterId];
    if (cluster == null) return;

    final updatedNodes = cluster.nodes.where((n) => n.id != nodeId).toList();

    if (updatedNodes.isEmpty) {
      throw Exception('Cannot remove last node');
    }

    final updated = Cluster(
      id: cluster.id,
      name: cluster.name,
      description: cluster.description,
      nodes: updatedNodes,
      strategy: cluster.strategy,
      createdAt: cluster.createdAt,
      updatedAt: DateTime.now(),
    );

    _clusters[clusterId] = updated;
    _clusterController.add(updated);

    debugPrint('[ServerClustering] Node removed: $nodeId');
  }

  /// 클러스터 조회
  Cluster? getCluster(String clusterId) {
    return _clusters[clusterId];
  }

  /// 모든 클러스터
  List<Cluster> getClusters() {
    return _clusters.values.toList();
  }

  /// 클러스터 통계
  Map<String, dynamic> getClusterStatistics(String clusterId) {
    final cluster = _clusters[clusterId];
    if (cluster == null) return {};

    return {
      'totalNodes': cluster.nodes.length,
      'activeNodes': cluster.activeNodes.length,
      'availableNodes': cluster.availableNodes.length,
      'totalCapacity': cluster.totalCapacity,
      'currentUsage': cluster.currentUsage,
      'clusterLoad': cluster.clusterLoad,
      'averageCpu': cluster.activeNodes.isEmpty
          ? 0.0
          : cluster.activeNodes.map((n) => n.cpuUsage).reduce((a, b) => a + b) /
              cluster.activeNodes.length,
      'averageMemory': cluster.activeNodes.isEmpty
          ? 0.0
          : cluster.activeNodes.map((n) => n.memoryUsage).reduce((a, b) => a + b) /
              cluster.activeNodes.length,
    };
  }

  void dispose() {
    _clusterController.close();
    _nodeController.close();
    _statusController.close();
    _healthCheckTimer?.cancel();
    _scalingTimer?.cancel();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

enum BuildStatus {
  pending,
  queued,
  running,
  success,
  failed,
  cancelled,
}

enum BuildType {
  debug,
  profile,
  release,
}

enum DeploymentStrategy {
  rolling,
  blueGreen,
  canary,
  allAtOnce,
}

class BuildConfig {
  final String buildId;
  final String version;
  final int buildNumber;
  final BuildType type;
  final String platform;
  final String environment;
  final Map<String, dynamic> environmentVariables;
  final List<String> enabledFeatures;

  const BuildConfig({
    required this.buildId,
    required this.version,
    required this.buildNumber,
    required this.type,
    required this.platform,
    required this.environment,
    required this.environmentVariables,
    required this.enabledFeatures,
  });

  String get fullName => '$version+$buildNumber';
}

class BuildJob {
  final String jobId;
  final BuildConfig config;
  final BuildStatus status;
  final DateTime queuedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? commitHash;
  final String? branch;
  final String? triggeredBy;
  final List<String> logs;
  final String? errorMessage;

  const BuildJob({
    required this.jobId,
    required this.config,
    required this.status,
    required this.queuedAt,
    this.startedAt,
    this.completedAt,
    this.commitHash,
    this.branch,
    this.triggeredBy,
    required this.logs,
    this.errorMessage,
  });

  Duration get duration {
    if (startedAt == null) return Duration.zero;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  bool get isCompleted => status == BuildStatus.success || status == BuildStatus.failed || status == BuildStatus.cancelled;
  bool get isSuccessful => status == BuildStatus.success;
  bool get isRunning => status == BuildStatus.running;
}

class DeploymentConfig {
  final String deploymentId;
  final String name;
  final String targetEnvironment;
  final DeploymentStrategy strategy;
  final int canaryPercentage;
  final Map<String, String> targetServers;
  final List<String> preDeploymentChecks;
  final List<String> postDeploymentChecks;

  const DeploymentConfig({
    required this.deploymentId,
    required this.name,
    required this.targetEnvironment,
    required this.strategy,
    required this.canaryPercentage,
    required this.targetServers,
    required this.preDeploymentChecks,
    required this.postDeploymentChecks,
  });
}

class Deployment {
  final String deploymentId;
  final String buildId;
  final DeploymentConfig config;
  final BuildStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> deployedServers;
  final String? rollbackTo;

  const Deployment({
    required this.deploymentId,
    required this.buildId,
    required this.config,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.deployedServers,
    this.rollbackTo,
  });

  Duration get duration {
    if (startedAt == null) return Duration.zero;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  double get progress {
    if (status == BuildStatus.success) return 1.0;
    if (status == BuildStatus.failed || status == BuildStatus.cancelled) return 0.0;
    if (startedAt == null) return 0.0;
    final elapsed = DateTime.now().difference(startedAt!).inSeconds;
    return (elapsed / 600).clamp(0.0, 1.0);
  }
}

class RollbackConfig {
  final String rollbackId;
  final String deploymentId;
  final String targetVersion;
  final DateTime createdAt;

  const RollbackConfig({
    required this.rollbackId,
    required this.deploymentId,
    required this.targetVersion,
    required this.createdAt,
  });
}

class CI CDManager {
  static final CI CDManager _instance = CI CDManager._();
  static CI CDManager get instance => _instance;

  CI CDManager._();

  final Map<String, BuildJob> _buildJobs = {};
  final Map<String, Deployment> _deployments = {};
  final Map<String, DeploymentConfig> _deploymentConfigs = {};
  final Map<String, RollbackConfig> _rollbacks = {};
  final Map<String, int> _versionCounters = {};
  final StreamController<CI CDEvent> _eventController = StreamController.broadcast();
  Timer? _buildTimer;

  Stream<CI CDEvent> get onCICDEvent => _eventController.stream;

  Future<void> initialize() async {
    _startBuildProcessor();
  }

  void _startBuildProcessor() {
    _buildTimer?.cancel();
    _buildTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _processQueuedBuilds(),
    );
  }

  Future<void> _processQueuedBuilds() async {
    final queuedJobs = _buildJobs.values
        .where((job) => job.status == BuildStatus.queued)
        .toList();

    for (final job in queuedJobs) {
      await _executeBuild(job.jobId);
    }
  }

  String queueBuild({
    required String version,
    required int buildNumber,
    required BuildType type,
    required String platform,
    String environment = 'production',
    String? commitHash,
    String? branch,
    String? triggeredBy,
    Map<String, dynamic>? environmentVariables,
    List<String>? enabledFeatures,
  }) {
    final buildId = 'build_${DateTime.now().millisecondsSinceEpoch}';
    final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';

    final config = BuildConfig(
      buildId: buildId,
      version: version,
      buildNumber: buildNumber,
      type: type,
      platform: platform,
      environment: environment,
      environmentVariables: environmentVariables ?? {},
      enabledFeatures: enabledFeatures ?? [],
    );

    final job = BuildJob(
      jobId: jobId,
      config: config,
      status: BuildStatus.queued,
      queuedAt: DateTime.now(),
      commitHash: commitHash,
      branch: branch,
      triggeredBy: triggeredBy,
      logs: [],
    );

    _buildJobs[jobId] = job;

    _eventController.add(CI CDEvent(
      type: CI CDEventType.buildQueued,
      jobId: jobId,
      buildId: buildId,
      timestamp: DateTime.now(),
    ));

    return jobId;
  }

  Future<void> _executeBuild(String jobId) async {
    final job = _buildJobs[jobId];
    if (job == null) return;

    final updated = BuildJob(
      jobId: job.jobId,
      config: job.config,
      status: BuildStatus.running,
      queuedAt: job.queuedAt,
      startedAt: DateTime.now(),
      completedAt: job.completedAt,
      commitHash: job.commitHash,
      branch: job.branch,
      triggeredBy: job.triggeredBy,
      logs: [...job.logs, 'Build started'],
    );

    _buildJobs[jobId] = updated;

    _eventController.add(CI CDEvent(
      type: CI CDEventType.buildStarted,
      jobId: jobId,
      buildId: job.config.buildId,
      timestamp: DateTime.now(),
    ));

    await Future.delayed(const Duration(seconds: 3));

    final success = DateTime.now().millisecondsSinceEpoch % 10 > 2;

    final finalJob = BuildJob(
      jobId: job.jobId,
      config: job.config,
      status: success ? BuildStatus.success : BuildStatus.failed,
      queuedAt: job.queuedAt,
      startedAt: updated.startedAt,
      completedAt: DateTime.now(),
      commitHash: job.commitHash,
      branch: job.branch,
      triggeredBy: job.triggeredBy,
      logs: [
        ...updated.logs,
        'Compiling sources...',
        'Running tests...',
        'Creating bundle...',
        success ? 'Build completed successfully' : 'Build failed',
      ],
      errorMessage: success ? null : 'Compilation error',
    );

    _buildJobs[jobId] = finalJob;

    _eventController.add(CI CDEvent(
      type: success ? CI CDEventType.buildSuccess : CI CDEventType.buildFailed,
      jobId: jobId,
      buildId: job.config.buildId,
      timestamp: DateTime.now(),
    ));
  }

  List<BuildJob> getBuildJobs() {
    return _buildJobs.values.toList()
      ..sort((a, b) => b.queuedAt.compareTo(a.queuedAt));
  }

  BuildJob? getBuildJob(String jobId) {
    return _buildJobs[jobId];
  }

  Future<bool> cancelBuild(String jobId) async {
    final job = _buildJobs[jobId];
    if (job == null) return false;
    if (job.isCompleted) return false;

    final updated = BuildJob(
      jobId: job.jobId,
      config: job.config,
      status: BuildStatus.cancelled,
      queuedAt: job.queuedAt,
      startedAt: job.startedAt,
      completedAt: DateTime.now(),
      commitHash: job.commitHash,
      branch: job.branch,
      triggeredBy: job.triggeredBy,
      logs: [...job.logs, 'Build cancelled'],
    );

    _buildJobs[jobId] = updated;

    return true;
  }

  void registerDeploymentConfig(DeploymentConfig config) {
    _deploymentConfigs[config.deploymentId] = config;
  }

  List<DeploymentConfig> getDeploymentConfigs() {
    return _deploymentConfigs.values.toList();
  }

  DeploymentConfig? getDeploymentConfig(String deploymentId) {
    return _deploymentConfigs[deploymentId];
  }

  String createDeployment({
    required String buildId,
    required String deploymentConfigId,
  }) {
    final config = _deploymentConfigs[deploymentConfigId];
    if (config == null) {
      throw Exception('Deployment config not found: $deploymentConfigId');
    }

    final deploymentId = 'deploy_${DateTime.now().millisecondsSinceEpoch}';

    final deployment = Deployment(
      deploymentId: deploymentId,
      buildId: buildId,
      config: config,
      status: BuildStatus.pending,
      createdAt: DateTime.now(),
      deployedServers: [],
    );

    _deployments[deploymentId] = deployment;

    _eventController.add(CI CDEvent(
      type: CI CDEventType.deploymentCreated,
      deploymentId: deploymentId,
      buildId: buildId,
      timestamp: DateTime.now(),
    ));

    return deploymentId;
  }

  Future<void> executeDeployment({
    required String deploymentId,
    Map<String, dynamic>? parameters,
  }) async {
    final deployment = _deployments[deploymentId];
    if (deployment == null) return;

    final updated = Deployment(
      deploymentId: deploymentId,
      buildId: deployment.buildId,
      config: deployment.config,
      status: BuildStatus.running,
      createdAt: deployment.createdAt,
      startedAt: DateTime.now(),
      completedAt: deployment.completedAt,
      deployedServers: deployment.deployedServers,
      rollbackTo: deployment.rollbackTo,
    );

    _deployments[deploymentId] = updated;

    _eventController.add(CI CDEvent(
      type: CI CDEventType.deploymentStarted,
      deploymentId: deploymentId,
      timestamp: DateTime.now(),
    ));

    await Future.delayed(const Duration(seconds: 2));

    final success = DateTime.now().millisecondsSinceEpoch % 10 > 1;

    final finalDeployment = Deployment(
      deploymentId: deploymentId,
      buildId: deployment.buildId,
      config: deployment.config,
      status: success ? BuildStatus.success : BuildStatus.failed,
      createdAt: deployment.createdAt,
      startedAt: updated.startedAt,
      completedAt: DateTime.now(),
      deployedServers: success ? deployment.config.targetServers.keys.toList() : [],
      rollbackTo: deployment.rollbackTo,
    );

    _deployments[deploymentId] = finalDeployment;

    _eventController.add(CI CDEvent(
      type: success ? CI CDEventType.deploymentSuccess : CI CDEventType.deploymentFailed,
      deploymentId: deploymentId,
      timestamp: DateTime.now(),
    ));
  }

  List<Deployment> getDeployments() {
    return _deployments.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Deployment? getDeployment(String deploymentId) {
    return _deployments[deploymentId];
  }

  Future<String> rollbackDeployment({
    required String deploymentId,
    required String targetVersion,
  }) async {
    final deployment = _deployments[deploymentId];
    if (deployment == null) {
      throw Exception('Deployment not found: $deploymentId');
    }

    final rollbackId = 'rollback_${DateTime.now().millisecondsSinceEpoch}';

    final rollback = RollbackConfig(
      rollbackId: rollbackId,
      deploymentId: deploymentId,
      targetVersion: targetVersion,
      createdAt: DateTime.now(),
    );

    _rollbacks[rollbackId] = rollback;

    await Future.delayed(const Duration(seconds: 1));

    _eventController.add(CI CDEvent(
      type: CI CDEventType.rollbackCompleted,
      deploymentId: deploymentId,
      timestamp: DateTime.now(),
    ));

    return rollbackId;
  }

  String getNextBuildNumber(String version) {
    final counter = (_versionCounters[version] ?? 0) + 1;
    _versionCounters[version] = counter;
    return counter.toString();
  }

  Map<String, dynamic> getBuildStats() {
    final jobs = _buildJobs.values.toList();
    final total = jobs.length;
    final success = jobs.where((j) => j.isSuccessful).length;
    final failed = jobs.where((j) => j.status == BuildStatus.failed).length;
    final running = jobs.where((j) => j.isRunning).length;

    return {
      'totalBuilds': total,
      'successfulBuilds': success,
      'failedBuilds': failed,
      'runningBuilds': running,
      'successRate': total > 0 ? success / total : 0.0,
    };
  }

  Map<String, dynamic> getDeploymentStats() {
    final deployments = _deployments.values.toList();
    final total = deployments.length;
    final success = deployments.where((d) => d.status == BuildStatus.success).length;
    final failed = deployments.where((d) => d.status == BuildStatus.failed).length;
    final running = deployments.where((d) => d.isRunning).length;

    return {
      'totalDeployments': total,
      'successfulDeployments': success,
      'failedDeployments': failed,
      'runningDeployments': running,
      'successRate': total > 0 ? success / total : 0.0,
    };
  }

  void dispose() {
    _buildTimer?.cancel();
    _eventController.close();
  }
}

class CI CDEvent {
  final CI CDEventType type;
  final String? jobId;
  final String? buildId;
  final String? deploymentId;
  final DateTime timestamp;

  const CI CDEvent({
    required this.type,
    this.jobId,
    this.buildId,
    this.deploymentId,
    required this.timestamp,
  });
}

enum CI CDEventType {
  buildQueued,
  buildStarted,
  buildSuccess,
  buildFailed,
  buildCancelled,
  deploymentCreated,
  deploymentStarted,
  deploymentSuccess,
  deploymentFailed,
  rollbackCompleted,
}

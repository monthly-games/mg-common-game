import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

enum BundleType {
  textures,
  audio,
  models,
  animations,
  ui,
  data,
  shaders,
  fonts,
}

enum BundleStatus {
  notDownloaded,
  downloading,
  downloaded,
  loading,
  loaded,
  failed,
  outdated,
}

enum DownloadPriority {
  low,
  normal,
  high,
  critical,
}

class AssetBundle {
  final String bundleId;
  final String name;
  final String version;
  final BundleType type;
  final BundleStatus status;
  final String url;
  final int size;
  final String checksum;
  final List<String> dependencies;
  final bool isRequired;
  final DateTime? lastUpdated;
  final String? localPath;
  final double downloadProgress;
  final int downloadedBytes;

  const AssetBundle({
    required this.bundleId,
    required this.name,
    required this.version,
    required this.type,
    required this.status,
    required this.url,
    required this.size,
    required this.checksum,
    required this.dependencies,
    required this.isRequired,
    this.lastUpdated,
    this.localPath,
    this.downloadProgress = 0.0,
    this.downloadedBytes = 0,
  });

  double get progress {
    if (status == BundleStatus.loaded) return 1.0;
    if (status == BundleStatus.notDownloaded) return 0.0;
    return downloadProgress;
  }

  bool get isAvailable => status == BundleStatus.loaded || status == BundleStatus.downloaded;
  bool get isDownloading => status == BundleStatus.downloading;
  bool get isOutdated => status == BundleStatus.outdated;
}

class BundleDownloadTask {
  final String taskId;
  final String bundleId;
  final DownloadPriority priority;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BundleStatus status;
  final String? errorMessage;
  final int totalBytes;
  final int downloadedBytes;

  const BundleDownloadTask({
    required this.taskId,
    required this.bundleId,
    required this.priority,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.status,
    this.errorMessage,
    required this.totalBytes,
    required this.downloadedBytes,
  });

  double get progress {
    if (totalBytes == 0) return 0.0;
    return downloadedBytes / totalBytes;
  }

  Duration get duration {
    if (startedAt == null) return Duration.zero;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  double get downloadSpeed {
    final elapsed = duration.inSeconds;
    if (elapsed == 0) return 0.0;
    return downloadedBytes / elapsed;
  }
}

class BundleCache {
  final Map<String, AssetBundle> bundles;
  final int totalSize;
  final int usedSize;
  final DateTime lastCleanup;

  const BundleCache({
    required this.bundles,
    required this.totalSize,
    required this.usedSize,
    required this.lastCleanup,
  });

  double get usageRate => totalSize > 0 ? usedSize / totalSize : 0.0;
  int get freeSize => totalSize - usedSize;
}

class AssetBundleManager {
  static final AssetBundleManager _instance = AssetBundleManager._();
  static AssetBundleManager get instance => _instance;

  AssetBundleManager._();

  final Map<String, AssetBundle> _bundles = {};
  final Map<String, BundleDownloadTask> _downloadTasks = {};
  final Map<String, List<String>> _loadedBundles = {};
  final StreamController<BundleEvent> _eventController = StreamController.broadcast();
  Timer? _cleanupTimer;
  String? _storagePath;

  Stream<BundleEvent> get onBundleEvent => _eventController.stream;

  Future<void> initialize({
    String? storagePath,
    int cacheSizeMB = 500,
  }) async {
    _storagePath = storagePath ?? _getDefaultStoragePath();
    await _loadBundleManifest();
    _startCleanupTimer();
  }

  String _getDefaultStoragePath() {
    return path.join(
      Directory.current.path,
      'asset_bundles',
    );
  }

  Future<void> _loadBundleManifest() async {
    final bundles = [
      AssetBundle(
        bundleId: 'ui_core',
        name: 'UI Core Assets',
        version: '1.0.0',
        type: BundleType.ui,
        status: BundleStatus.notDownloaded,
        url: 'https://cdn.example.com/bundles/ui_core.zip',
        size: 50 * 1024 * 1024,
        checksum: 'abc123',
        dependencies: [],
        isRequired: true,
      ),
      AssetBundle(
        bundleId: 'textures_hd',
        name: 'HD Textures',
        version: '1.2.0',
        type: BundleType.textures,
        status: BundleStatus.notDownloaded,
        url: 'https://cdn.example.com/bundles/textures_hd.zip',
        size: 200 * 1024 * 1024,
        checksum: 'def456',
        dependencies: [],
        isRequired: false,
      ),
      AssetBundle(
        bundleId: 'audio_bgm',
        name: 'Background Music',
        version: '1.1.0',
        type: BundleType.audio,
        status: BundleStatus.notDownloaded,
        url: 'https://cdn.example.com/bundles/audio_bgm.zip',
        size: 100 * 1024 * 1024,
        checksum: 'ghi789',
        dependencies: [],
        isRequired: false,
      ),
      AssetBundle(
        bundleId: 'models_characters',
        name: 'Character Models',
        version: '2.0.0',
        type: BundleType.models,
        status: BundleStatus.notDownloaded,
        url: 'https://cdn.example.com/bundles/models_characters.zip',
        size: 150 * 1024 * 1024,
        checksum: 'jkl012',
        dependencies: ['textures_hd'],
        isRequired: true,
      ),
    ];

    for (final bundle in bundles) {
      _bundles[bundle.bundleId] = bundle;
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _performCleanup(),
    );
  }

  List<AssetBundle> getAllBundles() {
    return _bundles.values.toList();
  }

  List<AssetBundle> getBundlesByType(BundleType type) {
    return _bundles.values
        .where((bundle) => bundle.type == type)
        .toList();
  }

  List<AssetBundle> getRequiredBundles() {
    return _bundles.values
        .where((bundle) => bundle.isRequired)
        .toList();
  }

  List<AssetBundle> getOutdatedBundles() {
    return _bundles.values
        .where((bundle) => bundle.isOutdated)
        .toList();
  }

  AssetBundle? getBundle(String bundleId) {
    return _bundles[bundleId];
  }

  Future<String> downloadBundle({
    required String bundleId,
    DownloadPriority priority = DownloadPriority.normal,
  }) async {
    final bundle = _bundles[bundleId];
    if (bundle == null) {
      throw Exception('Bundle not found: $bundleId');
    }

    await _checkDependencies(bundle);

    final task = BundleDownloadTask(
      taskId: 'task_${DateTime.now().millisecondsSinceEpoch}',
      bundleId: bundleId,
      priority: priority,
      createdAt: DateTime.now(),
      startedAt: DateTime.now(),
      status: BundleStatus.downloading,
      totalBytes: bundle.size,
      downloadedBytes: 0,
    );

    _downloadTasks[task.taskId] = task;

    _updateBundleStatus(bundleId, BundleStatus.downloading);

    _eventController.add(BundleEvent(
      type: BundleEventType.downloadStarted,
      bundleId: bundleId,
      taskId: task.taskId,
      timestamp: DateTime.now(),
    ));

    await _performDownload(task, bundle);

    return task.taskId;
  }

  Future<void> _checkDependencies(AssetBundle bundle) async {
    for (final depId in bundle.dependencies) {
      final dep = _bundles[depId];
      if (dep == null) {
        throw Exception('Dependency not found: $depId');
      }
      if (!dep.isAvailable) {
        await downloadBundle(bundleId: depId, priority: DownloadPriority.high);
      }
    }
  }

  Future<void> _performDownload(
    BundleDownloadTask task,
    AssetBundle bundle,
  ) async {
    final chunks = 10;
    final chunkSize = bundle.size ~/ chunks;

    for (int i = 0; i < chunks; i++) {
      await Future.delayed(const Duration(milliseconds: 500));

      final downloaded = (i + 1) * chunkSize;
      final updatedTask = BundleDownloadTask(
        taskId: task.taskId,
        bundleId: task.bundleId,
        priority: task.priority,
        createdAt: task.createdAt,
        startedAt: task.startedAt,
        status: task.status,
        totalBytes: task.totalBytes,
        downloadedBytes: downloaded,
      );

      _downloadTasks[task.taskId] = updatedTask;

      final updatedBundle = AssetBundle(
        bundleId: bundle.bundleId,
        name: bundle.name,
        version: bundle.version,
        type: bundle.type,
        status: bundle.status,
        url: bundle.url,
        size: bundle.size,
        checksum: bundle.checksum,
        dependencies: bundle.dependencies,
        isRequired: bundle.isRequired,
        lastUpdated: bundle.lastUpdated,
        localPath: bundle.localPath,
        downloadProgress: downloaded / bundle.size,
        downloadedBytes: downloaded,
      );

      _bundles[bundle.bundleId] = updatedBundle;

      _eventController.add(BundleEvent(
        type: BundleEventType.downloadProgress,
        bundleId: bundle.bundleId,
        taskId: task.taskId,
        timestamp: DateTime.now(),
        data: {
          'progress': updatedTask.progress,
          'downloadedBytes': downloaded,
        },
      ));
    }

    _updateBundleStatus(bundle.bundleId, BundleStatus.downloaded);

    _eventController.add(BundleEvent(
      type: BundleEventType.downloadCompleted,
      bundleId: bundle.bundleId,
      taskId: task.taskId,
      timestamp: DateTime.now(),
    ));
  }

  Future<bool> loadBundle(String bundleId) async {
    final bundle = _bundles[bundleId];
    if (bundle == null) return false;
    if (!bundle.isAvailable) return false;

    _updateBundleStatus(bundleId, BundleStatus.loading);

    _eventController.add(BundleEvent(
      type: BundleEventType.loadStarted,
      bundleId: bundleId,
      timestamp: DateTime.now(),
    ));

    await Future.delayed(const Duration(seconds: 1));

    _updateBundleStatus(bundleId, BundleStatus.loaded);

    _loadedBundles[bundleId] = [];

    _eventController.add(BundleEvent(
      type: BundleEventType.loadCompleted,
      bundleId: bundleId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> unloadBundle(String bundleId) async {
    final bundle = _bundles[bundleId];
    if (bundle == null) return false;

    _loadedBundles.remove(bundleId);

    _updateBundleStatus(bundleId, BundleStatus.downloaded);

    _eventController.add(BundleEvent(
      type: BundleEventType.unloaded,
      bundleId: bundleId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  void _updateBundleStatus(String bundleId, BundleStatus status) {
    final bundle = _bundles[bundleId];
    if (bundle == null) return;

    final updated = AssetBundle(
      bundleId: bundle.bundleId,
      name: bundle.name,
      version: bundle.version,
      type: bundle.type,
      status: status,
      url: bundle.url,
      size: bundle.size,
      checksum: bundle.checksum,
      dependencies: bundle.dependencies,
      isRequired: bundle.isRequired,
      lastUpdated: status == BundleStatus.loaded ? DateTime.now() : bundle.lastUpdated,
      localPath: bundle.localPath,
      downloadProgress: bundle.downloadProgress,
      downloadedBytes: bundle.downloadedBytes,
    );

    _bundles[bundleId] = updated;
  }

  Future<bool> deleteBundle(String bundleId) async {
    final bundle = _bundles[bundleId];
    if (bundle == null) return false;

    await unloadBundle(bundleId);

    _updateBundleStatus(bundleId, BundleStatus.notDownloaded);

    _eventController.add(BundleEvent(
      type: BundleEventType.deleted,
      bundleId: bundleId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<void> downloadRequiredBundles() async {
    final required = getRequiredBundles();
    for (final bundle in required) {
      if (!bundle.isAvailable) {
        await downloadBundle(
          bundleId: bundle.bundleId,
          priority: DownloadPriority.critical,
        );
      }
    }
  }

  Future<bool> updateBundle(String bundleId) async {
    final bundle = _bundles[bundleId];
    if (bundle == null) return false;

    await deleteBundle(bundleId);
    await downloadBundle(bundleId: bundleId);

    return true;
  }

  Future<void> updateAllBundles() async {
    final bundles = getAllBundles();
    for (final bundle in bundles) {
      if (bundle.isAvailable) {
        await updateBundle(bundle.bundleId);
      }
    }
  }

  BundleDownloadTask? getDownloadTask(String taskId) {
    return _downloadTasks[taskId];
  }

  List<BundleDownloadTask> getActiveDownloads() {
    return _downloadTasks.values
        .where((task) => task.status == BundleStatus.downloading)
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  BundleCache getCacheInfo() {
    final bundles = getAllBundles();
    final usedSize = bundles
        .where((b) => b.isAvailable)
        .fold<int>(0, (sum, b) => sum + b.size);

    return BundleCache(
      bundles: Map.from(_bundles),
      totalSize: 500 * 1024 * 1024,
      usedSize: usedSize,
      lastCleanup: DateTime.now(),
    );
  }

  Future<void> clearCache() async {
    final bundles = getAllBundles();
    for (final bundle in bundles) {
      if (!bundle.isRequired && bundle.isAvailable) {
        await deleteBundle(bundle.bundleId);
      }
    }

    _eventController.add(BundleEvent(
      type: BundleEventType.cacheCleared,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _performCleanup() async {
    final bundles = getAllBundles();
    for (final bundle in bundles) {
      if (!bundle.isRequired && bundle.isAvailable) {
        final lastUsed = bundle.lastUpdated;
        if (lastUsed != null) {
          final daysSinceUpdate = DateTime.now().difference(lastUsed).inDays;
          if (daysSinceUpdate > 30) {
            await deleteBundle(bundle.bundleId);
          }
        }
      }
    }

    _eventController.add(BundleEvent(
      type: BundleEventType.cleanupCompleted,
      timestamp: DateTime.now(),
    ));
  }

  Map<String, dynamic> getBundleStats() {
    final bundles = getAllBundles();
    final total = bundles.length;
    final downloaded = bundles.where((b) => b.isAvailable).length;
    final downloading = bundles.where((b) => b.isDownloading).length;
    final required = getRequiredBundles().length;
    final requiredDownloaded = getRequiredBundles()
        .where((b) => b.isAvailable)
        .length;

    int totalSize = 0;
    int downloadedSize = 0;
    for (final bundle in bundles) {
      totalSize += bundle.size;
      if (bundle.isAvailable) {
        downloadedSize += bundle.size;
      }
    }

    return {
      'totalBundles': total,
      'downloadedBundles': downloaded,
      'downloadingBundles': downloading,
      'requiredBundles': required,
      'requiredDownloaded': requiredDownloaded,
      'totalSize': totalSize,
      'downloadedSize': downloadedSize,
      'downloadProgress': totalSize > 0 ? downloadedSize / totalSize : 0.0,
    };
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _eventController.close();
  }
}

class BundleEvent {
  final BundleEventType type;
  final String? bundleId;
  final String? taskId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const BundleEvent({
    required this.type,
    this.bundleId,
    this.taskId,
    required this.timestamp,
    this.data,
  });
}

enum BundleEventType {
  downloadStarted,
  downloadProgress,
  downloadCompleted,
  downloadFailed,
  loadStarted,
  loadCompleted,
  loadFailed,
  unloaded,
  deleted,
  cacheCleared,
  cleanupCompleted,
  bundleUpdated,
}

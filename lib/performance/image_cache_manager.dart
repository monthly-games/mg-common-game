import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 캐시 정책
enum CachePolicy {
  /// 항상 캐시 사용
  always,

  /// 네트워크에서만 가져오기
  networkOnly,

  /// 캐시만 사용
  cacheOnly,

  /// 캐시 우선, 없으면 네트워크
  cacheFirst,
}

/// 이미지 캐시 항목
class ImageCacheItem {
  final String key;
  final String url;
  final Uint8List data;
  final DateTime cachedAt;
  final int size;
  final int accessCount;

  const ImageCacheItem({
    required this.key,
    required this.url,
    required this.data,
    required this.cachedAt,
    required this.size,
    required this.accessCount,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'key': key,
        'url': url,
        'cachedAt': cachedAt.toIso8601String(),
        'size': size,
        'accessCount': accessCount,
      };

  factory ImageCacheItem.fromJson(Map<String, dynamic> json) => ImageCacheItem(
        key: json['key'] as String,
        url: json['url'] as String,
        data: base64Decode(json['data'] as String),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        size: json['size'] as int,
        accessCount: json['accessCount'] as int,
      );

  /// 복사 (접근 횟수 증가)
  ImageCacheItem copyWith({int? accessCount}) => ImageCacheItem(
        key: key,
        url: url,
        data: data,
        cachedAt: cachedAt,
        size: size,
        accessCount: accessCount ?? this.accessCount + 1,
      );
}

/// 이미지 캐시 매니저
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._();
  static ImageCacheManager get instance => _instance;

  ImageCacheManager._();

  final Map<String, ImageCacheItem> _memoryCache = {};
  final StreamController<ImageCacheItem> _cacheUpdateController =
      StreamController<ImageCacheItem>.broadcast();

  Directory? _cacheDirectory;
  int _maxMemoryCacheSize = 100 * 1024 * 1024; // 100MB
  int _maxMemoryCacheItems = 100;
  int _currentMemoryCacheSize = 0;

  // Getters
  Map<String, ImageCacheItem> get memoryCache => Map.unmodifiable(_memoryCache);
  Stream<ImageCacheItem> get onCacheUpdate => _cacheUpdateController.stream;
  int get currentCacheSize => _currentMemoryCacheSize;
  int get cacheItemCount => _memoryCache.length;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_cacheDirectory != null) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDocDir.path}/image_cache');

    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }

    // 디스크 캐시 로드
    await _loadDiskCache();

    debugPrint('[ImageCache] Initialized');
    debugPrint('[ImageCache] Cache directory: ${_cacheDirectory!.path}');
  }

  // ============================================
  // 캐시 관리
  // ============================================

  /// 이미지 가져오기
  Future<Uint8List?> getImage(
    String url, {
    CachePolicy policy = CachePolicy.cacheFirst,
  }) async {
    final key = _generateCacheKey(url);

    // 캐시 정책에 따라 처리
    switch (policy) {
      case CachePolicy.cacheOnly:
        return _getFromCache(key);

      case CachePolicy.networkOnly:
        return await _fetchAndCache(url, key);

      case CachePolicy.always:
        final cached = _getFromCache(key);
        if (cached != null) return cached;
        return await _fetchAndCache(url, key);

      case CachePolicy.cacheFirst:
        final cached = _getFromCache(key);
        if (cached != null) {
          debugPrint('[ImageCache] Cache hit: $url');
          return cached;
        }
        return await _fetchAndCache(url, key);
    }
  }

  /// 캐시에서 가져오기
  Uint8List? _getFromCache(String key) {
    final item = _memoryCache[key];
    if (item != null) {
      // 접근 횟수 증가
      _memoryCache[key] = item.copyWith();
      return item.data;
    }

    // 디스크 캐시 확인
    return null;
  }

  /// 네트워크에서 가져와서 캐시
  Future<Uint8List?> _fetchAndCache(String url, String key) async {
    try {
      // 실제 구현에서는 HTTP 요청
      // 여기서는 시뮬레이션
      debugPrint('[ImageCache] Fetching: $url');

      // HttpClient로 이미지 가져오기
      final response = await HttpClient().getUrl(Uri.parse(url));
      final httpResponse = await response.close();

      final bytes = await consolidateHttpClientResponseBytes(
        httpResponse,
        onBytesReceived: ( cumulative,  total) {
          // 진행률 표시 등
        },
      );

      // 캐시에 저장
      await _cacheImage(key, url, bytes);

      return bytes;
    } catch (e) {
      debugPrint('[ImageCache] Error fetching image: $e');
      return null;
    }
  }

  /// 이미지 캐싱
  Future<void> _cacheImage(String key, String url, Uint8List data) async {
    final item = ImageCacheItem(
      key: key,
      url: url,
      data: data,
      cachedAt: DateTime.now(),
      size: data.length,
      accessCount: 1,
    );

    // 메모리 캐시에 추가
    _addToMemoryCache(item);

    // 디스크 캐시에 저장
    await _saveToDiskCache(item);

    _cacheUpdateController.add(item);
  }

  /// 메모리 캐시에 추가
  void _addToMemoryCache(ImageCacheItem item) {
    // 크기 제한 확인
    while (_currentMemoryCacheSize + item.size > _maxMemoryCacheSize ||
        _memoryCache.length >= _maxMemoryCacheItems) {
      _evictLeastUsed();
    }

    _memoryCache[item.key] = item;
    _currentMemoryCacheSize += item.size;
  }

  /// 가장 적게 사용된 항목 제거
  void _evictLeastUsed() {
    if (_memoryCache.isEmpty) return;

    String? leastUsedKey;
    int minAccess = 0x7FFFFFFFFFFFFFFF; // Max int64

    for (final entry in _memoryCache.entries) {
      if (entry.value.accessCount < minAccess) {
        minAccess = entry.value.accessCount;
        leastUsedKey = entry.key;
      }
    }

    if (leastUsedKey != null) {
      final removed = _memoryCache.remove(leastUsedKey);
      if (removed != null) {
        _currentMemoryCacheSize -= removed.size;
        debugPrint('[ImageCache] Evicted: ${removed.url}');
      }
    }
  }

  /// 디스크 캐시에 저장
  Future<void> _saveToDiskCache(ImageCacheItem item) async {
    if (_cacheDirectory == null) return;

    try {
      final file = File('${_cacheDirectory!.path}/${item.key}');
      await file.writeAsBytes(item.data);

      // 메타데이터 저장
      final metaFile = File('${_cacheDirectory!.path}/${item.key}.meta');
      await metaFile.writeAsString(jsonEncode(item.toJson()));
    } catch (e) {
      debugPrint('[ImageCache] Error saving to disk: $e');
    }
  }

  /// 디스크 캐시 로드
  Future<void> _loadDiskCache() async {
    if (_cacheDirectory == null) return;

    try {
      final files = _cacheDirectory!.listSync();

      for (final file in files) {
        if (file.path.endsWith('.meta')) {
          final metaFile = File(file.path);
          final metaJson = await metaFile.readAsString();
          final meta = jsonDecode(metaJson) as Map<String, dynamic>;

          final key = meta['key'] as String;
          final imageFile = File('${_cacheDirectory!.path}/$key');

          if (await imageFile.exists()) {
            final bytes = await imageFile.readAsBytes();

            final item = ImageCacheItem(
              key: key,
              url: meta['url'] as String,
              data: bytes,
              cachedAt: DateTime.parse(meta['cachedAt'] as String),
              size: meta['size'] as int,
              accessCount: meta['accessCount'] as int,
            );

            _memoryCache[key] = item;
            _currentMemoryCacheSize += item.size;
          }
        }
      }

      debugPrint('[ImageCache] Loaded ${_memoryCache.length} items from disk');
    } catch (e) {
      debugPrint('[ImageCache] Error loading disk cache: $e');
    }
  }

  /// 캐시 키 생성
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================
  // 캐스텀 Image 위젯
  // ============================================

  /// 캐시된 이미지 위젯
  Widget buildCachedImage(
    String url, {
    Widget Function(BuildContext)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    CachePolicy policy = CachePolicy.cacheFirst,
  }) {
    return FutureBuilder<Uint8List?>(
      future: getImage(url, policy: policy),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return errorBuilder?.call(
                context,
                snapshot.error ?? Exception('Image not found'),
                snapshot.stackTrace,
              ) ??
              const Icon(Icons.error);
        }

        return Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
        );
      },
    );
  }

  // ============================================
  // 캐시 관리
  // ============================================

  /// 캐시 지우기
  Future<void> clearCache() async {
    _memoryCache.clear();
    _currentMemoryCacheSize = 0;

    if (_cacheDirectory != null) {
      await _cacheDirectory!.delete(recursive: true);
      await _cacheDirectory!.create(recursive: true);
    }

    debugPrint('[ImageCache] Cache cleared');
  }

  /// 특정 URL 캐시 삭제
  Future<void> removeCache(String url) async {
    final key = _generateCacheKey(url);
    final removed = _memoryCache.remove(key);
    if (removed != null) {
      _currentMemoryCacheSize -= removed.size;
    }

    if (_cacheDirectory != null) {
      final file = File('${_cacheDirectory!.path}/$key');
      final metaFile = File('${_cacheDirectory!.path}/$key.meta');

      if (await file.exists()) await file.delete();
      if (await metaFile.exists()) await metaFile.delete();
    }
  }

  /// 캐시 크기 설정
  void setMaxMemoryCacheSize(int bytes) {
    _maxMemoryCacheSize = bytes;
    _enforceMemoryLimit();
  }

  void _enforceMemoryLimit() {
    while (_currentMemoryCacheSize > _maxMemoryCacheSize) {
      _evictLeastUsed();
    }
  }

  /// 캐시 통계
  Map<String, dynamic> getStatistics() {
    return {
      'memory_cache_items': _memoryCache.length,
      'memory_cache_size': _currentMemoryCacheSize,
      'max_memory_cache_size': _maxMemoryCacheSize,
      'max_memory_cache_items': _maxMemoryCacheItems,
      'cache_directory': _cacheDirectory?.path,
    };
  }

  /// 리소스 정리
  void dispose() {
    _cacheUpdateController.close();
  }
}

/// Optimized Network Image
class OptimizedNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final CachePolicy cachePolicy;

  const OptimizedNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.cachePolicy = CachePolicy.cacheFirst,
  });

  @override
  State<OptimizedNetworkImage> createState => _OptimizedNetworkImageState();
}

class _OptimizedNetworkImageState extends State<OptimizedNetworkImage> {
  Uint8List? _imageData;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final data = await ImageCacheManager.instance.getImage(
        widget.url,
        policy: widget.cachePolicy,
      );

      if (mounted && data != null) {
        setState(() {
          _imageData = data;
        });
      } else if (mounted) {
        setState(() {
          _error = Exception('Failed to load image');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
    }
  }

  @override
  void didUpdateWidget(OptimizedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _imageData = null;
      _error = null;
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ?? const Icon(Icons.error);
    }

    if (_imageData == null) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
          );
    }

    return Image.memory(
      _imageData!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      gaplessPlayback: true,
    );
  }
}

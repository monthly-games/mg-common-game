import 'dart:async';

/// Mock Services for Testing
///
/// Provides mock implementations of common game services for testing.

// ============================================================
// Mock Audio Service
// ============================================================

/// Mock audio service for testing
class MockAudioService {
  bool _bgmPlaying = false;
  bool _sfxEnabled = true;
  double _bgmVolume = 1.0;
  double _sfxVolume = 1.0;
  String? _currentBgm;
  final List<String> _playedSfx = [];

  bool get isBgmPlaying => _bgmPlaying;
  bool get isSfxEnabled => _sfxEnabled;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  String? get currentBgm => _currentBgm;
  List<String> get playedSfx => List.unmodifiable(_playedSfx);

  Future<void> playBgm(String path) async {
    _currentBgm = path;
    _bgmPlaying = true;
  }

  void stopBgm() {
    _bgmPlaying = false;
    _currentBgm = null;
  }

  void pauseBgm() {
    _bgmPlaying = false;
  }

  void resumeBgm() {
    if (_currentBgm != null) {
      _bgmPlaying = true;
    }
  }

  Future<void> playSfx(String path) async {
    if (_sfxEnabled) {
      _playedSfx.add(path);
    }
  }

  void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  void reset() {
    _bgmPlaying = false;
    _sfxEnabled = true;
    _bgmVolume = 1.0;
    _sfxVolume = 1.0;
    _currentBgm = null;
    _playedSfx.clear();
  }
}

// ============================================================
// Mock Analytics Service
// ============================================================

/// Mock analytics service for testing
class MockAnalyticsService {
  final List<AnalyticsEventRecord> _events = [];
  final Map<String, String> _userProperties = {};
  String? _userId;
  String? _currentScreen;

  List<AnalyticsEventRecord> get events => List.unmodifiable(_events);
  Map<String, String> get userProperties => Map.unmodifiable(_userProperties);
  String? get userId => _userId;
  String? get currentScreen => _currentScreen;

  void logEvent(String name, [Map<String, dynamic>? params]) {
    _events.add(AnalyticsEventRecord(
      name: name,
      params: params ?? {},
      timestamp: DateTime.now(),
    ));
  }

  void setUserId(String id) {
    _userId = id;
  }

  void setUserProperty(String name, String value) {
    _userProperties[name] = value;
  }

  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
    logEvent('screen_view', {'screen_name': screenName});
  }

  bool hasEvent(String name) {
    return _events.any((e) => e.name == name);
  }

  AnalyticsEventRecord? getLastEvent(String name) {
    return _events.lastWhere(
      (e) => e.name == name,
      orElse: () => throw StateError('Event not found: $name'),
    );
  }

  int countEvents(String name) {
    return _events.where((e) => e.name == name).length;
  }

  void reset() {
    _events.clear();
    _userProperties.clear();
    _userId = null;
    _currentScreen = null;
  }
}

class AnalyticsEventRecord {
  final String name;
  final Map<String, dynamic> params;
  final DateTime timestamp;

  AnalyticsEventRecord({
    required this.name,
    required this.params,
    required this.timestamp,
  });

  @override
  String toString() => 'Event($name, $params)';
}

// ============================================================
// Mock Storage Service
// ============================================================

/// Mock storage service for testing
class MockStorageService {
  final Map<String, dynamic> _data = {};

  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  Future<String?> getString(String key) async {
    return _data[key] as String?;
  }

  Future<void> setInt(String key, int value) async {
    _data[key] = value;
  }

  Future<int?> getInt(String key) async {
    return _data[key] as int?;
  }

  Future<void> setDouble(String key, double value) async {
    _data[key] = value;
  }

  Future<double?> getDouble(String key) async {
    return _data[key] as double?;
  }

  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  Future<bool?> getBool(String key) async {
    return _data[key] as bool?;
  }

  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
  }

  Future<List<String>?> getStringList(String key) async {
    return _data[key] as List<String>?;
  }

  Future<void> remove(String key) async {
    _data.remove(key);
  }

  Future<void> clear() async {
    _data.clear();
  }

  bool containsKey(String key) => _data.containsKey(key);

  Set<String> get keys => _data.keys.toSet();

  void reset() {
    _data.clear();
  }
}

// ============================================================
// Mock Network Service
// ============================================================

/// Mock network service for testing
class MockNetworkService {
  final Map<String, dynamic> _responses = {};
  final List<NetworkRequestRecord> _requests = [];
  bool _isOnline = true;
  Duration _delay = Duration.zero;

  List<NetworkRequestRecord> get requests => List.unmodifiable(_requests);
  bool get isOnline => _isOnline;

  void setOnline(bool online) {
    _isOnline = online;
  }

  void setDelay(Duration delay) {
    _delay = delay;
  }

  void mockResponse(String endpoint, dynamic response) {
    _responses[endpoint] = response;
  }

  void mockError(String endpoint, Exception error) {
    _responses[endpoint] = error;
  }

  Future<T> get<T>(String endpoint, {Map<String, String>? headers}) async {
    return _request<T>('GET', endpoint, headers: headers);
  }

  Future<T> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    return _request<T>('POST', endpoint, body: body, headers: headers);
  }

  Future<T> _request<T>(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    _requests.add(NetworkRequestRecord(
      method: method,
      endpoint: endpoint,
      body: body,
      headers: headers,
      timestamp: DateTime.now(),
    ));

    if (!_isOnline) {
      throw NetworkException('No internet connection');
    }

    if (_delay > Duration.zero) {
      await Future.delayed(_delay);
    }

    final response = _responses[endpoint];
    if (response == null) {
      throw NetworkException('No mock response for: $endpoint');
    }

    if (response is Exception) {
      throw response;
    }

    return response as T;
  }

  bool hasRequest(String endpoint) {
    return _requests.any((r) => r.endpoint == endpoint);
  }

  int countRequests(String endpoint) {
    return _requests.where((r) => r.endpoint == endpoint).length;
  }

  void reset() {
    _responses.clear();
    _requests.clear();
    _isOnline = true;
    _delay = Duration.zero;
  }
}

class NetworkRequestRecord {
  final String method;
  final String endpoint;
  final dynamic body;
  final Map<String, String>? headers;
  final DateTime timestamp;

  NetworkRequestRecord({
    required this.method,
    required this.endpoint,
    this.body,
    this.headers,
    required this.timestamp,
  });

  @override
  String toString() => '$method $endpoint';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

// ============================================================
// Mock Purchase Service
// ============================================================

/// Mock in-app purchase service for testing
class MockPurchaseService {
  final Map<String, ProductInfo> _products = {};
  final List<PurchaseRecord> _purchases = [];
  bool _isAvailable = true;

  List<PurchaseRecord> get purchases => List.unmodifiable(_purchases);
  bool get isAvailable => _isAvailable;

  void setAvailable(bool available) {
    _isAvailable = available;
  }

  void addProduct(ProductInfo product) {
    _products[product.id] = product;
  }

  Future<List<ProductInfo>> getProducts(List<String> ids) async {
    if (!_isAvailable) {
      throw PurchaseException('Store not available');
    }
    return ids
        .map((id) => _products[id])
        .whereType<ProductInfo>()
        .toList();
  }

  Future<PurchaseResult> purchase(String productId) async {
    if (!_isAvailable) {
      throw PurchaseException('Store not available');
    }

    final product = _products[productId];
    if (product == null) {
      return PurchaseResult(
        success: false,
        productId: productId,
        error: 'Product not found',
      );
    }

    final record = PurchaseRecord(
      productId: productId,
      transactionId: 'mock_tx_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
    );
    _purchases.add(record);

    return PurchaseResult(
      success: true,
      productId: productId,
      transactionId: record.transactionId,
    );
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      throw PurchaseException('Store not available');
    }
    // No-op for mock
  }

  bool hasPurchased(String productId) {
    return _purchases.any((p) => p.productId == productId);
  }

  void reset() {
    _products.clear();
    _purchases.clear();
    _isAvailable = true;
  }
}

class ProductInfo {
  final String id;
  final String title;
  final String description;
  final String price;
  final double priceValue;

  ProductInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceValue,
  });
}

class PurchaseRecord {
  final String productId;
  final String transactionId;
  final DateTime timestamp;

  PurchaseRecord({
    required this.productId,
    required this.transactionId,
    required this.timestamp,
  });
}

class PurchaseResult {
  final bool success;
  final String productId;
  final String? transactionId;
  final String? error;

  PurchaseResult({
    required this.success,
    required this.productId,
    this.transactionId,
    this.error,
  });
}

class PurchaseException implements Exception {
  final String message;
  PurchaseException(this.message);

  @override
  String toString() => 'PurchaseException: $message';
}

// ============================================================
// Mock Ad Service
// ============================================================

/// Mock ad service for testing
class MockAdService {
  final List<AdRecord> _shownAds = [];
  bool _isInitialized = false;
  bool _rewardedAdLoaded = false;
  bool _interstitialAdLoaded = false;
  bool _shouldReward = true;

  List<AdRecord> get shownAds => List.unmodifiable(_shownAds);
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  void setRewardedAdLoaded(bool loaded) {
    _rewardedAdLoaded = loaded;
  }

  void setInterstitialAdLoaded(bool loaded) {
    _interstitialAdLoaded = loaded;
  }

  void setShouldReward(bool reward) {
    _shouldReward = reward;
  }

  bool isRewardedAdReady() => _rewardedAdLoaded;
  bool isInterstitialAdReady() => _interstitialAdLoaded;

  Future<bool> showRewardedAd({
    required void Function(String type, int amount) onRewarded,
    void Function()? onClosed,
  }) async {
    if (!_rewardedAdLoaded) return false;

    _shownAds.add(AdRecord(type: 'rewarded', timestamp: DateTime.now()));

    if (_shouldReward) {
      onRewarded('coins', 100);
    }
    onClosed?.call();

    return true;
  }

  Future<bool> showInterstitialAd({void Function()? onClosed}) async {
    if (!_interstitialAdLoaded) return false;

    _shownAds.add(AdRecord(type: 'interstitial', timestamp: DateTime.now()));
    onClosed?.call();

    return true;
  }

  int countAdsShown(String type) {
    return _shownAds.where((a) => a.type == type).length;
  }

  void reset() {
    _shownAds.clear();
    _isInitialized = false;
    _rewardedAdLoaded = false;
    _interstitialAdLoaded = false;
    _shouldReward = true;
  }
}

class AdRecord {
  final String type;
  final DateTime timestamp;

  AdRecord({required this.type, required this.timestamp});
}

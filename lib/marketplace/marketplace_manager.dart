import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 아이템 등급
enum ItemGrade {
  common,       // 일반
  uncommon,     // 고급
  rare,         // 희귀
  epic,         // 에픽
  legendary,    // 전설
  mythical,     // 신화
}

/// 거래 유형
enum TransactionType {
  sale,         // 판매
  purchase,     // 구매
  cancel,       // 취소
  expire,       // 만료
}

/// 경매 상태
enum AuctionStatus {
  active,       // 진행 중
  sold,         // 판매 완료
  expired,      // 만료
  cancelled,    // 취소됨
}

/// 아이템
class Item {
  final String id;
  final String name;
  final String description;
  final ItemGrade grade;
  final String type;
  final String iconUrl;
  final Map<String, dynamic> stats;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.grade,
    required this.type,
    required this.iconUrl,
    required this.stats,
  });
}

/// 시장 등록 아이템
class MarketListing {
  final String id;
  final String sellerId;
  final String sellerName;
  final Item item;
  final int price;
  final int quantity;
  final DateTime listedAt;
  final DateTime? expiresAt;
  final bool isAuction; // 경매 여부
  final int? buyNowPrice; // 즉시 구매가 (경매만)
  final int? currentBid; // 현재 입찰가 (경매만)
  final String? currentBidderId; // 현재 입찰자 (경매만)

  const MarketListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.item,
    required this.price,
    required this.quantity,
    required this.listedAt,
    this.expiresAt,
    required this.isAuction,
    this.buyNowPrice,
    this.currentBid,
    this.currentBidderId,
  });

  /// 남은 시간
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// 경매 진행 중
  bool get isActive => remainingTime != null && remainingTime! > Duration.zero;
}

/// 거래 기록
class Transaction {
  final String id;
  final String listingId;
  final String sellerId;
  final String sellerName;
  final String buyerId;
  final String buyerName;
  final Item item;
  final int quantity;
  final int price;
  final int fee; // 수수료
  final TransactionType type;
  final DateTime timestamp;

  const Transaction({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.item,
    required this.quantity,
    required this.price,
    required this.fee,
    required this.type,
    required this.timestamp,
  });
}

/// 입찰
class Bid {
  final String id;
  final String listingId;
  final String bidderId;
  final String bidderName;
  final int amount;
  final DateTime timestamp;

  const Bid({
    required this.id,
    required this.listingId,
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });
}

/// 즐겨찾기
class Watchlist {
  final String userId;
  final List<String> listingIds;
  final DateTime updatedAt;

  const Watchlist({
    required this.userId,
    required this.listingIds,
    required this.updatedAt,
  });
}

/// 거래소 관리자
class MarketplaceManager {
  static final MarketplaceManager _instance = MarketplaceManager._();
  static MarketplaceManager get instance => _instance;

  MarketplaceManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, MarketListing> _listings = {};
  final Map<String, List<Transaction>> _transactions = {};
  final Map<String, List<Bid>> _bids = {};
  final Map<String, Watchlist> _watchlists = {};

  final StreamController<MarketListing> _listingController =
      StreamController<MarketListing>.broadcast();
  final StreamController<Transaction> _transactionController =
      StreamController<Transaction>.broadcast();
  final StreamController<Bid> _bidController =
      StreamController<Bid>.broadcast();

  Stream<MarketListing> get onListingUpdate => _listingController.stream;
  Stream<Transaction> get onTransaction => _transactionController.stream;
  Stream<Bid> get onBid => _bidController.stream;

  Timer? _auctionTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 경매 타이머 시작
    _startAuctionTimer();

    debugPrint('[Marketplace] Initialized');
  }

  void _startAuctionTimer() {
    _auctionTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkExpiredListings();
    });
  }

  /// 만료된 등록물 확인
  void _checkExpiredListings() {
    final now = DateTime.now();
    final expired = _listings.values.where((l) =>
        l.expiresAt != null && l.expiresAt!.isBefore(now)).toList();

    for (final listing in expired) {
      if (listing.isAuction && listing.currentBid != null) {
        // 입찰이 있으면 판매 완료
        _completeAuction(listing);
      } else {
        // 만료 처리
        _expireListing(listing.id);
      }
    }
  }

  /// 아이템 등록
  Future<MarketListing> listItem({
    required Item item,
    required int price,
    required int quantity,
    bool isAuction = false,
    int? buyNowPrice,
    Duration? duration,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final listingId = 'listing_${DateTime.now().millisecondsSinceEpoch}';
    final listing = MarketListing(
      id: listingId,
      sellerId: _currentUserId!,
      sellerName: 'Seller $_currentUserId',
      item: item,
      price: price,
      quantity: quantity,
      listedAt: DateTime.now(),
      expiresAt: duration != null
          ? DateTime.now().add(duration)
          : DateTime.now().add(const Duration(days: 7)),
      isAuction: isAuction,
      buyNowPrice: isAuction ? buyNowPrice : null,
    );

    _listings[listingId] = listing;
    _listingController.add(listing);

    await _saveListing(listing);

    debugPrint('[Marketplace] Item listed: $listingId');

    return listing;
  }

  /// 아이템 구매
  Future<Transaction> purchaseItem(String listingId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final listing = _listings[listingId];
    if (listing == null) {
      throw Exception('Listing not found');
    }

    if (listing.sellerId == _currentUserId) {
      throw Exception('Cannot buy your own item');
    }

    if (listing.isAuction) {
      throw Exception('Use bid for auction items');
    }

    // 수수료 계산 (5%)
    final fee = (listing.price * 0.05).toInt();
    final sellerReceived = listing.price - fee;

    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    final transaction = Transaction(
      id: transactionId,
      listingId: listingId,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      buyerId: _currentUserId!,
      buyerName: 'Buyer $_currentUserId',
      item: listing.item,
      quantity: listing.quantity,
      price: listing.price,
      fee: fee,
      type: TransactionType.purchase,
      timestamp: DateTime.now(),
    );

    // 거래 기록 추가
    _transactions.putIfAbsent(_currentUserId!, () => []).add(transaction);
    _transactions.putIfAbsent(listing.sellerId, () => []).add(transaction);

    // 등록물 제거
    _listings.remove(listingId);

    _transactionController.add(transaction);

    await _saveTransaction(transaction);

    debugPrint('[Marketplace] Item purchased: $listingId');

    return transaction;
  }

  /// 입찰
  Future<Bid> placeBid({
    required String listingId,
    required int amount,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final listing = _listings[listingId];
    if (listing == null) {
      throw Exception('Listing not found');
    }

    if (!listing.isAuction) {
      throw Exception('Not an auction');
    }

    if (listing.sellerId == _currentUserId) {
      throw Exception('Cannot bid on your own item');
    }

    // 최소 입찰가 확인
    final minBid = listing.currentBid ?? listing.price;
    if (amount <= minBid) {
      throw Exception('Bid must be higher than current bid');
    }

    final bidId = 'bid_${DateTime.now().millisecondsSinceEpoch}';
    final bid = Bid(
      id: bidId,
      listingId: listingId,
      bidderId: _currentUserId!,
      bidderName: 'Bidder $_currentUserId',
      amount: amount,
      timestamp: DateTime.now(),
    );

    _bids.putIfAbsent(listingId, () => []).add(bid);

    // 등록물 업데이트
    final updated = MarketListing(
      id: listing.id,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      item: listing.item,
      price: listing.price,
      quantity: listing.quantity,
      listedAt: listing.listedAt,
      expiresAt: listing.expiresAt,
      isAuction: listing.isAuction,
      buyNowPrice: listing.buyNowPrice,
      currentBid: amount,
      currentBidderId: _currentUserId,
    );

    _listings[listingId] = updated;
    _listingController.add(updated);
    _bidController.add(bid);

    await _saveBid(bid);

    debugPrint('[Marketplace] Bid placed: $amount');

    return bid;
  }

  /// 즉시 구매 (경매)
  Future<Transaction> buyNow(String listingId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final listing = _listings[listingId];
    if (listing == null) {
      throw Exception('Listing not found');
    }

    if (!listing.isAuction || listing.buyNowPrice == null) {
      throw Exception('Buy now not available');
    }

    final fee = (listing.buyNowPrice! * 0.05).toInt();
    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      listingId: listingId,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      buyerId: _currentUserId!,
      buyerName: 'Buyer $_currentUserId',
      item: listing.item,
      quantity: listing.quantity,
      price: listing.buyNowPrice!,
      fee: fee,
      type: TransactionType.purchase,
      timestamp: DateTime.now(),
    );

    _transactions.putIfAbsent(_currentUserId!, () => []).add(transaction);
    _transactions.putIfAbsent(listing.sellerId, () => []).add(transaction);

    _listings.remove(listingId);

    _transactionController.add(transaction);

    await _saveTransaction(transaction);

    debugPrint('[Marketplace] Buy now: $listingId');

    return transaction;
  }

  /// 등록 취소
  Future<void> cancelListing(String listingId) async {
    if (_currentUserId == null) return;

    final listing = _listings[listingId];
    if (listing == null) return;

    if (listing.sellerId != _currentUserId) {
      throw Exception('Not your listing');
    }

    if (listing.isAuction && listing.currentBid != null) {
      throw Exception('Cannot cancel auction with bids');
    }

    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      listingId: listingId,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      buyerId: listing.sellerId,
      buyerName: listing.sellerName,
      item: listing.item,
      quantity: listing.quantity,
      price: listing.price,
      fee: 0,
      type: TransactionType.cancel,
      timestamp: DateTime.now(),
    );

    _transactions.putIfAbsent(_currentUserId!, () => []).add(transaction);
    _listings.remove(listingId);

    _transactionController.add(transaction);

    debugPrint('[Marketplace] Listing cancelled: $listingId');
  }

  /// 경매 완료
  void _completeAuction(MarketListing listing) {
    if (listing.currentBidderId == null) return;

    final fee = (listing.currentBid! * 0.05).toInt();
    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      listingId: listing.id,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      buyerId: listing.currentBidderId!,
      buyerName: 'Winner ${listing.currentBidderId}',
      item: listing.item,
      quantity: listing.quantity,
      price: listing.currentBid!,
      fee: fee,
      type: TransactionType.sale,
      timestamp: DateTime.now(),
    );

    _transactions.putIfAbsent(listing.sellerId, () => []).add(transaction);
    _transactions.putIfAbsent(listing.currentBidderId!, () => []).add(transaction);

    _listings.remove(listing.id);

    _transactionController.add(transaction);

    debugPrint('[Marketplace] Auction completed: ${listing.id}');
  }

  /// 등록 만료
  void _expireListing(String listingId) {
    final listing = _listings[listingId];
    if (listing == null) return;

    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      listingId: listingId,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      buyerId: listing.sellerId,
      buyerName: listing.sellerName,
      item: listing.item,
      quantity: listing.quantity,
      price: listing.price,
      fee: 0,
      type: TransactionType.expire,
      timestamp: DateTime.now(),
    );

    _transactions.putIfAbsent(listing.sellerId, () => []).add(transaction);
    _listings.remove(listingId);

    _transactionController.add(transaction);

    debugPrint('[Marketplace] Listing expired: $listingId');
  }

  /// 검색
  List<MarketListing> searchListings({
    String? keyword,
    ItemGrade? grade,
    String? type,
    int? minPrice,
    int? maxPrice,
    bool? isAuction,
  }) {
    var listings = _listings.values.toList();

    if (keyword != null && keyword.isNotEmpty) {
      final lowerKeyword = keyword.toLowerCase();
      listings = listings.where((l) =>
          l.item.name.toLowerCase().contains(lowerKeyword)).toList();
    }

    if (grade != null) {
      listings = listings.where((l) => l.item.grade == grade).toList();
    }

    if (type != null) {
      listings = listings.where((l) => l.item.type == type).toList();
    }

    if (minPrice != null) {
      listings = listings.where((l) => l.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      listings = listings.where((l) => l.price <= maxPrice).toList();
    }

    if (isAuction != null) {
      listings = listings.where((l) => l.isAuction == isAuction).toList();
    }

    return listings..sort((a, b) => a.listedAt.compareTo(b.listedAt));
  }

  /// 즐겨찾기 추가
  Future<void> addToWatchlist(String listingId) async {
    if (_currentUserId == null) return;

    final watchlist = _watchlists[_currentUserId];
    if (watchlist != null) {
      if (!watchlist.listingIds.contains(listingId)) {
        final updated = Watchlist(
          userId: _currentUserId!,
          listingIds: [...watchlist.listingIds, listingId],
          updatedAt: DateTime.now(),
        );
        _watchlists[_currentUserId!] = updated;
      }
    } else {
      _watchlists[_currentUserId!] = Watchlist(
        userId: _currentUserId!,
        listingIds: [listingId],
        updatedAt: DateTime.now(),
      );
    }

    debugPrint('[Marketplace] Added to watchlist: $listingId');
  }

  /// 즐겨찾기 제거
  Future<void> removeFromWatchlist(String listingId) async {
    if (_currentUserId == null) return;

    final watchlist = _watchlists[_currentUserId];
    if (watchlist != null) {
      final updated = Watchlist(
        userId: _currentUserId!,
        listingIds: watchlist.listingIds.where((id) => id != listingId).toList(),
        updatedAt: DateTime.now(),
      );
      _watchlists[_currentUserId!] = updated;
    }

    debugPrint('[Marketplace] Removed from watchlist: $listingId');
  }

  /// 즐겨찾기 조회
  Watchlist? getWatchlist(String userId) {
    return _watchlists[userId];
  }

  /// 입찰 내역 조회
  List<Bid> getBids(String listingId) {
    return _bids[listingId] ?? [];
  }

  /// 거래 기록 조회
  List<Transaction> getTransactions(String userId) {
    return _transactions[userId] ?? [];
  }

  /// 시장 통계
  Map<String, dynamic> getMarketStatistics() {
    final allListings = _listings.values.toList();
    final soldItems = _transactions.values
        .expand((t) => t)
        .where((t) => t.type == TransactionType.purchase)
        .length;

    final gradeDistribution = <ItemGrade, int>{};
    for (final grade in ItemGrade.values) {
      gradeDistribution[grade] =
          allListings.where((l) => l.item.grade == grade).length;
    }

    return {
      'totalListings': allListings.length,
      'soldItems': soldItems,
      'activeAuctions': allListings.where((l) => l.isAuction && l.isActive).length,
      'gradeDistribution': gradeDistribution.map((k, v) => MapEntry(k.name, v)),
      'averagePrice': allListings.isNotEmpty
          ? allListings.map((l) => l.price).reduce((a, b) => a + b) / allListings.length
          : 0.0,
    };
  }

  Future<void> _saveListing(MarketListing listing) async {
    await _prefs?.setString(
      'marketplace_listing_${listing.id}',
      jsonEncode({
        'id': listing.id,
        'sellerId': listing.sellerId,
        'itemId': listing.item.id,
        'price': listing.price,
        'isAuction': listing.isAuction,
      }),
    );
  }

  Future<void> _saveTransaction(Transaction transaction) async {
    await _prefs?.setString(
      'marketplace_txn_${transaction.id}',
      jsonEncode({
        'id': transaction.id,
        'listingId': transaction.listingId,
        'sellerId': transaction.sellerId,
        'buyerId': transaction.buyerId,
        'price': transaction.price,
        'type': transaction.type.name,
      }),
    );
  }

  Future<void> _saveBid(Bid bid) async {
    await _prefs?.setString(
      'marketplace_bid_${bid.id}',
      jsonEncode({
        'id': bid.id,
        'listingId': bid.listingId,
        'bidderId': bid.bidderId,
        'amount': bid.amount,
      }),
    );
  }

  void dispose() {
    _listingController.close();
    _transactionController.close();
    _bidController.close();
    _auctionTimer?.cancel();
  }
}

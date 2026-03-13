import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 하우징 타입
enum HousingType {
  apartment,        // 아파트먼트
  house,            // 주택
  mansion,          // 저택
  castle,           // 성
  floating,         // 부유 하우징
  underground,      // 지하 하우징
}

/// 가구 타입
enum FurnitureType {
  chair,            // 의자
  table,            // 테이블
  bed,              // 침대
  storage,          // 수납장
  decoration,       // 장식품
  lighting,         // 조명
  rug,              // 러그
  wall,             // 벽지
  floor,            // 바닥
  electronic,       // 전자제품
  plant,            // 식물
  special,          // 특별 아이템
}

/// 가구 방향
enum FurnitureDirection {
  north,            // 북쪽
  east,             // 동쪽
  south,            // 남쪽
  west,             // 서쪽
}

/// 가구
class Furniture {
  final String id;
  final String name;
  final String description;
  final FurnitureType type;
  final int width;
  final int height;
  final String? imageUrl;
  final int price;
  final String? theme;
  final Map<String, dynamic>? properties;

  const Furniture({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.width,
    required this.height,
    this.imageUrl,
    required this.price,
    this.theme,
    this.properties,
  });
}

/// 배치된 가구
class PlacedFurniture {
  final String furnitureId;
  final Offset position;
  final FurnitureDirection direction;
  final DateTime? placedAt;

  const PlacedFurniture({
    required this.furnitureId,
    required this.position,
    required this.direction,
    this.placedAt,
  });
}

/// 방
class Room {
  final String id;
  final String name;
  final int width;
  final int height;
  final List<PlacedFurniture> furniture;
  final String? wallColor;
  final String? floorColor;
  final String? wallpaper;

  const Room({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    this.furniture = const [],
    this.wallColor,
    this.floorColor,
    this.wallpaper,
  });

  /// 가구 배치 가능 여부
  bool canPlaceFurniture(PlacedFurniture newFurniture) {
    final furniture = _getFurnitureById(newFurniture.furnitureId);
    if (furniture == null) return false;

    // 경계 체크
    final x = newFurniture.position.dx;
    final y = newFurniture.position.dy;

    if (x < 0 || y < 0) return false;
    if (x + furniture.width > width) return false;
    if (y + furniture.height > height) return false;

    // 충돌 체크
    for (final placed in furniture) {
      final existing = _getFurnitureById(placed.furnitureId);
      if (existing == null) continue;

      if (_checkCollision(newFurniture, existing!, placed)) {
        return false;
      }
    }

    return true;
  }

  bool _checkCollision(PlacedFurniture a, Furniture furnitureA, PlacedFurniture b) {
    final aRect = Rect.fromLTWH(
      a.position.dx,
      a.position.dy,
      furnitureA.width.toDouble(),
      furnitureA.height.toDouble(),
    );

    final bRect = Rect.fromLTWH(
      b.position.dx,
      b.position.dy,
      furnitureA.width.toDouble(), // b의 크기
      furnitureA.height.toDouble(),
    );

    return aRect.overlaps(bRect);
  }

  Furniture? _getFurnitureById(String id) {
    // 실제로는 가구 데이터베이스에서 조회
    return null;
  }
}

/// 하우징
class Housing {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final HousingType type;
  final List<Room> rooms;
  final int maxRooms;
  final List<String> visitors;
  final int housingScore;
  final DateTime createdAt;
  final DateTime? lastVisited;

  const Housing({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.type,
    required this.rooms,
    required this.maxRooms,
    this.visitors = const [],
    required this.housingScore,
    required this.createdAt,
    this.lastVisited,
  });

  /// 방 추가 가능 여부
  bool get canAddRoom => rooms.length < maxRooms;
}

/// 방문자 기록
class VisitorRecord {
  final String visitorId;
  final String visitorName;
  final DateTime visitTime;
  final int rating;
  final String? comment;

  const VisitorRecord({
    required this.visitorId,
    required this.visitorName,
    required this.visitTime,
    required this.rating,
    this.comment,
  });
}

/// 하우징 관리자
class HousingManager {
  static final HousingManager _instance = HousingManager._();
  static HousingManager get instance => _instance;

  HousingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Housing> _housings = {};
  final Map<String, Furniture> _furnitureCatalog = {};
  final Map<String, List<VisitorRecord>> _visitorRecords = {};

  final StreamController<Housing> _housingController =
      StreamController<Housing>.broadcast();
  final StreamController<VisitorRecord> _visitorController =
      StreamController<VisitorRecord>.broadcast();

  Stream<Housing> get onHousingUpdate => _housingController.stream;
  Stream<VisitorRecord> get onVisitorRecord => _visitorController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 가구 카탈로그 로드
    _loadFurnitureCatalog();

    // 하우징 로드
    await _loadHousings();

    debugPrint('[Housing] Initialized');
  }

  void _loadFurnitureCatalog() {
    // 의자
    _furnitureCatalog['chair_1'] = const Furniture(
      id: 'chair_1',
      name: '기본 의자',
      description: '편안한 의자',
      type: FurnitureType.chair,
      width: 1,
      height: 1,
      price: 100,
      theme: 'basic',
    );

    // 침대
    _furnitureCatalog['bed_1'] = const Furniture(
      id: 'bed_1',
      name: '싱글 침대',
      description: '편안한 싱글 침대',
      type: FurnitureType.bed,
      width: 2,
      height: 3,
      price: 500,
      theme: 'basic',
    );

    // 테이블
    _furnitureCatalog['table_1'] = const Furniture(
      id: 'table_1',
      name: '식탁',
      description: '식사용 테이블',
      type: FurnitureType.table,
      width: 2,
      height: 1,
      price: 300,
      theme: 'basic',
    );

    // 장식품
    _furnitureCatalog['decoration_1'] = const Furniture(
      id: 'decoration_1',
      name: '화병',
      description: '예쁜 꽃이 든 화병',
      type: FurnitureType.decoration,
      width: 1,
      height: 1,
      price: 200,
      theme: 'elegant',
    );
  }

  Future<void> _loadHousings() async {
    if (_currentUserId != null) {
      // 기본 하우징 생성
      final defaultHousing = Housing(
        id: 'housing_${_currentUserId}',
        ownerId: _currentUserId!,
        name: '나의 집',
        description: '편안한 주택',
        type: HousingType.house,
        rooms: [
          Room(
            id: 'room_living',
            name: '거실',
            width: 10,
            height: 10,
          ),
          Room(
            id: 'room_bedroom',
            name: '침실',
            width: 8,
            height: 8,
          ),
        ],
        maxRooms: 5,
        housingScore: 100,
        createdAt: DateTime.now(),
      );

      _housings[defaultHousing.id] = defaultHousing;
    }
  }

  /// 하우징 생성
  Future<Housing> createHousing({
    required String name,
    required String description,
    required HousingType type,
    List<Room>? rooms,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final housing = Housing(
      id: 'housing_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: _currentUserId!,
      name: name,
      description: description,
      type: type,
      rooms: rooms ?? [
        const Room(
          id: 'room_main',
          name: '메인 방',
          width: 10,
          height: 10,
        ),
      ],
      maxRooms: type == HousingType.castle ? 10 : 5,
      housingScore: 0,
      createdAt: DateTime.now(),
    );

    _housings[housing.id] = housing;
    _housingController.add(housing);

    await _saveHousing(housing);

    debugPrint('[Housing] Housing created: ${housing.name}');

    return housing;
  }

  /// 방 추가
  Future<void> addRoom({
    required String housingId,
    required String name,
    required int width,
    required int height,
  }) async {
    final housing = _housings[housingId];
    if (housing == null) return;

    if (!housing.canAddRoom) {
      throw Exception('Max rooms reached');
    }

    final room = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      width: width,
      height: height,
    );

    final updated = Housing(
      id: housing.id,
      ownerId: housing.ownerId,
      name: housing.name,
      description: housing.description,
      type: housing.type,
      rooms: [...housing.rooms, room],
      maxRooms: housing.maxRooms,
      visitors: housing.visitors,
      housingScore: _calculateHousingScore(housing),
      createdAt: housing.createdAt,
      lastVisited: housing.lastVisited,
    );

    _housings[housingId] = updated;
    _housingController.add(updated);

    await _saveHousing(updated);

    debugPrint('[Housing] Room added: $name');
  }

  /// 가구 배치
  Future<void> placeFurniture({
    required String housingId,
    required String roomId,
    required String furnitureId,
    required Offset position,
    FurnitureDirection direction = FurnitureDirection.north,
  }) async {
    final housing = _housings[housingId];
    if (housing == null) return;

    final roomIndex = housing.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;

    final room = housing.rooms[roomIndex];
    final furniture = _furnitureCatalog[furnitureId];

    if (furniture == null) {
      throw Exception('Furniture not found');
    }

    final placed = PlacedFurniture(
      furnitureId: furnitureId,
      position: position,
      direction: direction,
      placedAt: DateTime.now(),
    );

    if (!room.canPlaceFurniture(placed)) {
      throw Exception('Cannot place furniture here');
    }

    final updatedRoom = Room(
      id: room.id,
      name: room.name,
      width: room.width,
      height: room.height,
      furniture: [...room.furniture, placed],
      wallColor: room.wallColor,
      floorColor: room.floorColor,
      wallpaper: room.wallpaper,
    );

    final updatedRooms = List<Room>.from(housing.rooms);
    updatedRooms[roomIndex] = updatedRoom;

    final updated = Housing(
      id: housing.id,
      ownerId: housing.ownerId,
      name: housing.name,
      description: housing.description,
      type: housing.type,
      rooms: updatedRooms,
      maxRooms: housing.maxRooms,
      visitors: housing.visitors,
      housingScore: _calculateHousingScore(housing),
      createdAt: housing.createdAt,
      lastVisited: housing.lastVisited,
    );

    _housings[housingId] = updated;
    _housingController.add(updated);

    debugPrint('[Housing] Furniture placed: $furnitureId');
  }

  /// 가구 제거
  Future<void> removeFurniture({
    required String housingId,
    required String roomId,
    required Offset position,
  }) async {
    final housing = _housings[housingId];
    if (housing == null) return;

    final roomIndex = housing.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;

    final room = housing.rooms[roomIndex];

    final furnitureIndex = room.furniture.indexWhere((f) =>
        f.position == position);

    if (furnitureIndex == -1) return;

    final updatedRoom = Room(
      id: room.id,
      name: room.name,
      width: room.width,
      height: room.height,
      furniture: [...room.furniture]..removeAt(furnitureIndex),
      wallColor: room.wallColor,
      floorColor: room.floorColor,
      wallpaper: room.wallpaper,
    );

    final updatedRooms = List<Room>.from(housing.rooms);
    updatedRooms[roomIndex] = updatedRoom;

    final updated = Housing(
      id: housing.id,
      ownerId: housing.ownerId,
      name: housing.name,
      description: housing.description,
      type: housing.type,
      rooms: updatedRooms,
      maxRooms: housing.maxRooms,
      visitors: housing.visitors,
      housingScore: _calculateHousingScore(housing),
      createdAt: housing.createdAt,
      lastVisited: housing.lastVisited,
    );

    _housings[housingId] = updated;
    _housingController.add(updated);

    debugPrint('[Housing] Furniture removed');
  }

  /// 방문하다
  Future<void> visitHousing({
    required String housingId,
    required String visitorId,
    required String visitorName,
  }) async {
    final housing = _housings[housingId];
    if (housing == null) return;

    final updatedVisitors = [...housing.visitors, visitorId];

    final updated = Housing(
      id: housing.id,
      ownerId: housing.ownerId,
      name: housing.name,
      description: housing.description,
      type: housing.type,
      rooms: housing.rooms,
      maxRooms: housing.maxRooms,
      visitors: updatedVisitors,
      housingScore: housing.housingScore,
      createdAt: housing.createdAt,
      lastVisited: DateTime.now(),
    );

    _housings[housingId] = updated;
    _housingController.add(updated);

    debugPrint('[Housing] Visited: $housingId by $visitorName');
  }

  /// 방문자 평가
  Future<void> rateHousing({
    required String housingId,
    required String visitorId,
    required String visitorName,
    required int rating,
    String? comment,
  }) async {
    final record = VisitorRecord(
      visitorId: visitorId,
      visitorName: visitorName,
      visitTime: DateTime.now(),
      rating: rating,
      comment: comment,
    );

    _visitorRecords.putIfAbsent(housingId, () => []).add(record);
    _visitorController.add(record);

    debugPrint('[Housing] Rated: $housingId - $rating');
  }

  /// 하우징 점수 계산
  int _calculateHousingScore(Housing housing) {
    var score = 0;

    // 가구 수 점수
    for (final room in housing.rooms) {
      score += room.furniture.length * 10;
    }

    // 방 수 점수
    score += housing.rooms.length * 20;

    // 방문자 수 점수
    score += housing.visitors.length * 5;

    return score;
  }

  /// 하우징 조회
  Housing? getHousing(String housingId) {
    return _housings[housingId];
  }

  /// 사용자의 하우징 조회
  Housing? getUserHousing(String userId) {
    return _housings.values.firstWhere(
      (h) => h.ownerId == userId,
      orElse: () => _housings.values.first,
    );
  }

  /// 모든 하우징 조회
  List<Housing> getAllHousings() {
    return _housings.values.toList()
      ..sort((a, b) => b.housingScore.compareTo(a.housingScore));
  }

  /// 방문자 기록 조회
  List<VisitorRecord> getVisitorRecords(String housingId, {int limit = 10}) {
    return (_visitorRecords[housingId] ?? []).take(limit).toList()
      ..sort((a, b) => b.visitTime.compareTo(a.visitTime));
  }

  /// 가구 카탈로그 조회
  List<Furniture> getFurnitureCatalog({FurnitureType? type}) {
    var furniture = _furnitureCatalog.values.toList();

    if (type != null) {
      furniture = furniture.where((f) => f.type == type).toList();
    }

    return furniture;
  }

  Future<void> _saveHousing(Housing housing) async {
    await _prefs?.setString(
      'housing_${housing.id}',
      jsonEncode({
        'id': housing.id,
        'ownerId': housing.ownerId,
        'name': housing.name,
        'description': housing.description,
        'type': housing.type.name,
        'rooms': housing.rooms.map((room) => {
          'id': room.id,
          'name': room.name,
          'width': room.width,
          'height': room.height,
          'furniture': room.furniture.map((f) => {
            'furnitureId': f.furnitureId,
            'position': {'dx': f.position.dx, 'dy': f.position.dy},
            'direction': f.direction.name,
          }).toList(),
        }).toList(),
        'maxRooms': housing.maxRooms,
        'housingScore': housing.housingScore,
        'createdAt': housing.createdAt.toIso8601String(),
      }),
    );
  }

  void dispose() {
    _housingController.close();
    _visitorController.close();
  }
}

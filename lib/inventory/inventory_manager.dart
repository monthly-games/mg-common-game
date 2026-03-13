import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 아이템 타입
enum ItemType {
  weapon,         // 무기
  armor,          // 방어구
  accessory,      // 액세서리
  consumable,     // 소모품
  material,       // 재료
  quest,          // 퀘스트 아이템
  currency,       // 화폐
  special,        // 특수 아이템
}

/// 아이템 등급
enum ItemGrade {
  common,         // 일반 (회색)
  uncommon,       // 고급 (녹색)
  rare,           // 희귀 (파란색)
  epic,           // 에픽 (보라색)
  legendary,      // 전설 (주황색)
  mythic,         // 신화 (빨간색)
}

/// 아이템
class Item {
  final String itemId;
  final String name;
  final String description;
  final String icon;
  final ItemType type;
  final ItemGrade grade;
  final int maxStack;
  final bool isTradable;
  final bool isDropable;
  final int sellPrice;
  final Map<String, dynamic>? stats;
  final Map<String, dynamic>? metadata;

  const Item({
    required this.itemId,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.grade,
    required this.maxStack,
    required this.isTradable,
    required this.isDropable,
    required this.sellPrice,
    this.stats,
    this.metadata,
  });
}

/// 인벤토리 슬롯
class InventorySlot {
  final String slotId;
  final int index;
  final Item? item;
  final int quantity;

  const InventorySlot({
    required this.slotId,
    required this.index,
    this.item,
    required this.quantity,
  });

  /// 비어있는지
  bool get isEmpty => item == null;

  /// 가용 공간
  int get availableSpace => isEmpty ? maxStack : maxStack - quantity;

  /// 최대 중첩 수
  int get maxStack => item?.maxStack ?? 1;
}

/// 인벤토리
class Inventory {
  final String inventoryId;
  final String ownerId;
  final List<InventorySlot> slots;
  final int maxSlots;
  final String? type; // equipment, consumable, material, etc.

  const Inventory({
    required this.inventoryId,
    required this.ownerId,
    required this.slots,
    required this.maxSlots,
    this.type,
  });

  /// 사용 가능한 슬롯 수
  int get availableSlots => slots.where((s) => s.isEmpty).length;

  /// 사용 중인 슬롯 수
  int get usedSlots => maxSlots - availableSlots;
}

/// 아이템 강화 결과
class EnhancementResult {
  final bool success;
  final int newLevel;
  final Item? newItem;
  final String? message;

  const EnhancementResult({
    required this.success,
    required this.newLevel,
    this.newItem,
    this.message,
  });
}

/// 인벤토리 & 아이템 시스템 관리자
class InventoryManager {
  static final InventoryManager _instance = InventoryManager._();
  static InventoryManager get instance => _instance;

  InventoryManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Item> _items = {};
  final Map<String, Inventory> _inventories = {};

  final StreamController<Inventory> _inventoryController =
      StreamController<Inventory>.broadcast();
  final StreamController<Item> _itemController =
      StreamController<Item>.broadcast();

  Stream<Inventory> get onInventoryUpdate => _inventoryController.stream;
  Stream<Item> get onItemUpdate => _itemController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 아이템 로드
    await _loadItems();

    // 인벤토리 로드
    await _loadInventories();

    debugPrint('[Inventory] Initialized');
  }

  Future<void> _loadItems() async {
    // 샘플 아이템
    _items['weapon_sword_001'] = const Item(
      itemId: 'weapon_sword_001',
      name: '철검',
      description: '기본적인 철검',
      icon: 'sword_iron',
      type: ItemType.weapon,
      grade: ItemGrade.common,
      maxStack: 1,
      isTradable: true,
      isDropable: true,
      sellPrice: 10,
      stats: {'attack': 15},
    );

    _items['armor_chest_001'] = const Item(
      itemId: 'armor_chest_001',
      name: '가죽 갑옷',
      description: '가죽으로 만든 갑옷',
      icon: 'armor_leather',
      type: ItemType.armor,
      grade: ItemGrade.common,
      maxStack: 1,
      isTradable: true,
      isDropable: true,
      sellPrice: 15,
      stats: {'defense': 10},
    );

    _items['potion_hp_001'] = const Item(
      itemId: 'potion_hp_001',
      name: 'HP 포션',
      description: 'HP를 100 회복',
      icon: 'potion_hp',
      type: ItemType.consumable,
      grade: ItemGrade.common,
      maxStack: 99,
      isTradable: true,
      isDropable: true,
      sellPrice: 5,
    );

    _items['material_wood'] = const Item(
      itemId: 'material_wood',
      name: '나무',
      description: '제작 재료',
      icon: 'wood',
      type: ItemType.material,
      grade: ItemGrade.common,
      maxStack: 999,
      isTradable: true,
      isDropable: true,
      sellPrice: 1,
    );
  }

  Future<void> _loadInventories() async {
    // 기본 인벤토리 생성
    _inventories['default'] = Inventory(
      inventoryId: 'inv_${_currentUserId}_default',
      ownerId: _currentUserId ?? 'unknown',
      slots: _generateSlots(30),
      maxSlots: 30,
    );

    _inventories['equipment'] = Inventory(
      inventoryId: 'inv_${_currentUserId}_equipment',
      ownerId: _currentUserId ?? 'unknown',
      slots: _generateSlots(10),
      maxSlots: 10,
      type: 'equipment',
    );
  }

  List<InventorySlot> _generateSlots(int count) {
    return List.generate(count, (index) => InventorySlot(
      slotId: 'slot_$index',
      index: index,
      quantity: 0,
    ));
  }

  /// 아이템 조회
  Item? getItem(String itemId) {
    return _items[itemId];
  }

  /// 아이템 추가
  Future<bool> addItem({
    required String itemId,
    required int quantity,
    String? inventoryId,
  }) async {
    final item = _items[itemId];
    if (item == null) return false;

    final targetInventoryId = inventoryId ?? 'default';
    final inventory = _inventories[targetInventoryId];
    if (inventory == null) return false;

    // 기존 슬롯 확인 (중첩 가능)
    for (final slot in inventory.slots) {
      if (!slot.isEmpty && slot.item?.itemId == itemId) {
        final addAmount = slot.availableSpace < quantity
            ? slot.availableSpace
            : quantity;
        // 슬롯 업데이트
        return true;
      }
    }

    // 빈 슬롯 찾기
    for (final slot in inventory.slots) {
      if (slot.isEmpty) {
        // 슬롯에 아이템 추가
        return true;
      }
    }

    return false; // 인벤토리 가득 참
  }

  /// 아이템 제거
  Future<bool> removeItem({
    required String itemId,
    required int quantity,
    String? inventoryId,
  }) async {
    final targetInventoryId = inventoryId ?? 'default';
    final inventory = _inventories[targetInventoryId];
    if (inventory == null) return false;

    var remaining = quantity;

    for (final slot in inventory.slots) {
      if (slot.item?.itemId == itemId) {
        if (slot.quantity >= remaining) {
          // 충분함
          return true;
        } else {
          remaining -= slot.quantity;
        }
      }
    }

    return true;
  }

  /// 아이템 사용
  Future<bool> useItem(String itemId) async {
    final item = _items[itemId];
    if (item == null) return false;

    if (item.type == ItemType.consumable) {
      // 소모품 사용
      await removeItem(itemId: itemId, quantity: 1);
      return true;
    }

    return false;
  }

  /// 인벤토리 조회
  Inventory? getInventory(String inventoryId) {
    return _inventories[inventoryId];
  }

  /// 인벤토리 생성
  Inventory createInventory({
    required String ownerId,
    required int maxSlots,
    String? type,
  }) {
    final inventory = Inventory(
      inventoryId: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      slots: _generateSlots(maxSlots),
      maxSlots: maxSlots,
      type: type,
    );

    _inventories[inventory.inventoryId] = inventory;

    return inventory;
  }

  /// 아이템 강화
  Future<EnhancementResult> enhanceItem({
    required String itemId,
    required int currentLevel,
  }) async {
    final item = _items[itemId];
    if (item == null) {
      return const EnhancementResult(
        success: false,
        newLevel: 0,
        message: '아이템을 찾을 수 없습니다',
      );
    }

    // 강화 확률 계산
    final successRate = _calculateEnhanceSuccessRate(currentLevel);
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final success = random < successRate;

    if (success) {
      return EnhancementResult(
        success: true,
        newLevel: currentLevel + 1,
        message: '강화 성공! +${currentLevel + 1}',
      );
    } else {
      return const EnhancementResult(
        success: false,
        newLevel: 0,
        message: '강화 실패',
      );
    }
  }

  int _calculateEnhanceSuccessRate(int level) {
    // 레벨이 높을수록 성공률 감소
    switch (level) {
      case 0:
      case 1:
      case 2:
        return 100;
      case 3:
      case 4:
      case 5:
        return 90;
      case 6:
      case 7:
      case 8:
        return 80;
      case 9:
      case 10:
        return 70;
      default:
        return 50;
    }
  }

  void dispose() {
    _inventoryController.close();
    _itemController.close();
  }
}

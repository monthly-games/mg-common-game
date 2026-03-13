import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 아바타 파트
enum AvatarPart {
  hair,
  face,
  eyes,
  mouth,
  accessory,
  outfit,
  background,
}

/// 아바타 옵션
class AvatarOption {
  final String id;
  final String name;
  final String? iconUrl;
  final String? imageUrl;
  final bool isUnlocked;
  final int? cost;

  const AvatarOption({
    required this.id,
    required this.name,
    this.iconUrl,
    this.imageUrl,
    this.isUnlocked = true,
    this.cost,
  });
}

/// 아바타 설정
class AvatarSettings {
  final Map<AvatarPart, String> selectedParts;
  final String? backgroundColor;

  const AvatarSettings({
    required this.selectedParts,
    this.backgroundColor,
  });

  Map<String, dynamic> toJson() => {
        'parts': selectedParts.map((k, v) => k.name: v),
        'backgroundColor': backgroundColor,
    };
}

/// 캐릭터 커스터마이징
class CharacterCustomization {
  final String id;
  final String? skinColor;
  final String? hairColor;
  final String? eyeColor;
  final String? outfitId;
  final String? accessoryId;
  final Map<String, dynamic>? stats;

  const CharacterCustomization({
    required this.id,
    this.skinColor,
    this.hairColor,
    this.eyeColor,
    this.outfitId,
    this.accessoryId,
    this.stats,
  });

  /// 복사본 생성
  CharacterCustomization copyWith({
    String? id,
    String? skinColor,
    String? hairColor,
    String? eyeColor,
    String? outfitId,
    String? accessoryId,
    Map<String, dynamic>? stats,
  }) {
    return CharacterCustomization(
      id: id ?? this.id,
      skinColor: skinColor ?? this.skinColor,
      hairColor: hairColor ?? this.hairColor,
      eyeColor: eyeColor ?? this.eyeColor,
      outfitId: outfitId ?? this.outfitId,
      accessoryId: accessoryId ?? this.accessoryId,
      stats: stats ?? this.stats,
    );
  }
}

/// 커스템 스킨
class CustomSkin {
  final String id;
  final String name;
  final String description;
  final String type; // character, weapon, vehicle, etc.
  final String? previewUrl;
  final bool isOwned;
  final int? price;
  final String? rarity;
  final DateTime? availableUntil;

  const CustomSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.previewUrl,
    this.isOwned = false,
    this.price,
    this.rarity,
    this.availableUntil,
  });
}

/// UI 테마
class UITheme {
  final String id;
  final String name;
  final String description;
  final MaterialColor primaryColor;
  final MaterialColor secondaryColor;
  final ThemeData themeData;
  final bool isUnlocked;

  const UITheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.themeData,
    this.isUnlocked = true,
  });
}

/// 커스터마이징 관리자
class CustomizationManager {
  static final CustomizationManager _instance = CustomizationManager._();
  static CustomizationManager get instance => _instance;

  CustomizationManager._();

  SharedPreferences? _prefs;
  String? _userId;

  final Map<String, AvatarOption> _avatarOptions = {};
  final Map<String, CustomSkin> _skins = {};
  final Map<String, UITheme> _themes = {};
  CharacterCustomization? _currentCustomization;

  final StreamController<CharacterCustomization> _customizationController =
      StreamController<CharacterCustomization>.broadcast();

  Stream<CharacterCustomization> get onCustomizationChange =>
      _customizationController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _userId = _prefs?.getString('user_id');

    // 아바타 옵션 로드
    _loadAvatarOptions();

    // 스킨 로드
    _loadSkins();

    // 테마 로드
    _loadThemes();

    // 사용자 설정 로드
    await _loadUserCustomization();

    debugPrint('[Customization] Initialized');
  }

  void _loadAvatarOptions() {
    // 머리카락
    _avatarOptions['hair_1'] = const AvatarOption(
      id: 'hair_1',
      name: '숏은 머리',
      isUnlocked: true,
    );
    _avatarOptions['hair_2'] = const AvatarOption(
      id: 'hair_2',
      name: '긴 머리',
      isUnlocked: true,
    );
    _avatarOptions['hair_3'] = const AvatarOption(
      id: 'hair_3',
      name: '웨이브',
      isUnlocked: false,
      cost: 500,
    );

    // 얼굴
    _avatarOptions['face_1'] = const AvatarOption(
      id: 'face_1',
      name: '기본 얼굴',
      isUnlocked: true,
    );

    // 눈
    _avatarOptions['eyes_1'] = const AvatarOption(
      id: 'eyes_1',
      name: '기본 눈',
      isUnlocked: true,
    );
    _avatarOptions['eyes_2'] = const AvatarOption(
      id: 'eyes_2',
      name: '큰 눈',
      isUnlocked: false,
      cost: 300,
    );

    // 입
    _avatarOptions['mouth_1'] = const AvatarOption(
      id: 'mouth_1',
      name: '미소',
      isUnlocked: true,
    );

    // 옷
    _avatarOptions['outfit_1'] = const AvatarOption(
      id: 'outfit_1',
      name: '기본 옷',
      isUnlocked: true,
    );
    _avatarOptions['outfit_2'] = const AvatarOption(
      id: 'outfit_2',
      name: '영웅의 갑옷',
      isUnlocked: false,
      cost: 1000,
    );
  }

  void _loadSkins() {
    _skins.addAll({
      'skin_legendary_1': const CustomSkin(
        id: 'skin_legendary_1',
        name: '전설의 용사',
        description: '고대의 전설을 따라 만든 갑옷',
        type: 'character',
        rarity: 'legendary',
        price: 5000,
        isOwned: false,
      ),
      'skin_epic_1': const CustomSkin(
        id: 'skin_epic_1',
        name: '불꽃의 마법사',
        description: '불꽃 마법으로 무장한 마법사',
        type: 'character',
        rarity: 'epic',
        price: 3000,
        isOwned: false,
      ),
      'skin_rare_1': const CustomSkin(
        id: 'skin_rare_1',
        name: '숲의 사냥꾼',
        description: '숲속에서 온 사냥꾼',
        type: 'character',
        rarity: 'rare',
        price: 1000,
        isOwned: false,
      ),
    });
  }

  void _loadThemes() {
    _themes.addAll({
      'dark': UITheme(
        id: 'dark',
        name: '다크 모드',
        description: '어두운 테마',
        primaryColor: Colors.blue,
        secondaryColor: Colors.amber,
        themeData: ThemeData.dark(),
        isUnlocked: true,
      ),
      'light': UITheme(
        id: 'light',
        name: '라이트 모드',
        description: '밝은 테마',
        primaryColor: Colors.blue,
        secondaryColor: Colors.orange,
        themeData: ThemeData.light(),
        isUnlocked: true,
      ),
      'nature': UITheme(
        id: 'nature',
        name: '자연',
        description: '자연의 색감',
        primaryColor: Colors.green,
        secondaryColor: Colors.lightGreen,
        themeData: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        isUnlocked: false,
      ),
    });
  }

  Future<void> _loadUserCustomization() async {
    final customizationJson = _prefs?.getString('customization');

    if (customizationJson != null) {
      // JSON 파싱 (실제 구현)
      _currentCustomization = CharacterCustomization(
        id: 'custom_1',
        skinColor: '#FFE0BD',
        hairColor: '#4A3728',
        eyeColor: '#5D4037',
      );
    } else {
      // 기본 커스터마이징
      _currentCustomization = const CharacterCustomization(
        id: 'default',
        skinColor: '#FFE0BD',
        hairColor: '#4A3728',
        eyeColor: '#5D4037',
      );
    }
  }

  /// 아바타 옵션 목록 조회
  List<AvatarOption> getAvatarOptions(AvatarPart part) {
    return _avatarOptions.values
        .where((option) => option.id.startsWith('${part.name}_'))
        .toList();
  }

  /// 아바타 옵션 선택
  Future<void> selectAvatarOption({
    required AvatarPart part,
    required String optionId,
  }) async {
    final option = _avatarOptions[optionId];
    if (option == null) return;

    if (!option.isUnlocked) {
      debugPrint('[Customization] Option not unlocked: $optionId');
      return;
    }

    // 사용자 설정 업데이트
    await _prefs?.setString('avatar_${part.name}', optionId);

    debugPrint('[Customization] Selected: ${part.name} = $optionId');
  }

  /// 캐릭터 커스터마이징 업데이트
  Future<void> updateCustomization(CharacterCustomization customization) async {
    _currentCustomization = customization;

    // 저장
    await _prefs?.setString('customization', '{}');

    _customizationController.add(customization);

    debugPrint('[Customization] Updated customization');
  }

  /// 스킨 구매
  Future<bool> purchaseSkin(String skinId) async {
    final skin = _skins[skinId];
    if (skin == null) return false;

    if (skin.price == null) return false;

    // 결제 처리 (실제로는 InAppPurchaseManager 사용)
    await Future.delayed(const Duration(milliseconds: 500));

    // 소유한 스킨으로 업데이트
    final ownedSkin = CustomSkin(
      id: skin.id,
      name: skin.name,
      description: skin.description,
      type: skin.type,
      previewUrl: skin.previewUrl,
      isOwned: true,
      price: skin.price,
      rarity: skin.rarity,
      availableUntil: skin.availableUntil,
    );

    _skins[skinId] = ownedSkin;

    // 저장
    await _prefs?.setBool('owned_skin_$skinId', true);

    debugPrint('[Customization] Purchased skin: $skinId');

    return true;
  }

  /// 스킨 장착
  Future<void> equipSkin(String skinId) async {
    final skin = _skins[skinId];
    if (skin == null || !skin.isOwned) return;

    await _prefs?.setString('equipped_skin_${skin.type}', skinId);

    debugPrint('[Customization] Equipped skin: $skinId');
  }

  /// 장착된 스킨 조회
  Future<String?> getEquippedSkin(String type) async {
    return _prefs?.getString('equipped_skin_$type');
  }

  /// 소유한 스킨 목록
  List<CustomSkin> getOwnedSkins({String? type}) {
    var skins = _skins.values.where((s) => s.isOwned).toList();

    if (type != null) {
      skins = skins.where((s) => s.type == type).toList();
    }

    return skins;
  }

  /// 테마 적용
  Future<void> applyTheme(String themeId) async {
    final theme = _themes[themeId];
    if (theme == null || !theme.isUnlocked) return;

    await _prefs?.setString('ui_theme', themeId);

    debugPrint('[Customization] Applied theme: $themeId');
  }

  /// 현재 테마 조회
  Future<UITheme?> getCurrentTheme() async {
    final themeId = await _prefs?.getString('ui_theme') ?? 'light';
    return _themes[themeId];
  }

  /// 프리셋 생성
  Future<void> createPreset({
    required String name,
    required CharacterCustomization customization,
  }) async {
    final presetId = 'preset_${DateTime.now().millisecondsSinceEpoch}';

    // 프리셋 저장
    await _prefs?.setString('preset_$presetId', '{}');

    debugPrint('[Customization] Created preset: $presetId');
  }

  /// 프리셋 목록 조회
  Future<List<Map<String, dynamic>>> getPresets() async {
    // 실제 구현에서는 저장된 프리셋 로드
    return [];
  }

  /// 커스텀 색상 생성
  static Color parseColor(String hexColor) {
    final colorValue = int.parse(hexColor.replaceFirst('#', '0xFF'));
    return Color(colorValue);
  }

  void dispose() {
    _customizationController.close();
  }
}

/// 아바타 빌더
class AvatarBuilder {
  final Map<AvatarPart, String> _selectedParts = {};

  /// 파트 선택
  void selectPart(AvatarPart part, String optionId) {
    _selectedParts[part] = optionId;
  }

  /// 아바타 설정 생성
  AvatarSettings build() {
    return AvatarSettings(
      selectedParts: Map.from(_selectedParts),
      backgroundColor: '#FFFFFF',
    );
  }

  /// 미리보기 생성
  Widget preview(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 100),
      ),
    );
  }
}

/// 커스텀 아이템 제작기
class ItemCreator {
  final String name;
  final Map<String, dynamic> properties;

  const ItemCreator({
    required this.name,
    required this.properties,
  });

  /// 아이템 생성
  Map<String, dynamic> create() {
    return {
      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'properties': properties,
      'isCustom': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// 아이템 내보내기
  String export() {
    return jsonEncode({
      'name': name,
      'properties': properties,
    });
  }
}

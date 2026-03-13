import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 코드 타입
enum PromoCodeType {
  oneTime,        // 일회용
  multiUse,       // 다회용
  limited,        // 제한 횟수
  unlimited,      // 무제한
}

/// 보상 타입
enum PromoRewardType {
  currency,       // 통화
  item,           // 아이템
  boost,          // 부스트
  gacha,          // 가채 티켓
  custom,         // 커스텀
}

/// 코드 상태
enum PromoCodeStatus {
  active,         // 활성
  inactive,       // 비활성
  expired,        // 만료
  depleted,       // 소진
  scheduled,      // 예정
}

/// 프로모션 보상
class PromoReward {
  final PromoRewardType type;
  final String id;
  final String name;
  final int? amount;
  final String? itemId;
  final int? itemQuantity;
  final int? duration; // 부스트 지속 시간 (초)
  final Map<String, dynamic>? metadata;

  const PromoReward({
    required this.type,
    required this.id,
    required this.name,
    this.amount,
    this.itemId,
    this.itemQuantity,
    this.duration,
    this.metadata,
  });
}

/// 프로모션 코드
class PromoCode {
  final String code;
  final String name;
  final String description;
  final PromoCodeType type;
  final PromoCodeStatus status;
  final List<PromoReward> rewards;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxUses; // 최대 사용 가능 횟수
  final int currentUses; // 현재 사용 횟수
  final int? maxUsesPerUser; // 유저별 최대 사용 횟수
  final Set<String> requiredLevel; // 필요 레벨 등 조건
  final String? campaignId; // 캠페인 ID
  final bool isNewUserOnly; // 신규 유저만
  final String? icon;

  const PromoCode({
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.rewards,
    this.startDate,
    this.endDate,
    this.maxUses,
    required this.currentUses,
    this.maxUsesPerUser,
    this.requiredLevel = const {},
    this.campaignId,
    this.isNewUserOnly = false,
    this.icon,
  });

  /// 활성 상태
  bool get isActive {
    if (status != PromoCodeStatus.active) return false;

    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (maxUses != null && currentUses >= maxUses!) return false;

    return true;
  }

  /// 남은 사용 가능 횟수
  int get remainingUses {
    if (maxUses == null) return -1; // 무제한
    return (maxUses! - currentUses).clamp(0, maxUses!);
  }

  /// 만료까지 남은 시간
  Duration? get timeUntilExpiry {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// 사용 가능 여부
  bool canUse({
    required bool isNewUser,
    required int userUses,
  }) {
    if (!isActive) return false;
    if (isNewUserOnly && !isNewUser) return false;
    if (maxUsesPerUser != null && userUses >= maxUsesPerUser!) return false;

    return true;
  }
}

/// 코드 사용 기록
class CodeRedemption {
  final String code;
  final DateTime redeemedAt;
  final List<PromoReward> rewards;
  final String? deviceId;
  final String? ip;

  const CodeRedemption({
    required this.code,
    required this.redeemedAt,
    required this.rewards,
    this.deviceId,
    this.ip,
  });
}

/// 플레이어 코드 데이터
class PlayerCodeData {
  final String userId;
  final Map<String, int> usedCodes; // code -> usage count
  final List<CodeRedemption> history;
  final int totalRedeemed;
  final int totalRewardsValue;

  const PlayerCodeData({
    required this.userId,
    required this.usedCodes,
    required this.history,
    required this.totalRedeemed,
    required this.totalRewardsValue,
  });

  /// 코드 사용 횟수
  int getCodeUsage(String code) {
    return usedCodes[code] ?? 0;
  }

  /// 이미 사용한 코드인지
  bool hasUsed(String code) {
    return usedCodes.containsKey(code);
  }
}

/// 프로모션 코드 관리자
class PromoCodeManager {
  static final PromoCodeManager _instance = PromoCodeManager._();
  static PromoCodeManager get instance => _instance;

  PromoCodeManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<PromoCode> _codes = [];
  PlayerCodeData? _playerData;

  final StreamController<CodeRedemption> _redemptionController =
      StreamController<CodeRedemption>.broadcast();
  final StreamController<List<PromoCode>> _codesController =
      StreamController<List<PromoCode>>.broadcast();

  Stream<CodeRedemption> get onCodeRedeem => _redemptionController.stream;
  Stream<List<PromoCode>> get onCodesUpdate => _codesController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 코드 로드
    _loadCodes();

    // 플레이어 데이터 로드
    if (_currentUserId != null) {
      await _loadPlayerData(_currentUserId!);
    }

    debugPrint('[PromoCode] Initialized');
  }

  void _loadCodes() {
    _codes.clear();

    // 환영 코드 (신규 유저)
    _codes.add(PromoCode(
      code: 'WELCOME2024',
      name: '환영 보상',
      description: '새로운 모험을 시작하는 플레이어를 위한 선물',
      type: PromoCodeType.oneTime,
      status: PromoCodeStatus.active,
      rewards: const [
        PromoReward(
          type: PromoRewardType.currency,
          id: 'gold',
          name: '골드',
          amount: 10000,
        ),
        PromoReward(
          type: PromoRewardType.currency,
          id: 'gems',
          name: '젬',
          amount: 100,
        ),
        PromoReward(
          type: PromoRewardType.boost,
          id: 'exp_boost',
          name: '경험치 부스트',
          duration: 86400, // 24시간
        ),
      ],
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 335)),
      maxUses: null,
      currentUses: 1234,
      maxUsesPerUser: 1,
      isNewUserOnly: true,
      icon: 'assets/promo/welcome.png',
    ));

    // 이벤트 코드 (다회용)
    _codes.add(PromoCode(
      code: 'EVENT2024',
      name: '2024 이벤트',
      description: '특별 이벤트 보상',
      type: PromoCodeType.multiUse,
      status: PromoCodeStatus.active,
      rewards: const [
        PromoReward(
          type: PromoRewardType.item,
          id: 'event_box',
          name: '이벤트 상자',
          itemQuantity: 1,
        ),
      ],
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 23)),
      maxUses: 100000,
      currentUses: 45000,
      maxUsesPerUser: 3,
      campaignId: 'event_2024',
    ));

    // 추첨 코드 (제한)
    _codes.add(PromoCode(
      code: 'LUCKY777',
      name: '행운의 추첨',
      description: '특별 보상 추첨',
      type: PromoCodeType.limited,
      status: PromoCodeStatus.active,
      rewards: const [
        PromoReward(
          type: PromoRewardType.gacha,
          id: 'gacha_ticket',
          name: '가채 티켓',
          amount: 10,
        ),
      ],
      maxUses: 50000,
      currentUses: 12000,
      maxUsesPerUser: 1,
    ));

    // 시즌 코드 (일회용)
    _codes.add(PromoCode(
      code: 'SEASON1START',
      name: '시즌 1 시작',
      description: '첫 시즌을 기념하는 보상',
      type: PromoCodeType.oneTime,
      status: PromoCodeStatus.active,
      rewards: const [
        PromoReward(
          type: PromoRewardType.currency,
          id: 'season_currency',
          name: '시즌 통화',
          amount: 1000,
        ),
        PromoReward(
          type: PromoRewardType.item,
          id: 'season_chest',
          name: '시즌 상자',
          itemQuantity: 3,
        ),
      ],
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 29)),
      maxUses: 100000,
      currentUses: 7800,
      maxUsesPerUser: 1,
      campaignId: 'season_1',
    ));

    // 배우자 코드 (소셜)
    _codes.add(PromoCode(
      code: 'FRIENDGIFT',
      name: '친구의 선물',
      description: '친구 초대 특별 보상',
      type: PromoCodeType.multiUse,
      status: PromoCodeStatus.active,
      rewards: const [
        PromoReward(
          type: PromoRewardType.currency,
          id: 'gold',
          name: '골드',
          amount: 5000,
        ),
      ],
      maxUses: null,
      currentUses: 5600,
      maxUsesPerUser: 10,
      campaignId: 'referral',
    ));
  }

  Future<void> _loadPlayerData(String userId) async {
    final json = _prefs?.getString('promo_codes_$userId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[PromoCode] Error loading data: $e');
      }
    }

    _playerData = PlayerCodeData(
      userId: userId,
      usedCodes: {},
      history: [],
      totalRedeemed: 0,
      totalRewardsValue: 0,
    );
  }

  /// 코드 입력
  Future<CodeRedemption?> redeemCode(String inputCode) async {
    if (_currentUserId == null) return null;
    if (_playerData == null) return null;

    final code = inputCode.toUpperCase().trim();
    if (code.isEmpty) return null;

    // 코드 찾기
    final promoCode = _codes.cast<PromoCode?>.firstWhere(
      (c) => c?.code == code,
      orElse: () => null,
    );

    if (promoCode == null) {
      debugPrint('[PromoCode] Code not found: $code');
      return null;
    }

    // 활성 상태 확인
    if (!promoCode.isActive) {
      debugPrint('[PromoCode] Code not active: $code');
      return null;
    }

    // 사용 가능 여부 확인
    final userUsage = _playerData!.getCodeUsage(code);
    final isNewUser = _playerData!.totalRedeemed == 0;

    if (!promoCode.canUse(
      isNewUser: isNewUser,
      userUses: userUsage,
    )) {
      debugPrint('[PromoCode] Cannot use code: $code');
      return null;
    }

    // 보상 지급
    await _grantRewards(promoCode.rewards);

    // 사용 기록 생성
    final redemption = CodeRedemption(
      code: code,
      redeemedAt: DateTime.now(),
      rewards: promoCode.rewards,
      deviceId: 'device_${DateTime.now().millisecondsSinceEpoch}',
    );

    // 데이터 업데이트
    final usedCodes = Map<String, int>.from(_playerData!.usedCodes);
    usedCodes[code] = (usedCodes[code] ?? 0) + 1;

    final updated = PlayerCodeData(
      userId: _playerData!.userId,
      usedCodes: usedCodes,
      history: [..._playerData!.history, redemption],
      totalRedeemed: _playerData!.totalRedeemed + 1,
      totalRewardsValue: _playerData!.totalRewardsValue + _calculateRewardValue(promoCode.rewards),
    );

    _playerData = updated;

    _redemptionController.add(redemption);

    await _savePlayerData();

    debugPrint('[PromoCode] Redeemed: $code (${promoCode.rewards.length} rewards)');

    return redemption;
  }

  Future<void> _grantRewards(List<PromoReward> rewards) async {
    // 실제 보상 지급
    for (final reward in rewards) {
      debugPrint('[PromoCode] Granted: ${reward.name} x${reward.amount ?? reward.itemQuantity ?? 1}');
    }
  }

  int _calculateRewardValue(List<PromoReward> rewards) {
    return rewards.fold<int>(0, (sum, r) => sum + (r.amount ?? r.itemQuantity ?? 0));
  }

  /// 코드 정보 조회
  PromoCode? getCode(String code) {
    return _codes.cast<PromoCode?>.firstWhere(
      (c) => c?.code == code.toUpperCase(),
      orElse: () => null,
    );
  }

  /// 활성 코드 목록
  List<PromoCode> getActiveCodes() {
    return _codes.where((c) => c.isActive).toList()
      ..sort((a, b) => a.endDate?.compareTo(b.endDate ?? DateTime.now()) ?? 0);
  }

  /// 사용 가능한 코드만
  List<PromoCode> getRedeemableCodes({required bool isNewUser}) {
    return _codes.where((c) {
      if (!c.isActive) return false;
      if (_playerData == null) return true;

      final userUsage = _playerData!.getCodeUsage(c.code);
      return c.canUse(
        isNewUser: isNewUser,
        userUses: userUsage,
      );
    }).toList();
  }

  /// 사용 기록
  List<CodeRedemption> getRedemptionHistory({int limit = 20}) {
    if (_playerData == null) return [];
    return _playerData!.history.take(limit).toList()
      ..sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
  }

  /// 플레이어 데이터
  PlayerCodeData? getPlayerData() {
    return _playerData;
  }

  /// 코드 검증
  bool validateCode(String code, {required bool isNewUser}) {
    final promoCode = getCode(code);
    if (promoCode == null) return false;
    if (!promoCode.isActive) return false;

    if (_playerData == null) return true;

    final userUsage = _playerData!.getCodeUsage(code);
    return promoCode.canUse(
      isNewUser: isNewUser,
      userUses: userUsage,
    );
  }

  /// 대량 코드 생성 (관리자용)
  List<String> generateBulkCodes({
    required int count,
    required String prefix,
    PromoCodeType type = PromoCodeType.oneTime,
    List<PromoReward>? rewards,
  }) {
    final codes = <String>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < count; i++) {
      final suffix = (now + i).toRadixString(36).toUpperCase();
      final code = '${prefix}_$suffix';

      if (rewards != null) {
        _codes.add(PromoCode(
          code: code,
          name: '생성된 코드 $i',
          description: '자동 생성된 코드',
          type: type,
          status: PromoCodeStatus.active,
          rewards: rewards,
          maxUses: type == PromoCodeType.oneTime ? 1 : null,
          currentUses: 0,
          maxUsesPerUser: 1,
        ));
      }

      codes.add(code);
    }

    debugPrint('[PromoCode] Generated $count codes');

    return codes;
  }

  /// 코드 활성화/비활성화 (관리자용)
  Future<bool> setCodeStatus(String code, PromoCodeStatus status) async {
    final index = _codes.indexWhere((c) => c.code == code);
    if (index == -1) return false;

    // 실제로는 서버 업데이트
    debugPrint('[PromoCode] Status updated: $code -> ${status.name}');

    return true;
  }

  /// 사용 통계 (관리자용)
  Map<String, dynamic> getCodeStatistics(String code) {
    final promoCode = getCode(code);
    if (promoCode == null) return {};

    return {
      'code': promoCode.code,
      'name': promoCode.name,
      'totalUses': promoCode.currentUses,
      'remainingUses': promoCode.remainingUses,
      'isActive': promoCode.isActive,
      'type': promoCode.type.name,
      'rewardsCount': promoCode.rewards.length,
      'campaignId': promoCode.campaignId,
    };
  }

  Future<void> _savePlayerData() async {
    if (_currentUserId == null || _playerData == null) return;

    final data = {
      'usedCodes': _playerData!.usedCodes,
      'totalRedeemed': _playerData!.totalRedeemed,
      'totalRewardsValue': _playerData!.totalRewardsValue,
    };

    await _prefs?.setString(
      'promo_codes_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _redemptionController.close();
    _codesController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 지역
enum Region {
  global,         // 글로벌
  na,             // 북미
  eu,             // 유럽
  kr,             // 한국
  jp,             // 일본
  cn,             // 중국
  sea,            // 동남아
  latam,          // 라틴 아메리카
  mena,           // 중동/북아프리카
  in,             // 인도
  ru,             // 러시아/CIS
  oc,             // 오세아니아
}

/// 콘텐츠 카테고리
enum ContentCategory {
  gameplay,       // 게임플레이
  story,          // 스토리
  visual,         // 비주얼
  audio,          // 오디오
  items,          // 아이템
  characters,     // 캐릭터
  events,         // 이벤트
  promotions,     // 프로모션
  social,         // 소셜
  payment,        // 결제
}

/// 콘텐츠 등급
enum ContentRating {
  everyone,       // 전체 이용가
  teen,           // 12세 이용가
  mature,         // 15세 이용가
  adultsOnly,     // 18세 이용가
  regional,       // 지역별 등급
}

/// 지역 제약
enum RegionalRestriction {
  gambling,       // 도박
  violence,       // 폭력성
  sexual,         // 선정성
  language,       // 언어
  religion,       // 종교
  politics,       // 정치
  drugs,          // 약물
  custom,         // 기타
}

/// 지역별 콘텐츠 설정
class RegionalContentConfig {
  final Region region;
  final String countryCode; // ISO 3166-1 alpha-2
  final ContentRating defaultRating;
  final List<ContentCategory> restrictedCategories;
  final List<RegionalRestriction> restrictions;
  final Map<String, dynamic> customSettings;
  final String? serverRegion;
  final String? currencyCode;
  final List<String> prohibitedFeatures;
  final bool requiresCompliance;

  const RegionalContentConfig({
    required this.region,
    required this.countryCode,
    required this.defaultRating,
    this.restrictedCategories = const [],
    this.restrictions = const [],
    this.customSettings = const {},
    this.serverRegion,
    this.currencyCode,
    this.prohibitedFeatures = const [],
    this.requiresCompliance = false,
  });
}

/// 콘텐츠 항목
class ContentItem {
  final String contentId;
  final String name;
  final ContentCategory category;
  final ContentRating rating;
  final List<Region> availableRegions;
  final List<Region>? excludedRegions;
  final Map<RegionalRestriction, int> restrictionLevels; // 0-10
  final Map<String, dynamic>? metadata;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? localizedId;

  const ContentItem({
    required this.contentId,
    required this.name,
    required this.category,
    required this.rating,
    required this.availableRegions,
    this.excludedRegions,
    this.restrictionLevels = const {},
    this.metadata,
    this.availableFrom,
    this.availableUntil,
    this.localizedId,
  });

  /// 현재 지역에서 사용 가능한지
  bool isAvailableIn(Region region) {
    if (!availableRegions.contains(region) &&
        !availableRegions.contains(Region.global)) {
      return false;
    }

    if (excludedRegions != null && excludedRegions!.contains(region)) {
      return false;
    }

    // 기간 체크
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return false;
    }
    if (availableUntil != null && now.isAfter(availableUntil!)) {
      return false;
    }

    return true;
  }
}

/// 지역별 이벤트
class RegionalEvent {
  final String eventId;
  final String name;
  final String description;
  final Region region;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> rewards;
  final List<String> requirements;
  final Map<String, dynamic>? customRules;

  const RegionalEvent({
    required this.eventId,
    required this.name,
    required this.description,
    required this.region,
    required this.startTime,
    required this.endTime,
    required this.rewards,
    this.requirements = const [],
    this.customRules,
  });

  /// 활성 상태
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}

/// 지역 통계
class RegionalStatistics {
  final Region region;
  final int activeUsers;
  final int totalUsers;
  final double avgSessionTime;
  final double revenue;
  final int contentViews;
  final Map<String, int> popularContent;
  final DateTime periodStart;
  final DateTime periodEnd;

  const RegionalStatistics({
    required this.region,
    required this.activeUsers,
    required this.totalUsers,
    required this.avgSessionTime,
    required this.revenue,
    required this.contentViews,
    required this.popularContent,
    required this.periodStart,
    required this.periodEnd,
  });
}

/// 규정 준수 상태
enum ComplianceStatus {
  compliant,      // 준수
  pending,        // 대기 중
  nonCompliant,   // 미준수
  exempt,         // 면제
}

/// 규정 준수 리포트
class ComplianceReport {
  final String region;
  final ComplianceStatus status;
  final List<String> requirements;
  final List<String> violations;
  final DateTime lastChecked;
  final String? certificateUrl;
  final Map<String, dynamic>? auditData;

  const ComplianceReport({
    required this.region,
    required this.status,
    required this.requirements,
    required this.violations,
    required this.lastChecked,
    this.certificateUrl,
    this.auditData,
  });
}

/// 지역별 콘텐츠 관리자
class RegionalContentManager {
  static final RegionalContentManager _instance =
      RegionalContentManager._();
  static RegionalContentManager get instance => _instance;

  RegionalContentManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  Region _currentRegion = Region.global;
  RegionalContentConfig? _currentConfig;

  final Map<String, ContentItem> _contentItems = {};
  final Map<Region, List<RegionalEvent>> _events = {};
  final Map<Region, ComplianceReport> _complianceReports = {};

  final StreamController<Region> _regionController =
      StreamController<Region>.broadcast();
  final StreamController<ContentItem> _contentController =
      StreamController<ContentItem>.broadcast();
  final StreamController<RegionalEvent> _eventController =
      StreamController<RegionalEvent>.broadcast();

  Stream<Region> get onRegionChange => _regionController.stream;
  Stream<ContentItem> get onContentUpdate => _contentController.stream;
  Stream<RegionalEvent> get onEventUpdate => _eventController.stream;

  Timer? _complianceCheckTimer;

  /// 초기화
  Future<void> initialize({Region? region}) async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 지역 감지
    if (region != null) {
      _currentRegion = region;
    } else {
      await _detectRegion();
    }

    // 콘텐츠 로드
    await _loadContent();

    // 이벤트 로드
    await _loadEvents();

    // 규정 준수 체크 시작
    _startComplianceCheck();

    debugPrint('[RegionalContent] Initialized: ${_currentRegion.name}');
  }

  Future<void> _detectRegion() async {
    // 저장된 지역 확인
    final savedRegion = _prefs?.getString('detected_region');
    if (savedRegion != null) {
      _currentRegion = Region.values.firstWhere(
        (r) => r.name == savedRegion,
        orElse: () => Region.global,
      );
    } else {
      // IP 또는 시스템 설정으로 감지 (시뮬레이션)
      _currentRegion = await _detectRegionFromSystem();
      await _prefs?.setString('detected_region', _currentRegion.name);
    }

    // 지역 설정 로드
    await _loadRegionalConfig();
  }

  Future<Region> _detectRegionFromSystem() async {
    // 실제로는 시스템 로케일 또는 IP 기반 감지
    // 여기서는 시뮬레이션
    return Region.na;
  }

  Future<void> _loadRegionalConfig() async {
    // 지역별 설정 정의
    final configs = {
      Region.kr: const RegionalContentConfig(
        region: Region.kr,
        countryCode: 'KR',
        defaultRating: ContentRating.teen,
        restrictions: [
          RegionalRestriction.gambling,
        ],
        currencyCode: 'KRW',
        serverRegion: 'asia-east1',
        requiresCompliance: true,
      ),
      Region.jp: const RegionalContentConfig(
        region: Region.jp,
        countryCode: 'JP',
        defaultRating: ContentRating.teen,
        restrictions: [
          RegionalRestriction.gambling,
        ],
        currencyCode: 'JPY',
        serverRegion: 'asia-east2',
        requiresCompliance: true,
      ),
      Region.cn: const RegionalContentConfig(
        region: Region.cn,
        countryCode: 'CN',
        defaultRating: ContentRating.teen,
        restrictions: [
          RegionalRestriction.gambling,
          RegionalRestriction.violence,
          RegionalRestriction.religion,
          RegionalRestriction.politics,
        ],
        currencyCode: 'CNY',
        serverRegion: 'asia-cn',
        requiresCompliance: true,
      ),
      Region.eu: const RegionalContentConfig(
        region: Region.eu,
        countryCode: 'EU',
        defaultRating: ContentRating.mature,
        restrictions: [
          RegionalRestriction.language,
        ],
        currencyCode: 'EUR',
        serverRegion: 'europe-west1',
        requiresCompliance: true, // GDPR
      ),
      Region.na: const RegionalContentConfig(
        region: Region.na,
        countryCode: 'US',
        defaultRating: ContentRating.teen,
        restrictions: [],
        currencyCode: 'USD',
        serverRegion: 'us-central1',
        requiresCompliance: false,
      ),
    };

    _currentConfig = configs[_currentRegion];
  }

  Future<void> _loadContent() async {
    // 샘플 콘텐츠
    _contentItems['weapon_001'] = const ContentItem(
      contentId: 'weapon_001',
      name: 'Legendary Sword',
      category: ContentCategory.items,
      rating: ContentRating.everyone,
      availableRegions: [
        Region.global,
      ],
      restrictionLevels: {
        RegionalRestriction.violence: 3,
      },
    );

    _contentItems['character_001'] = const ContentItem(
      contentId: 'character_001',
      name: 'Warrior Class',
      category: ContentCategory.characters,
      rating: ContentRating.everyone,
      availableRegions: [
        Region.global,
      ],
      restrictionLevels: {
        RegionalRestriction.violence: 5,
      },
    );

    _contentItems['event_halloween'] = const ContentItem(
      contentId: 'event_halloween',
      name: 'Halloween Event',
      category: ContentCategory.events,
      rating: ContentRating.everyone,
      availableRegions: [
        Region.na,
        Region.eu,
        Region.kr,
        Region.jp,
      ],
      excludedRegions: [
        Region.cn, // 중국에서는 할로윈 이벤트 제한
      ],
    );

    _contentItems['gacha_system'] = const ContentItem(
      contentId: 'gacha_system',
      name: 'Gacha System',
      category: ContentCategory.gameplay,
      rating: ContentRating.teen,
      availableRegions: [
        Region.global,
      ],
      excludedRegions: [
        Region.kr,
        Region.jp,
        Region.cn, // 일부 국가에서 도박 규제
      ],
      restrictionLevels: {
        RegionalRestriction.gambling: 8,
      },
    );
  }

  Future<void> _loadEvents() async {
    // 지역별 이벤트
    _events[Region.kr] = [
      RegionalEvent(
        eventId: 'kr_chuseok_2024',
        name: 'Chuseok Festival',
        description: 'Special Chuseok celebration event',
        region: Region.kr,
        startTime: DateTime(2024, 9, 14),
        endTime: DateTime(2024, 9, 18),
        rewards: {
          'coins': 10000,
          'special_item': 'chuseok_costume',
        },
      ),
    ];

    _events[Region.jp] = [
      RegionalEvent(
        eventId: 'jp_golden_week_2024',
        name: 'Golden Week Special',
        description: 'Golden Week celebration event',
        region: Region.jp,
        startTime: DateTime(2024, 4, 27),
        endTime: DateTime(2024, 5, 6),
        rewards: {
          'coins': 15000,
          'special_item': 'golden_week_item',
        },
      ),
    ];

    _events[Region.cn] = [
      RegionalEvent(
        eventId: 'cn_lunar_new_year_2024',
        name: 'Lunar New Year Celebration',
        description: 'Lunar New Year special event',
        region: Region.cn,
        startTime: DateTime(2024, 2, 10),
        endTime: DateTime(2024, 2, 17),
        rewards: {
          'coins': 20000,
          'special_item': 'lunar_new_year_costume',
        },
      ),
    ];

    _events[Region.na] = [
      RegionalEvent(
        eventId: 'na_thanksgiving_2024',
        name: 'Thanksgiving Festival',
        description: 'Thanksgiving special event',
        region: Region.na,
        startTime: DateTime(2024, 11, 22),
        endTime: DateTime(2024, 11, 29),
        rewards: {
          'coins': 12000,
          'special_item': 'thanksgiving_item',
        },
      ),
    ];
  }

  void _startComplianceCheck() {
    _complianceCheckTimer?.cancel();
    _complianceCheckTimer = Timer.periodic(const Duration(hours: 24), (_) {
      checkCompliance();
    });
  }

  /// 지역 설정
  Future<void> setRegion(Region region) async {
    if (_currentRegion == region) return;

    _currentRegion = region;
    await _prefs?.setString('detected_region', region.name);
    await _loadRegionalConfig();

    _regionController.add(region);

    debugPrint('[RegionalContent] Region changed to: ${region.name}');
  }

  /// 현재 지역
  Region get currentRegion => _currentRegion;

  /// 현재 지역 설정
  RegionalContentConfig? get currentConfig => _currentConfig;

  /// 콘텐츠 사용 가능 여부 확인
  bool isContentAvailable(String contentId) {
    final content = _contentItems[contentId];
    if (content == null) return false;

    // 지역 체크
    if (!content.isAvailableIn(_currentRegion)) {
      return false;
    }

    // 규제 체크
    if (_currentConfig != null) {
      for (final restriction in content.restrictionLevels.keys) {
        if (_currentConfig!.restrictions.contains(restriction)) {
          return false;
        }
      }

      // 금지된 기능 체크
      if (_currentConfig!.prohibitedFeatures.contains(contentId)) {
        return false;
      }
    }

    return true;
  }

  /// 필터링된 콘텐츠 목록
  List<ContentItem> getAvailableContent({
    ContentCategory? category,
    ContentRating? maxRating,
  }) {
    var contents = _contentItems.values.where((item) =>
        isContentAvailable(item.contentId));

    if (category != null) {
      contents = contents.where((item) => item.category == category);
    }

    if (maxRating != null) {
      contents = contents.where((item) =>
          item.rating.index <= maxRating.index);
    }

    return contents.toList();
  }

  /// 지역별 이벤트 목록
  List<RegionalEvent> getActiveEvents({Region? region}) {
    final targetRegion = region ?? _currentRegion;
    final events = _events[targetRegion] ?? [];

    return events.where((event) => event.isActive).toList();
  }

  /// 콘텐츠 추가
  Future<void> addContent(ContentItem content) async {
    _contentItems[content.contentId] = content;
    _contentController.add(content);

    await _saveContent();
  }

  /// 콘텐츠 제거
  Future<void> removeContent(String contentId) async {
    _contentItems.remove(contentId);

    await _saveContent();
  }

  /// 이벤트 추가
  Future<void> addEvent(RegionalEvent event) async {
    final events = _events[event.region] ?? [];
    _events[event.region] = [...events, event];
    _eventController.add(event);

    await _saveEvents();
  }

  /// 규정 준수 체크
  Future<ComplianceReport> checkCompliance() async {
    if (_currentConfig == null) {
      return ComplianceReport(
        region: _currentRegion.name,
        status: ComplianceStatus.exempt,
        requirements: [],
        violations: [],
        lastChecked: DateTime.now(),
      );
    }

    final requirements = <String>[];
    final violations = <String>[];

    // 지역별 규정 요구사항
    switch (_currentRegion) {
      case Region.eu:
        requirements.addAll([
          'GDPR compliance',
          'Data privacy consent',
          'Right to data deletion',
          'Cookie consent',
        ]);
        break;

      case Region.cn:
        requirements.addAll([
          'Real-name verification',
          'Game time limits',
          'Content censorship',
          'Data localization',
        ]);
        break;

      case Region.kr:
        requirements.addAll([
          'Game rating compliance',
          'Probability disclosure',
          'Spending limits',
          'Minor protection',
        ]);
        break;

      case Region.jp:
        requirements.addAll([
          'Gacha probability disclosure',
          'Spending caps',
          'Minor restrictions',
        ]);
        break;

      default:
        break;
    }

    // 위반사항 체크 (시뮬레이션)
    if (_currentConfig!.requiresCompliance) {
      // 실제로는 각 요구사항 체크
    }

    final status = violations.isEmpty
        ? ComplianceStatus.compliant
        : ComplianceStatus.nonCompliant;

    final report = ComplianceReport(
      region: _currentRegion.name,
      status: status,
      requirements: requirements,
      violations: violations,
      lastChecked: DateTime.now(),
    );

    _complianceReports[_currentRegion] = report;

    return report;
  }

  /// 콘텐츠 현지화
  String? getLocalizedContentId(String contentId) {
    final content = _contentItems[contentId];
    return content?.localizedId;
  }

  /// 지역별 통계
  RegionalStatistics getStatistics(Region region) {
    // 실제로는 서버에서 통계 가져옴
    return RegionalStatistics(
      region: region,
      activeUsers: 10000,
      totalUsers: 50000,
      avgSessionTime: 45.0,
      revenue: 50000.0,
      contentViews: 100000,
      popularContent: {
        'weapon_001': 5000,
        'character_001': 4000,
      },
      periodStart: DateTime.now().subtract(const Duration(days: 7)),
      periodEnd: DateTime.now(),
    );
  }

  /// 금지된 콘텐츠 추가
  Future<void> prohibitContent(String contentId) async {
    if (_currentConfig == null) return;

    final updated = RegionalContentConfig(
      region: _currentConfig!.region,
      countryCode: _currentConfig!.countryCode,
      defaultRating: _currentConfig!.defaultRating,
      restrictedCategories: _currentConfig!.restrictedCategories,
      restrictions: _currentConfig!.restrictions,
      customSettings: _currentConfig!.customSettings,
      serverRegion: _currentConfig!.serverRegion,
      currencyCode: _currentConfig!.currencyCode,
      prohibitedFeatures: [..._currentConfig!.prohibitedFeatures, contentId],
      requiresCompliance: _currentConfig!.requiresCompliance,
    );

    _currentConfig = updated;
  }

  Future<void> _saveContent() async {
    final data = _contentItems.map((key, value) => MapEntry(
      key,
      {
        'contentId': value.contentId,
        'name': value.name,
        'category': value.category.name,
      },
    ));

    await _prefs?.setString('regional_content', jsonEncode(data));
  }

  Future<void> _saveEvents() async {
    // 이벤트 저장
  }

  void dispose() {
    _regionController.close();
    _contentController.close();
    _eventController.close();
    _complianceCheckTimer?.cancel();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 콘텐츠 타입
enum ContentType {
  announcement,    // 공지사항
  event,          // 이벤트
  news,           // 뉴스
  maintenance,    // 점검
  update,         // 업데이트
  promotion,      // 프로모션
  patch,          // 패치 노트
}

/// 콘텐츠 상태
enum ContentStatus {
  draft,          // 임시저장
  scheduled,      // 예약
  published,      // 게시
  archived,       // 보관
  deleted,        // 삭제
}

/// 타겟 플랫폼
enum TargetPlatform {
  all,            // 전체
  ios,            // iOS
  android,        // Android
  pc,             // PC
  web,            // Web
}

/// 콘텐츠
class GameContent {
  final String id;
  final String title;
  final String body;
  final ContentType type;
  final ContentStatus status;
  final String? imageUrl;
  final String? linkUrl;
  final DateTime? publishedAt;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final List<TargetPlatform> platforms;
  final List<String>? tags;
  final int priority; // 0-100
  final int viewCount;
  final int likeCount;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GameContent({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    this.imageUrl,
    this.linkUrl,
    this.publishedAt,
    this.scheduledAt,
    this.expiresAt,
    required this.platforms,
    this.tags,
    required this.priority,
    required this.viewCount,
    required this.likeCount,
    this.authorId,
    this.authorName,
    required this.createdAt,
    this.updatedAt,
  });

  /// 활성 여부
  bool get isActive {
    if (status != ContentStatus.published) return false;

    final now = DateTime.now();
    if (publishedAt != null && now.isBefore(publishedAt!)) return false;
    if (expiresAt != null && now.isAfter(expiresAt!)) return false;

    return true;
  }
}

/// 배너
class Banner {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final int priority;
  final List<TargetPlatform> platforms;
  final bool isActive;

  const Banner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.startDate,
    this.endDate,
    required this.priority,
    required this.platforms,
    required this.isActive,
  });
}

/// 푸시 알림
class PushNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? linkUrl;
  final DateTime? scheduledAt;
  final bool isSent;
  final int targetCount; // 발송 대상 수
  final int sentCount; // 실제 발송 수
  final int openCount; // 오픈 수

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.linkUrl,
    this.scheduledAt,
    required this.isSent,
    required this.targetCount,
    required this.sentCount,
    required this.openCount,
  });

  /// 오픈률
  double get openRate => sentCount > 0 ? openCount / sentCount : 0.0;
}

/// 콘텐츠 관리자
class ContentManager {
  static final ContentManager _instance = ContentManager._();
  static ContentManager get instance => _instance;

  ContentManager._();

  SharedPreferences? _prefs;

  final Map<String, GameContent> _contents = {};
  final Map<String, Banner> _banners = {};
  final Map<String, PushNotification> _notifications = {};

  final StreamController<GameContent> _contentController =
      StreamController<GameContent>.broadcast();
  final StreamController<Banner> _bannerController =
      StreamController<Banner>.broadcast();
  final StreamController<PushNotification> _notificationController =
      StreamController<PushNotification>.broadcast();

  Stream<GameContent> get onContentUpdate => _contentController.stream;
  Stream<Banner> get onBannerUpdate => _bannerController.stream;
  Stream<PushNotification> get onNotification => _notificationController.stream;

  Timer? _scheduleTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 기본 콘텐츠 로드
    await _loadDefaultContents();

    // 배너 로드
    await _loadBanners();

    // 스케줄 체크 시작
    _startScheduleCheck();

    debugPrint('[Content] Initialized');
  }

  Future<void> _loadDefaultContents() async {
    // 공지사항
    _contents['announce_1'] = GameContent(
      id: 'announce_1',
      title: '정기 점검 안내',
      body: '안정적인 서비스 제공을 위해 정기 점검을 진행합니다.',
      type: ContentType.maintenance,
      status: ContentStatus.published,
      imageUrl: 'assets/images/maintenance.png',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      platforms: TargetPlatform.values,
      tags: ['점검', '안내'],
      priority: 80,
      viewCount: 15234,
      likeCount: 234,
      authorName: '운영팀',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    // 이벤트
    _contents['event_1'] = GameContent(
      id: 'event_1',
      title: '한겨울 축제 이벤트',
      body: '한겨울 축제 이벤트가 진행됩니다! 다양한 보상을 획득하세요.',
      type: ContentType.event,
      status: ContentStatus.published,
      imageUrl: 'assets/images/winter_event.png',
      linkUrl: '/events/winter',
      publishedAt: DateTime.now().subtract(const Duration(days: 7)),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      platforms: TargetPlatform.values,
      tags: ['이벤트', '보너스'],
      priority: 100,
      viewCount: 45678,
      likeCount: 1234,
      authorName: '이벤트팀',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    // 업데이트
    _contents['update_1'] = GameContent(
      id: 'update_1',
      title: 'v1.2.3 업데이트 안내',
      body: '새로운 챔피언과 시스템 개선이 포함된 업데이트입니다.',
      type: ContentType.update,
      status: ContentStatus.published,
      imageUrl: 'assets/images/update.png',
      linkUrl: '/updates/v123',
      publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
      platforms: TargetPlatform.values,
      tags: ['업데이트', '패치'],
      priority: 90,
      viewCount: 23456,
      likeCount: 876,
      authorName: '개발팀',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  Future<void> _loadBanners() async {
    _banners['banner_1'] = Banner(
      id: 'banner_1',
      title: '신규 유저 특별 보상',
      imageUrl: 'assets/banners/new_user.png',
      linkUrl: '/events/newbie',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      priority: 100,
      platforms: TargetPlatform.values,
      isActive: true,
    );

    _banners['banner_2'] = Banner(
      id: 'banner_2',
      title: '한정 시간 레이드',
      imageUrl: 'assets/banners/raid.png',
      linkUrl: '/raids/limited',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      priority: 90,
      platforms: TargetPlatform.values,
      isActive: true,
    );
  }

  void _startScheduleCheck() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkScheduledContent();
    });
  }

  /// 스케줄 체크
  void _checkScheduledContent() {
    final now = DateTime.now();

    for (final content in _contents.values) {
      if (content.status == ContentStatus.scheduled &&
          content.scheduledAt != null &&
          now.isAfter(content.scheduledAt!)) {
        publishContent(content.id);
      }

      // 만료된 콘텐츠 보관
      if (content.status == ContentStatus.published &&
          content.expiresAt != null &&
          now.isAfter(content.expiresAt!)) {
        archiveContent(content.id);
      }
    }

    // 배너 활성화/비활성화
    for (final banner in _banners.values) {
      final shouldBeActive = _isBannerActive(banner);
      if (banner.isActive != shouldBeActive) {
        final updated = Banner(
          id: banner.id,
          title: banner.title,
          imageUrl: banner.imageUrl,
          linkUrl: banner.linkUrl,
          startDate: banner.startDate,
          endDate: banner.endDate,
          priority: banner.priority,
          platforms: banner.platforms,
          isActive: shouldBeActive,
        );
        _banners[banner.id] = updated;
        _bannerController.add(updated);
      }
    }
  }

  bool _isBannerActive(Banner banner) {
    final now = DateTime.now();

    if (banner.startDate != null && now.isBefore(banner.startDate!)) {
      return false;
    }

    if (banner.endDate != null && now.isAfter(banner.endDate!)) {
      return false;
    }

    return true;
  }

  /// 콘텐츠 생성
  Future<GameContent> createContent({
    required String title,
    required String body,
    required ContentType type,
    String? imageUrl,
    String? linkUrl,
    DateTime? scheduledAt,
    DateTime? expiresAt,
    List<TargetPlatform>? platforms,
    List<String>? tags,
    int priority = 50,
  }) async {
    final contentId = 'content_${DateTime.now().millisecondsSinceEpoch}';
    final content = GameContent(
      id: contentId,
      title: title,
      body: body,
      type: type,
      status: scheduledAt != null ? ContentStatus.scheduled : ContentStatus.draft,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      scheduledAt: scheduledAt,
      expiresAt: expiresAt,
      platforms: platforms ?? TargetPlatform.values,
      tags: tags,
      priority: priority,
      viewCount: 0,
      likeCount: 0,
      createdAt: DateTime.now(),
    );

    _contents[contentId] = content;
    _contentController.add(content);

    await _saveContent(content);

    debugPrint('[Content] Created: $title');

    return content;
  }

  /// 콘텐츠 게시
  Future<void> publishContent(String contentId) async {
    final content = _contents[contentId];
    if (content == null) return;

    final updated = GameContent(
      id: content.id,
      title: content.title,
      body: content.body,
      type: content.type,
      status: ContentStatus.published,
      imageUrl: content.imageUrl,
      linkUrl: content.linkUrl,
      publishedAt: DateTime.now(),
      scheduledAt: content.scheduledAt,
      expiresAt: content.expiresAt,
      platforms: content.platforms,
      tags: content.tags,
      priority: content.priority,
      viewCount: content.viewCount,
      likeCount: content.likeCount,
      authorId: content.authorId,
      authorName: content.authorName,
      createdAt: content.createdAt,
      updatedAt: DateTime.now(),
    );

    _contents[contentId] = updated;
    _contentController.add(updated);

    debugPrint('[Content] Published: ${content.title}');
  }

  /// 콘텐츠 보관
  Future<void> archiveContent(String contentId) async {
    final content = _contents[contentId];
    if (content == null) return;

    final updated = GameContent(
      id: content.id,
      title: content.title,
      body: content.body,
      type: content.type,
      status: ContentStatus.archived,
      imageUrl: content.imageUrl,
      linkUrl: content.linkUrl,
      publishedAt: content.publishedAt,
      scheduledAt: content.scheduledAt,
      expiresAt: content.expiresAt,
      platforms: content.platforms,
      tags: content.tags,
      priority: content.priority,
      viewCount: content.viewCount,
      likeCount: content.likeCount,
      authorId: content.authorId,
      authorName: content.authorName,
      createdAt: content.createdAt,
      updatedAt: DateTime.now(),
    );

    _contents[contentId] = updated;
    _contentController.add(updated);

    debugPrint('[Content] Archived: ${content.title}');
  }

  /// 콘텐츠 삭제
  Future<void> deleteContent(String contentId) async {
    final content = _contents[contentId];
    if (content == null) return;

    final updated = GameContent(
      id: content.id,
      title: content.title,
      body: content.body,
      type: content.type,
      status: ContentStatus.deleted,
      imageUrl: content.imageUrl,
      linkUrl: content.linkUrl,
      publishedAt: content.publishedAt,
      scheduledAt: content.scheduledAt,
      expiresAt: content.expiresAt,
      platforms: content.platforms,
      tags: content.tags,
      priority: content.priority,
      viewCount: content.viewCount,
      likeCount: content.likeCount,
      authorId: content.authorId,
      authorName: content.authorName,
      createdAt: content.createdAt,
      updatedAt: DateTime.now(),
    );

    _contents[contentId] = updated;
    _contentController.add(updated);

    debugPrint('[Content] Deleted: ${content.title}');
  }

  /// 조회수 증가
  Future<void> incrementViewCount(String contentId) async {
    final content = _contents[contentId];
    if (content == null) return;

    final updated = GameContent(
      id: content.id,
      title: content.title,
      body: content.body,
      type: content.type,
      status: content.status,
      imageUrl: content.imageUrl,
      linkUrl: content.linkUrl,
      publishedAt: content.publishedAt,
      scheduledAt: content.scheduledAt,
      expiresAt: content.expiresAt,
      platforms: content.platforms,
      tags: content.tags,
      priority: content.priority,
      viewCount: content.viewCount + 1,
      likeCount: content.likeCount,
      authorId: content.authorId,
      authorName: content.authorName,
      createdAt: content.createdAt,
      updatedAt: DateTime.now(),
    );

    _contents[contentId] = updated;
  }

  /// 좋아요
  Future<void> likeContent(String contentId) async {
    final content = _contents[contentId];
    if (content == null) return;

    final updated = GameContent(
      id: content.id,
      title: content.title,
      body: content.body,
      type: content.type,
      status: content.status,
      imageUrl: content.imageUrl,
      linkUrl: content.linkUrl,
      publishedAt: content.publishedAt,
      scheduledAt: content.scheduledAt,
      expiresAt: content.expiresAt,
      platforms: content.platforms,
      tags: content.tags,
      priority: content.priority,
      viewCount: content.viewCount,
      likeCount: content.likeCount + 1,
      authorId: content.authorId,
      authorName: content.authorName,
      createdAt: content.createdAt,
      updatedAt: DateTime.now(),
    );

    _contents[contentId] = updated;
    _contentController.add(updated);

    debugPrint('[Content] Liked: ${content.title}');
  }

  /// 배너 생성
  Future<Banner> createBanner({
    required String title,
    required String imageUrl,
    String? linkUrl,
    DateTime? startDate,
    DateTime? endDate,
    int priority = 50,
    List<TargetPlatform>? platforms,
  }) async {
    final bannerId = 'banner_${DateTime.now().millisecondsSinceEpoch}';
    final banner = Banner(
      id: bannerId,
      title: title,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      startDate: startDate,
      endDate: endDate,
      priority: priority,
      platforms: platforms ?? TargetPlatform.values,
      isActive: false,
    );

    _banners[bannerId] = banner;
    _bannerController.add(banner);

    debugPrint('[Content] Banner created: $title');

    return banner;
  }

  /// 푸시 알림 발송
  Future<PushNotification> sendPushNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? linkUrl,
    DateTime? scheduledAt,
  }) async {
    final notificationId = 'push_${DateTime.now().millisecondsSinceEpoch}';
    final notification = PushNotification(
      id: notificationId,
      title: title,
      body: body,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      scheduledAt: scheduledAt,
      isSent: scheduledAt == null,
      targetCount: 10000, // 시뮬레이션
      sentCount: scheduledAt == null ? 9500 : 0,
      openCount: scheduledAt == null ? 3800 : 0,
    );

    _notifications[notificationId] = notification;
    _notificationController.add(notification);

    debugPrint('[Content] Push notification sent: $title');

    return notification;
  }

  /// 콘텐츠 목록 조회
  List<GameContent> getContents({
    ContentType? type,
    ContentStatus? status,
    List<TargetPlatform>? platforms,
    bool? activeOnly,
  }) {
    var contents = _contents.values.toList();

    if (type != null) {
      contents = contents.where((c) => c.type == type).toList();
    }

    if (status != null) {
      contents = contents.where((c) => c.status == status).toList();
    }

    if (platforms != null) {
      contents = contents.where((c) =>
          c.platforms.any((p) => platforms.contains(p))).toList();
    }

    if (activeOnly == true) {
      contents = contents.where((c) => c.isActive).toList();
    }

    return contents..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 배너 목록 조회
  List<Banner> getBanners({bool? activeOnly}) {
    var banners = _banners.values.toList();

    if (activeOnly == true) {
      banners = banners.where((b) => b.isActive).toList();
    }

    return banners..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 콘텐츠 검색
  List<GameContent> searchContents(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _contents.values
        .where((c) =>
            c.title.toLowerCase().contains(lowerKeyword) ||
            c.body.toLowerCase().contains(lowerKeyword) ||
            (c.tags?.any((t) => t.toLowerCase().contains(lowerKeyword)) ?? false))
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 태그별 콘텐츠
  List<GameContent> getContentsByTag(String tag) {
    return _contents.values
        .where((c) => c.tags?.contains(tag) ?? false)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveContent(GameContent content) async {
    await _prefs?.setString(
      'content_${content.id}',
      jsonEncode({
        'id': content.id,
        'title': content.title,
        'type': content.type.name,
        'status': content.status.name,
        'publishedAt': content.publishedAt?.toIso8601String(),
      }),
    );
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final typeDistribution = <ContentType, int>{};
    for (final type in ContentType.values) {
      typeDistribution[type] =
          _contents.values.where((c) => c.type == type).length;
    }

    final totalViews = _contents.values.fold<int>(
        0, (sum, c) => sum + c.viewCount);
    final totalLikes = _contents.values.fold<int>(
        0, (sum, c) => sum + c.likeCount);

    return {
      'totalContents': _contents.length,
      'typeDistribution': typeDistribution.map((k, v) => MapEntry(k.name, v)),
      'totalBanners': _banners.length,
      'activeBanners': _banners.values.where((b) => b.isActive).length,
      'totalNotifications': _notifications.length,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
    };
  }

  void dispose() {
    _contentController.close();
    _bannerController.close();
    _notificationController.close();
    _scheduleTimer?.cancel();
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 지원 언어
enum AppLanguage {
  korean,
  english,
  japanese,
  chinese,
  spanish,
  french,
  german,
  portuguese,
  russian,
  arabic,
}

/// 지역 정보
class LocaleInfo {
  final AppLanguage language;
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;
  final String name;
  final bool isRTL;
  final String flag;

  const LocaleInfo({
    required this.language,
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
    required this.name,
    required this.isRTL,
    required this.flag,
  });

  /// Locale 객체 생성
  Locale get locale {
    if (scriptCode != null) {
      return Locale.fromSubtags(
        languageCode: languageCode,
        scriptCode: scriptCode,
        countryCode: countryCode,
      );
    }
    return Locale(languageCode, countryCode);
  }

  /// 지원하는 모든 언어 목록
  static const List<LocaleInfo> all = [
    LocaleInfo(
      language: AppLanguage.korean,
      languageCode: 'ko',
      name: '한국어',
      isRTL: false,
      flag: '🇰🇷',
    ),
    LocaleInfo(
      language: AppLanguage.english,
      languageCode: 'en',
      countryCode: 'US',
      name: 'English',
      isRTL: false,
      flag: '🇺🇸',
    ),
    LocaleInfo(
      language: AppLanguage.japanese,
      languageCode: 'ja',
      name: '日本語',
      isRTL: false,
      flag: '🇯🇵',
    ),
    LocaleInfo(
      language: AppLanguage.chinese,
      languageCode: 'zh',
      name: '中文',
      isRTL: false,
      flag: '🇨🇳',
    ),
    LocaleInfo(
      language: AppLanguage.spanish,
      languageCode: 'es',
      name: 'Español',
      isRTL: false,
      flag: '🇪🇸',
    ),
    LocaleInfo(
      language: AppLanguage.french,
      languageCode: 'fr',
      name: 'Français',
      isRTL: false,
      flag: '🇫🇷',
    ),
    LocaleInfo(
      language: AppLanguage.german,
      languageCode: 'de',
      name: 'Deutsch',
      isRTL: false,
      flag: '🇩🇪',
    ),
    LocaleInfo(
      language: AppLanguage.portuguese,
      languageCode: 'pt',
      name: 'Português',
      isRTL: false,
      flag: '🇧🇷',
    ),
    LocaleInfo(
      language: AppLanguage.russian,
      languageCode: 'ru',
      name: 'Русский',
      isRTL: false,
      flag: '🇷🇺',
    ),
    LocaleInfo(
      language: AppLanguage.arabic,
      languageCode: 'ar',
      name: 'العربية',
      isRTL: true,
      flag: '🇸🇦',
    ),
  ];

  /// 언어 코드로 찾기
  static LocaleInfo? fromLanguageCode(String languageCode) {
    try {
      return all.firstWhere(
        (info) => info.languageCode == languageCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// AppLanguage에서 찾기
  static LocaleInfo fromAppLanguage(AppLanguage language) {
    return all.firstWhere(
      (info) => info.language == language,
      orElse: () => all[1], // 영어를 기본값으로
    );
  }
}

/// 번역 데이터
class Translations {
  static const Map<String, Map<String, String>> _translations = {
    'ko': {
      'app_name': 'MG Games',
      'home': '홈',
      'settings': '설정',
      'quest': '퀘스트',
      'event': '이벤트',
      'shop': '상점',
      'profile': '프로필',
      'friends': '친구',
      'chat': '채팅',
      'leaderboard': '리더보드',
      'save': '저장',
      'load': '불러오기',
      'confirm': '확인',
      'cancel': '취소',
      'delete': '삭제',
      'edit': '편집',
      'close': '닫기',
      'retry': '재시도',
      'loading': '로딩 중...',
      'error': '오류',
      'success': '성공',
      'warning': '경고',
      'info': '정보',
      // 퀘스트 관련
      'daily_quest': '일일 퀘스트',
      'quest_complete': '퀘스트 완료!',
      'quest_reward': '퀘스트 보상',
      'accept_quest': '퀘스트 수락',
      'quest_progress': '진행률',
      // 이벤트 관련
      'event_started': '이벤트 시작',
      'event_ended': '이벤트 종료',
      'join_event': '이벤트 참여',
      'event_reward': '이벤트 보상',
      // 상점 관련
      'purchase': '구매',
      'purchase_complete': '구매 완료',
      'insufficient_currency': '통화 부족',
      // 소셜 관련
      'add_friend': '친구 추가',
      'remove_friend': '친구 삭제',
      'send_message': '메시지 전송',
      'online': '온라인',
      'offline': '오프라인',
      'in_game': '게임 중',
    },
    'en': {
      'app_name': 'MG Games',
      'home': 'Home',
      'settings': 'Settings',
      'quest': 'Quest',
      'event': 'Event',
      'shop': 'Shop',
      'profile': 'Profile',
      'friends': 'Friends',
      'chat': 'Chat',
      'leaderboard': 'Leaderboard',
      'save': 'Save',
      'load': 'Load',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'retry': 'Retry',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Info',
      'daily_quest': 'Daily Quest',
      'quest_complete': 'Quest Complete!',
      'quest_reward': 'Quest Reward',
      'accept_quest': 'Accept Quest',
      'quest_progress': 'Progress',
      'event_started': 'Event Started',
      'event_ended': 'Event Ended',
      'join_event': 'Join Event',
      'event_reward': 'Event Reward',
      'purchase': 'Purchase',
      'purchase_complete': 'Purchase Complete',
      'insufficient_currency': 'Insufficient Currency',
      'add_friend': 'Add Friend',
      'remove_friend': 'Remove Friend',
      'send_message': 'Send Message',
      'online': 'Online',
      'offline': 'Offline',
      'in_game': 'In Game',
    },
    'ja': {
      'app_name': 'MGゲーム',
      'home': 'ホーム',
      'settings': '設定',
      'quest': 'クエスト',
      'event': 'イベント',
      'shop': 'ショップ',
      'profile': 'プロフィール',
      'friends': 'フレンド',
      'chat': 'チャット',
      'leaderboard': 'リーダーボード',
      'save': '保存',
      'load': 'ロード',
      'confirm': '確認',
      'cancel': 'キャンセル',
      'delete': '削除',
      'edit': '編集',
      'close': '閉じる',
      'retry': '再試行',
      'loading': '読み込み中...',
      'error': 'エラー',
      'success': '成功',
      'warning': '警告',
      'info': '情報',
      'daily_quest': 'デイリークエスト',
      'quest_complete': 'クエスト完了！',
      'quest_reward': 'クエスト報酬',
      'accept_quest': 'クエスト受諾',
      'quest_progress': '進行状況',
    },
    'zh': {
      'app_name': 'MG游戏',
      'home': '主页',
      'settings': '设置',
      'quest': '任务',
      'event': '活动',
      'shop': '商店',
      'profile': '个人资料',
      'friends': '好友',
      'chat': '聊天',
      'leaderboard': '排行榜',
      'save': '保存',
      'load': '加载',
      'confirm': '确认',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'close': '关闭',
      'retry': '重试',
      'loading': '加载中...',
      'error': '错误',
      'success': '成功',
      'warning': '警告',
      'info': '信息',
      'daily_quest': '每日任务',
      'quest_complete': '任务完成！',
      'quest_reward': '任务奖励',
      'accept_quest': '接受任务',
      'quest_progress': '进度',
    },
    // 다른 언어들도 필요에 따라 추가
  };

  /// 번역 가져오기
  static String get(String key, [String languageCode = 'en']) {
    final langTranslations = _translations[languageCode];
    if (langTranslations != null) {
      final value = langTranslations[key];
      if (value != null) return value;
    }

    // 영어를 기본값으로 사용
    final enTranslations = _translations['en'];
    if (enTranslations != null) {
      final value = enTranslations[key];
      if (value != null) return value;
    }

    return key; // 키를 기본값으로 반환
  }

  /// 모든 키 가져오기
  static Set<String> getAllKeys() {
    final keys = <String>{};
    for (final lang in _translations.values) {
      keys.addAll(lang.keys);
    }
    return keys;
  }

  /// 번역 누락 확인
  static Map<String, List<String>> getMissingTranslations() {
    final missing = <String, List<String>>{};
    final allKeys = getAllKeys();

    for (final entry in _translations.entries) {
      final lang = entry.key;
      final translations = entry.value;
      final missingKeys = <String>[];

      for (final key in allKeys) {
        if (!translations.containsKey(key)) {
          missingKeys.add(key);
        }
      }

      if (missingKeys.isNotEmpty) {
        missing[lang] = missingKeys;
      }
    }

    return missing;
  }
}

/// 지역화 매니저
class LocalizationManager {
  static final LocalizationManager _instance = LocalizationManager._();
  static LocalizationManager get instance => _instance;

  LocalizationManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  LocaleInfo _currentLocale = LocaleInfo.fromAppLanguage(AppLanguage.english);

  final StreamController<LocaleInfo> _localeController =
      StreamController<LocaleInfo>.broadcast();

  // ============================================
  // Getters
  // ============================================
  LocaleInfo get currentLocale => _currentLocale;
  Locale get locale => _currentLocale.locale;
  bool get isRTL => _currentLocale.isRTL;
  Stream<LocaleInfo> get onLocaleChanged => _localeController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 저장된 언어 설정 로드
    final savedLang = _prefs!.getString('app_language');
    if (savedLang != null) {
      final localeInfo = LocaleInfo.fromLanguageCode(savedLang);
      if (localeInfo != null) {
        _currentLocale = localeInfo;
      }
    }

    debugPrint('[Localization] Initialized: ${_currentLocale.name}');
  }

  // ============================================
  // 언어 관리
  // ============================================

  Future<void> setLanguage(AppLanguage language) async {
    final newLocale = LocaleInfo.fromAppLanguage(language);

    if (_currentLocale.language != newLocale.language) {
      _currentLocale = newLocale;

      // 설정 저장
      await _prefs!.setString('app_language', newLocale.languageCode);

      // 알림
      _localeController.add(_currentLocale);

      debugPrint('[Localization] Language changed: ${newLocale.name}');
    }
  }

  Future<void> setLocaleFromSystem() async {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final localeInfo = LocaleInfo.fromLanguageCode(systemLocale.languageCode);

    if (localeInfo != null) {
      await setLanguage(localeInfo.language);
    }
  }

  // ============================================
  // 번역
  // ============================================

  String translate(String key) {
    return Translations.get(key, _currentLocale.languageCode);
  }

  /// 번역 헬퍼 메서드
  String t(String key) => translate(key);

  /// 복수형 번역 (간단 구현)
  String plural(String key, int count) {
    // 실제로는 각 언어의 복수형 규칙에 따라 처리
    return translate(key).replaceAll('{count}', count.toString());
  }

  // ============================================
  // 유틸리티
  // ============================================

  /// 지원하는 모든 언어 목록
  List<LocaleInfo> get supportedLanguages => List.unmodifiable(LocaleInfo.all);

  /// 번역 누락 보고서 생성
  Map<String, dynamic> generateTranslationReport() {
    final missing = Translations.getMissingTranslations();
    final totalKeys = Translations.getAllKeys().length;

    return {
      'total_keys': totalKeys,
      'supported_languages': LocaleInfo.all.length,
      'missing_translations': missing.map(
        (lang, keys) => MapEntry(lang, keys.length),
      ),
      'coverage_percentage': _calculateCoverage(missing, totalKeys),
    };
  }

  double _calculateCoverage(
    Map<String, List<String>> missing,
    int totalKeys,
  ) {
    if (totalKeys == 0) return 100.0;

    int totalTranslations = 0;
    for (final translations in Translations._translations.values) {
      totalTranslations += translations.length;
    }

    final expectedTotal = totalKeys * Translations._translations.length;
    return (totalTranslations / expectedTotal * 100).clamp(0.0, 100.0);
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _localeController.close();
  }
}

/// 지역화 확장
extension LocalizationExtension on BuildContext {
  /// 현재 언어로 번역
  String t(String key) {
    return LocalizationManager.instance.t(key);
  }

  /// 복수형 번역
  String tp(String key, int count) {
    return LocalizationManager.instance.plural(key, count);
  }

  /// 현재 로케일
  Locale get currentLocale => LocalizationManager.instance.locale;

  /// RTL 여부
  bool get isRTL => LocalizationManager.instance.isRTL;
}

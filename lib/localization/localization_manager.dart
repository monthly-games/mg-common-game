import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// 지원 언어
enum SupportedLanguage {
  english,        // 영어
  korean,         // 한국어
  japanese,       // 일본어
  chineseSimplified, // 중국어 간체
  chineseTraditional, // 중국어 번체
  spanish,        // 스페인어
  french,         // 프랑스어
  german,         // 독일어
  portuguese,     // 포르투갈어
  russian,        // 러시아어
  arabic,         // 아랍어
  hindi,          // 힌디어
  thai,           // 태국어
  vietnamese,     // 베트남어
  indonesian,     // 인도네시아어
}

/// 텍스트 방향
enum TextDirection {
  ltr,            // 왼쪽에서 오른쪽
  rtl,            // 오른쪽에서 왼쪽
}

/// 번역 키
class TranslationKey {
  final String key;
  final String category;
  final Map<String, dynamic>? parameters;
  final String? context;

  const TranslationKey({
    required this.key,
    required this.category,
    this.parameters,
    this.context,
  });
}

/// 번역 항목
class TranslationEntry {
  final String key;
  final Map<String, String> translations; // languageCode -> translation
  final String category;
  final String? context;
  final bool hasPlurals;
  final Map<String, dynamic>? metadata;

  const TranslationEntry({
    required this.key,
    required this.translations,
    required this.category,
    this.context,
    this.hasPlurals = false,
    this.metadata,
  });
}

/// 복수형 규칙
class PluralRule {
  final int quantity;
  final String form;

  const PluralRule({
    required this.quantity,
    required this.form,
  });
}

/// 지역화 설정
class LocalizationConfig {
  final SupportedLanguage language;
  final String regionCode; // ISO 3166-1 alpha-2
  final String? timeZone;
  final bool use24HourFormat;
  final String currencyCode;
  final String numberFormat;
  final String dateFormat;
  final bool autoDetectLanguage;

  const LocalizationConfig({
    required this.language,
    required this.regionCode,
    this.timeZone,
    this.use24HourFormat = true,
    this.currencyCode = 'USD',
    this.numberFormat = 'comma', // comma, period, space
    this.dateFormat = 'ymd', // ymd, dmy, mdy
    this.autoDetectLanguage = true,
  });

  /// 로케일 코드
  String get localeCode => '${_getLanguageCode()}_$regionCode';

  String _getLanguageCode() {
    switch (language) {
      case SupportedLanguage.english:
        return 'en';
      case SupportedLanguage.korean:
        return 'ko';
      case SupportedLanguage.japanese:
        return 'ja';
      case SupportedLanguage.chineseSimplified:
        return 'zh';
      case SupportedLanguage.chineseTraditional:
        return 'zh_TW';
      case SupportedLanguage.spanish:
        return 'es';
      case SupportedLanguage.french:
        return 'fr';
      case SupportedLanguage.german:
        return 'de';
      case SupportedLanguage.portuguese:
        return 'pt';
      case SupportedLanguage.russian:
        return 'ru';
      case SupportedLanguage.arabic:
        return 'ar';
      case SupportedLanguage.hindi:
        return 'hi';
      case SupportedLanguage.thai:
        return 'th';
      case SupportedLanguage.vietnamese:
        return 'vi';
      case SupportedLanguage.indonesian:
        return 'id';
    }
  }
}

/// 번역 리소스
class TranslationResource {
  final String languageCode;
  final Map<String, dynamic> translations;
  final DateTime? lastUpdated;
  final String? version;

  const TranslationResource({
    required this.languageCode,
    required this.translations,
    this.lastUpdated,
    this.version,
  });
}

/// 지역화 관리자
class LocalizationManager {
  static final LocalizationManager _instance =
      LocalizationManager._();
  static LocalizationManager get instance => _instance;

  LocalizationManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  LocalizationConfig _config = const LocalizationConfig(
    language: SupportedLanguage.english,
    regionCode: 'US',
  );

  final Map<String, TranslationEntry> _translations = {};
  final Map<String, TranslationResource> _resources = {};

  final StreamController<SupportedLanguage> _languageController =
      StreamController<SupportedLanguage>.broadcast();
  final StreamController<String> _translationController =
      StreamController<String>.broadcast();

  Stream<SupportedLanguage> get onLanguageChanged => _languageController.stream;
  Stream<String> get onTranslationUpdate => _translationController.stream;

  /// 현재 언어
  SupportedLanguage get currentLanguage => _config.language;

  /// 텍스트 방향
  TextDirection get textDirection {
    switch (_config.language) {
      case SupportedLanguage.arabic:
        return TextDirection.rtl;
      default:
        return TextDirection.ltr;
    }
  }

  /// 로케일
  Locale get locale {
    final langCode = _getLanguageCode(_config.language);
    return Locale(langCode, _config.regionCode);
  }

  /// 초기화
  Future<void> initialize({LocalizationConfig? config}) async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    if (config != null) {
      _config = config;
    } else {
      // 저장된 설정 로드
      await _loadSavedConfig();
    }

    // 번역 리소스 로드
    await _loadTranslations();

    // Intl 초기화
    await _initializeIntl();

    debugPrint('[Localization] Initialized: ${_config.language.name}');
  }

  Future<void> _loadSavedConfig() async {
    final savedLang = _prefs?.getString('preferred_language');
    final savedRegion = _prefs?.getString('preferred_region');

    if (savedLang != null) {
      final language = SupportedLanguage.values.firstWhere(
        (lang) => _getLanguageCode(lang) == savedLang,
        orElse: () => SupportedLanguage.english,
      );

      _config = LocalizationConfig(
        language: language,
        regionCode: savedRegion ?? 'US',
        autoDetectLanguage: false,
      );
    }
  }

  Future<void> _loadTranslations() async {
    // 기본 번역 로드
    await _loadBuiltInTranslations();

    // 사용자 정의 번역 로드
    await _loadCustomTranslations();
  }

  Future<void> _loadBuiltInTranslations() async {
    // 영어
    _addTranslationResource(const TranslationResource(
      languageCode: 'en',
      translations: {
        'common': {
          'ok': 'OK',
          'cancel': 'Cancel',
          'confirm': 'Confirm',
          'delete': 'Delete',
          'save': 'Save',
          'edit': 'Edit',
          'close': 'Close',
          'back': 'Back',
          'next': 'Next',
          'previous': 'Previous',
          'loading': 'Loading...',
          'error': 'Error',
          'success': 'Success',
          'warning': 'Warning',
          'info': 'Information',
        },
        'game': {
          'start': 'Start Game',
          'pause': 'Pause',
          'resume': 'Resume',
          'settings': 'Settings',
          'exit': 'Exit',
          'victory': 'Victory!',
          'defeat': 'Defeat',
          'score': 'Score',
          'level': 'Level',
          'time': 'Time',
        },
        'menu': {
          'title': 'Main Menu',
          'play': 'Play',
          'shop': 'Shop',
          'inventory': 'Inventory',
          'quests': 'Quests',
          'social': 'Social',
          'profile': 'Profile',
          'settings': 'Settings',
        },
      },
    ));

    // 한국어
    _addTranslationResource(const TranslationResource(
      languageCode: 'ko',
      translations: {
        'common': {
          'ok': '확인',
          'cancel': '취소',
          'confirm': '확인',
          'delete': '삭제',
          'save': '저장',
          'edit': '편집',
          'close': '닫기',
          'back': '뒤로',
          'next': '다음',
          'previous': '이전',
          'loading': '로딩 중...',
          'error': '오류',
          'success': '성공',
          'warning': '경고',
          'info': '정보',
        },
        'game': {
          'start': '게임 시작',
          'pause': '일시정지',
          'resume': '재개',
          'settings': '설정',
          'exit': '종료',
          'victory': '승리!',
          'defeat': '패배',
          'score': '점수',
          'level': '레벨',
          'time': '시간',
        },
        'menu': {
          'title': '메인 메뉴',
          'play': '플레이',
          'shop': '상점',
          'inventory': '인벤토리',
          'quests': '퀘스트',
          'social': '소셜',
          'profile': '프로필',
          'settings': '설정',
        },
      },
    ));

    // 일본어
    _addTranslationResource(const TranslationResource(
      languageCode: 'ja',
      translations: {
        'common': {
          'ok': 'OK',
          'cancel': 'キャンセル',
          'confirm': '確認',
          'delete': '削除',
          'save': '保存',
          'edit': '編集',
          'close': '閉じる',
          'back': '戻る',
          'next': '次へ',
          'previous': '前へ',
          'loading': '読み込み中...',
          'error': 'エラー',
          'success': '成功',
          'warning': '警告',
          'info': '情報',
        },
        'game': {
          'start': 'ゲーム開始',
          'pause': '一時停止',
          'resume': '再開',
          'settings': '設定',
          'exit': '終了',
          'victory': '勝利！',
          'defeat': '敗北',
          'score': 'スコア',
          'level': 'レベル',
          'time': '時間',
        },
        'menu': {
          'title': 'メインメニュー',
          'play': 'プレイ',
          'shop': 'ショップ',
          'inventory': 'インベントリ',
          'quests': 'クエスト',
          'social': 'ソーシャル',
          'profile': 'プロフィール',
          'settings': '設定',
        },
      },
    ));

    // 중국어 간체
    _addTranslationResource(const TranslationResource(
      languageCode: 'zh',
      translations: {
        'common': {
          'ok': '确定',
          'cancel': '取消',
          'confirm': '确认',
          'delete': '删除',
          'save': '保存',
          'edit': '编辑',
          'close': '关闭',
          'back': '返回',
          'next': '下一步',
          'previous': '上一步',
          'loading': '加载中...',
          'error': '错误',
          'success': '成功',
          'warning': '警告',
          'info': '信息',
        },
        'game': {
          'start': '开始游戏',
          'pause': '暂停',
          'resume': '继续',
          'settings': '设置',
          'exit': '退出',
          'victory': '胜利！',
          'defeat': '失败',
          'score': '分数',
          'level': '等级',
          'time': '时间',
        },
        'menu': {
          'title': '主菜单',
          'play': '开始',
          'shop': '商店',
          'inventory': '背包',
          'quests': '任务',
          'social': '社交',
          'profile': '个人资料',
          'settings': '设置',
        },
      },
    ));

    // 아랍어
    _addTranslationResource(const TranslationResource(
      languageCode: 'ar',
      translations: {
        'common': {
          'ok': 'موافق',
          'cancel': 'إلغاء',
          'confirm': 'تأكيد',
          'delete': 'حذف',
          'save': 'حفظ',
          'edit': 'تعديل',
          'close': 'إغلاق',
          'back': 'رجوع',
          'next': 'التالي',
          'previous': 'السابق',
          'loading': 'جاري التحميل...',
          'error': 'خطأ',
          'success': 'نجح',
          'warning': 'تحذير',
          'info': 'معلومات',
        },
        'game': {
          'start': 'بدء اللعبة',
          'pause': 'إيقاف مؤقت',
          'resume': 'استئناف',
          'settings': 'الإعدادات',
          'exit': 'خروج',
          'victory': 'انتصار!',
          'defeat': 'هزيمة',
          'score': 'النتيجة',
          'level': 'المستوى',
          'time': 'الوقت',
        },
        'menu': {
          'title': 'القائمة الرئيسية',
          'play': 'العب',
          'shop': 'المتجر',
          'inventory': 'المخزون',
          'quests': 'المهام',
          'social': 'اجتماعي',
          'profile': 'الملف الشخصي',
          'settings': 'الإعدادات',
        },
      },
    ));
  }

  Future<void> _loadCustomTranslations() async {
    final json = _prefs?.getString('custom_translations');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[Localization] Error loading custom: $e');
      }
    }
  }

  Future<void> _initializeIntl() async {
    final locale = this.locale;
    Intl.defaultLocale = locale.toString();
  }

  void _addTranslationResource(TranslationResource resource) {
    _resources[resource.languageCode] = resource;

    // TranslationEntry로 변환
    for (final categoryEntry in resource.translations.entries) {
      final category = categoryEntry.key;
      final categoryTranslations = categoryEntry.value as Map<String, dynamic>;

      for (final entry in categoryTranslations.entries) {
        final key = entry.key;
        final fullKey = '$category.$key';

        _translations[fullKey] = TranslationEntry(
          key: fullKey,
          translations: {resource.languageCode: entry.value as String},
          category: category,
        );
      }
    }
  }

  /// 언어 변경
  Future<void> setLanguage(SupportedLanguage language) async {
    if (_config.language == language) return;

    _config = LocalizationConfig(
      language: language,
      regionCode: _config.regionCode,
      timeZone: _config.timeZone,
      use24HourFormat: _config.use24HourFormat,
      currencyCode: _config.currencyCode,
      numberFormat: _config.numberFormat,
      dateFormat: _config.dateFormat,
      autoDetectLanguage: false,
    );

    // 저장
    await _prefs?.setString('preferred_language', _getLanguageCode(language));

    // Intl 재초기화
    await _initializeIntl();

    _languageController.add(language);

    debugPrint('[Localization] Language changed to: ${language.name}');
  }

  /// 지역 변경
  Future<void> setRegion(String regionCode) async {
    _config = LocalizationConfig(
      language: _config.language,
      regionCode: regionCode,
      timeZone: _config.timeZone,
      use24HourFormat: _config.use24HourFormat,
      currencyCode: _config.currencyCode,
      numberFormat: _config.numberFormat,
      dateFormat: _config.dateFormat,
      autoDetectLanguage: _config.autoDetectLanguage,
    );

    await _prefs?.setString('preferred_region', regionCode);

    await _initializeIntl();
  }

  /// 번역 조회
  String translate(
    String key, {
    Map<String, dynamic>? parameters,
    String? context,
    int? quantity,
    String? gender,
  }) {
    final languageCode = _getLanguageCode(_config.language);

    // 번역 엔트리 조회
    final entry = _translations[key];
    if (entry == null) {
      debugPrint('[Localization] Translation not found: $key');
      return key;
    }

    // 언어별 번역 조회
    var translation = entry.translations[languageCode];

    // 대체 언어 (영어)
    if (translation == null && languageCode != 'en') {
      translation = entry.translations['en'];
    }

    if (translation == null) {
      return key;
    }

    // 복수형 처리
    if (quantity != null && entry.hasPlurals) {
      translation = _getPluralForm(translation, quantity, languageCode);
    }

    // 파라미터 치환
    if (parameters != null && parameters.isNotEmpty) {
      translation = _replaceParameters(translation, parameters);
    }

    return translation;
  }

  /// 복수형 처리
  String _getPluralForm(String translation, int quantity, String languageCode) {
    // 간단한 복수형 처리
    if (quantity == 1) {
      return translation.replaceAll('|', '').split('^')[0];
    } else {
      final parts = translation.split('|');
      if (parts.length > 1) {
        return parts[1].replaceAll('|', '');
      }
      return translation;
    }
  }

  /// 파라미터 치환
  String _replaceParameters(String translation, Map<String, dynamic> parameters) {
    var result = translation;

    for (final entry in parameters.entries) {
      final placeholder = '{${entry.key}}';
      result = result.replaceAll(placeholder, entry.value.toString());
    }

    return result;
  }

  /// 날짜 포맷
  String formatDate(DateTime date, {String? pattern}) {
    final locale = this.locale;

    if (pattern != null) {
      return DateFormat(pattern, locale.toString()).format(date);
    }

    switch (_config.dateFormat) {
      case 'ymd':
        return DateFormat.yMd(locale.toString()).format(date);
      case 'dmy':
        return DateFormat('dd/MM/yyyy').format(date);
      case 'mdy':
        return DateFormat('MM/dd/yyyy').format(date);
      default:
        return DateFormat.yMd(locale.toString()).format(date);
    }
  }

  /// 시간 포맷
  String formatTime(DateTime time) {
    final locale = this.locale;

    if (_config.use24HourFormat) {
      return DateFormat('HH:mm', locale.toString()).format(time);
    } else {
      return DateFormat('hh:mm a', locale.toString()).format(time);
    }
  }

  /// 숫자 포맷
  String formatNumber(num number, {int? decimalDigits}) {
    final locale = this.locale;

    if (decimalDigits != null) {
      return NumberFormat decimalPatternDigits(decimalDigits: decimalDigits)
          .format(number);
    }

    return NumberFormat.decimalPattern(locale.toString()).format(number);
  }

  /// 통화 포맷
  String formatCurrency(num amount, {String? currencyCode}) {
    final code = currencyCode ?? _config.currencyCode;
    final locale = this.locale;

    return NumberFormat.currency(
      locale: locale.toString(),
      code: code,
    ).format(amount);
  }

  /// 퍼센트 포맷
  String formatPercent(double value, {int decimalDigits = 1}) {
    final locale = this.locale;

    return NumberFormat.percentPattern(
      locale.toString(),
      decimalDigits: decimalDigits,
    ).format(value);
  }

  /// 상대적 시간
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return translate('time.just_now');
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return translate('time.minutes_ago', parameters: {'count': minutes});
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return translate('time.hours_ago', parameters: {'count': hours});
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return translate('time.days_ago', parameters: {'count': days});
    } else {
      return formatDate(dateTime);
    }
  }

  /// 번역 추가 (런타임)
  Future<void> addTranslation({
    required String key,
    required String translation,
    required String category,
    String? context,
  }) async {
    final languageCode = _getLanguageCode(_config.language);
    final fullKey = '$category.$key';

    final existing = _translations[fullKey];
    final translations = existing?.translations ?? {};

    _translations[fullKey] = TranslationEntry(
      key: fullKey,
      translations: {...translations, languageCode: translation},
      category: category,
      context: context,
    );

    // 커스텀 번역 저장
    await _saveCustomTranslations();

    _translationController.add(fullKey);
  }

  /// 번역 내보내기
  Map<String, dynamic> exportTranslations({String? languageCode}) {
    final result = <String, dynamic>{};

    for (final entry in _translations.values) {
      final key = entry.key;

      if (languageCode != null) {
        final translation = entry.translations[languageCode];
        if (translation != null) {
          result[key] = translation;
        }
      } else {
        result[key] = entry.translations;
      }
    }

    return result;
  }

  /// 번역 가져오기
  Future<void> importTranslations({
    required String languageCode,
    required Map<String, String> translations,
  }) async {
    for (final entry in translations.entries) {
      final parts = entry.key.split('.');
      if (parts.length >= 2) {
        final category = parts[0];
        final key = parts.sublist(1).join('.');

        _translations[entry.key] = TranslationEntry(
          key: entry.key,
          translations: {languageCode: entry.value},
          category: category,
        );
      }
    }

    await _saveCustomTranslations();
  }

  /// 지원되는 언어 목록
  List<SupportedLanguage> getSupportedLanguages() {
    return SupportedLanguage.values;
  }

  /// 언어 코드 변환
  String _getLanguageCode(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.english:
        return 'en';
      case SupportedLanguage.korean:
        return 'ko';
      case SupportedLanguage.japanese:
        return 'ja';
      case SupportedLanguage.chineseSimplified:
        return 'zh';
      case SupportedLanguage.chineseTraditional:
        return 'zh_TW';
      case SupportedLanguage.spanish:
        return 'es';
      case SupportedLanguage.french:
        return 'fr';
      case SupportedLanguage.german:
        return 'de';
      case SupportedLanguage.portuguese:
        return 'pt';
      case SupportedLanguage.russian:
        return 'ru';
      case SupportedLanguage.arabic:
        return 'ar';
      case SupportedLanguage.hindi:
        return 'hi';
      case SupportedLanguage.thai:
        return 'th';
      case SupportedLanguage.vietnamese:
        return 'vi';
      case SupportedLanguage.indonesian:
        return 'id';
    }
  }

  Future<void> _saveCustomTranslations() async {
    // 커스텀 번역 저장 로직
  }

  void dispose() {
    _languageController.close();
    _translationController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// 모드 타입
enum ModType {
  texture,      // 텍스처
  sound,        // 사운드
  gameplay,     // 게임플레이
  ui,           // UI
  language,     // 언어
  totalConversion, // 토탈 컨버전
}

/// 모드 상태
enum ModStatus {
  disabled,     // 비활성화
  enabled,      // 활성화
  loading,      // 로딩 중
  error,        // 에러
}

/// 지원 언어
enum GameLanguage {
  english,
  korean,
  japanese,
  chinese,
  spanish,
  french,
  german,
  russian,
  portuguese,
  arabic,
}

/// 텍스트 방향
enum TextDirection {
  ltr,          // 왼쪽에서 오른쪽
  rtl,          // 오른쪽에서 왼쪽
}

/// 번역 키
class TranslationKey {
  final String key;
  final String context;
  final Map<GameLanguage, String> translations;

  const TranslationKey({
    required this.key,
    required this.context,
    required this.translations,
  });
}

/// 모드 메타데이터
class ModMetadata {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final ModType type;
  final List<String> dependencies;
  final String? thumbnailUrl;
  final int fileSize;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ModMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.type,
    this.dependencies = const [],
    this.thumbnailUrl,
    required this.fileSize,
    required this.createdAt,
    this.updatedAt,
  });
}

/// 모드
class GameMod {
  final ModMetadata metadata;
  final ModStatus status;
  final String? errorMessage;
  final bool isCompatible;
  final List<String> conflicts;
  final DateTime? installedAt;

  const GameMod({
    required this.metadata,
    required this.status,
    this.errorMessage,
    this.isCompatible = true,
    this.conflicts = const [],
    this.installedAt,
  });
}

/// 로케일 설정
class LocaleSettings {
  final GameLanguage language;
  final TextDirection textDirection;
  final String? customFont;
  final Map<String, String> customFormats;

  const LocaleSettings({
    required this.language,
    required this.textDirection,
    this.customFont,
    this.customFormats = const {},
  });
}

/// 모딩 및 i18n 관리자
class ModdingI18nManager {
  static final ModdingI18nManager _instance = ModdingI18nManager._();
  static ModdingI18nManager get instance => _instance;

  ModdingI18nManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, GameMod> _mods = {};
  final Map<String, TranslationKey> _translations = {};
  final Map<GameLanguage, LocaleSettings> _localeSettings = {};

  GameLanguage _currentLanguage = GameLanguage.english;
  String? _modsDirectory;

  final StreamController<GameMod> _modController =
      StreamController<GameMod>.broadcast();
  final StreamController<LocaleSettings> _localeController =
      StreamController<LocaleSettings>.broadcast();

  Stream<GameMod> get onModUpdate => _modController.stream;
  Stream<LocaleSettings> get onLocaleChange => _localeController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 모드 디렉토리 설정
    await _setupModsDirectory();

    // 번역 로드
    await _loadTranslations();

    // 로케일 설정 로드
    await _loadLocaleSettings();

    // 모드 로드
    await _loadMods();

    debugPrint('[ModdingI18n] Initialized');
  }

  Future<void> _setupModsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _modsDirectory = '${appDir.path}/mods';

    final modsDir = Directory(_modsDirectory!);
    if (!await modsDir.exists()) {
      await modsDir.create(recursive: true);
    }
  }

  Future<void> _loadTranslations() async {
    // 기본 번역
    _translations['welcome'] = const TranslationKey(
      key: 'welcome',
      context: 'greeting',
      translations: {
        GameLanguage.english: 'Welcome',
        GameLanguage.korean: '환영합니다',
        GameLanguage.japanese: 'ようこそ',
        GameLanguage.chinese: '欢迎',
        GameLanguage.spanish: 'Bienvenido',
        GameLanguage.french: 'Bienvenue',
        GameLanguage.german: 'Willkommen',
        GameLanguage.russian: 'Добро пожаловать',
        GameLanguage.portuguese: 'Bem-vindo',
        GameLanguage.arabic: 'مرحبا',
      },
    );

    _translations['guild_war'] = const TranslationKey(
      key: 'guild_war',
      context: 'feature',
      translations: {
        GameLanguage.english: 'Guild War',
        GameLanguage.korean: '길드전',
        GameLanguage.japanese: 'ギルド戦',
        GameLanguage.chinese: '公会战',
        GameLanguage.spanish: 'Guerra de gremios',
        GameLanguage.french: 'Guerre de guildes',
        GameLanguage.german: 'Gildenkrieg',
        GameLanguage.russian: 'Война гильдий',
        GameLanguage.portuguese: 'Guerra de guildas',
        GameLanguage.arabic: 'حرب النقابات',
      },
    );

    _translations['settings'] = const TranslationKey(
      key: 'settings',
      context: 'menu',
      translations: {
        GameLanguage.english: 'Settings',
        GameLanguage.korean: '설정',
        GameLanguage.japanese: '設定',
        GameLanguage.chinese: '设置',
        GameLanguage.spanish: 'Configuración',
        GameLanguage.french: 'Paramètres',
        GameLanguage.german: 'Einstellungen',
        GameLanguage.russian: 'Настройки',
        GameLanguage.portuguese: 'Configurações',
        GameLanguage.arabic: 'الإعدادات',
      },
    );
  }

  Future<void> _loadLocaleSettings() async {
    // 기본 로케일 설정
    _localeSettings[GameLanguage.english] = const LocaleSettings(
      language: GameLanguage.english,
      textDirection: TextDirection.ltr,
    );

    _localeSettings[GameLanguage.korean] = const LocaleSettings(
      language: GameLanguage.korean,
      textDirection: TextDirection.ltr,
    );

    _localeSettings[GameLanguage.japanese] = const LocaleSettings(
      language: GameLanguage.japanese,
      textDirection: TextDirection.ltr,
    );

    _localeSettings[GameLanguage.chinese] = const LocaleSettings(
      language: GameLanguage.chinese,
      textDirection: TextDirection.ltr,
    );

    _localeSettings[GameLanguage.arabic] = const LocaleSettings(
      language: GameLanguage.arabic,
      textDirection: TextDirection.rtl,
    );

    // 현재 언어 로드
    final savedLanguage = _prefs?.getString('language');
    if (savedLanguage != null) {
      _currentLanguage = GameLanguage.values.firstWhere(
        (lang) => lang.name == savedLanguage,
        orElse: () => GameLanguage.english,
      );
    }
  }

  Future<void> _loadMods() async {
    // 설치된 모드 로드 (시뮬레이션)
    _mods['example_mod'] = GameMod(
      metadata: const ModMetadata(
        id: 'example_mod',
        name: 'Example Mod',
        description: 'An example mod',
        author: 'Dev Team',
        version: '1.0.0',
        type: ModType.gameplay,
        fileSize: 1024 * 1024, // 1MB
        createdAt: null,
      ),
      status: ModStatus.enabled,
      isCompatible: true,
      installedAt: DateTime.now(),
    );
  }

  /// 모드 설치
  Future<GameMod> installMod({
    required String modFile,
    required ModMetadata metadata,
  }) async {
    final mod = GameMod(
      metadata: metadata,
      status: ModStatus.loading,
      isCompatible: true,
      installedAt: DateTime.now(),
    );

    _mods[metadata.id] = mod;
    _modController.add(mod);

    try {
      // 모드 파일 복사 (시뮬레이션)
      await Future.delayed(const Duration(seconds: 2));

      final installed = GameMod(
        metadata: metadata,
        status: ModStatus.enabled,
        isCompatible: true,
        installedAt: DateTime.now(),
      );

      _mods[metadata.id] = installed;
      _modController.add(installed);

      debugPrint('[ModdingI18n] Mod installed: ${metadata.name}');

      return installed;
    } catch (e) {
      final failed = GameMod(
        metadata: metadata,
        status: ModStatus.error,
        errorMessage: e.toString(),
        isCompatible: true,
        installedAt: DateTime.now(),
      );

      _mods[metadata.id] = failed;
      _modController.add(failed);

      debugPrint('[ModdingI18n] Mod install failed: $e');

      return failed;
    }
  }

  /// 모드 제거
  Future<void> uninstallMod(String modId) async {
    final mod = _mods[modId];
    if (mod == null) return;

    _mods.remove(modId);
    _modController.add(mod);

    debugPrint('[ModdingI18n] Mod uninstalled: $modId');
  }

  /// 모드 활성화/비활성화
  Future<void> toggleMod(String modId, bool enabled) async {
    final mod = _mods[modId];
    if (mod == null) return;

    final updated = GameMod(
      metadata: mod.metadata,
      status: enabled ? ModStatus.enabled : ModStatus.disabled,
      errorMessage: mod.errorMessage,
      isCompatible: mod.isCompatible,
      conflicts: mod.conflicts,
      installedAt: mod.installedAt,
    );

    _mods[modId] = updated;
    _modController.add(updated);

    debugPrint('[ModdingI18n] Mod ${enabled ? "enabled" : "disabled"}: $modId');
  }

  /// 번역 추가
  void addTranslation(TranslationKey translation) {
    _translations[translation.key] = translation;

    debugPrint('[ModdingI18n] Translation added: ${translation.key}');
  }

  /// 번역 조회
  String translate(String key, {Map<String, dynamic>? args}) {
    final translation = _translations[key];
    if (translation == null) return key;

    final translated = translation.translations[_currentLanguage] ??
        translation.translations[GameLanguage.english] ??
        key;

    // 파라미터 치환
    if (args != null) {
      var result = translated;
      args.forEach((argKey, value) {
        result = result.replaceAll('{$argKey}', value.toString());
      });
      return result;
    }

    return translated;
  }

  /// 언어 변경
  Future<void> setLanguage(GameLanguage language) async {
    _currentLanguage = language;

    final settings = _localeSettings[language];
    if (settings != null) {
      _localeController.add(settings);
    }

    await _prefs?.setString('language', language.name);

    debugPrint('[ModdingI18n] Language changed: ${language.name}');
  }

  /// 현재 언어
  GameLanguage get currentLanguage => _currentLanguage;

  /// 현재 로케일 설정
  LocaleSettings? get currentLocaleSettings => _localeSettings[_currentLanguage];

  /// 텍스트 방향
  TextDirection get textDirection =>
      _localeSettings[_currentLanguage]?.textDirection ??
      TextDirection.ltr;

  /// 모드 조회
  GameMod? getMod(String modId) {
    return _mods[modId];
  }

  /// 모든 모드 조회
  List<GameMod> getMods({ModType? type, ModStatus? status}) {
    var mods = _mods.values.toList();

    if (type != null) {
      mods = mods.where((m) => m.metadata.type == type).toList();
    }

    if (status != null) {
      mods = mods.where((m) => m.status == status).toList();
    }

    return mods;
  }

  /// 활성화된 모드
  List<GameMod> getEnabledMods() {
    return _mods.values
        .where((m) => m.status == ModStatus.enabled)
        .toList();
  }

  /// 모드 의존성 체크
  List<String> checkDependencies(String modId) {
    final mod = _mods[modId];
    if (mod == null) return [];

    final missingDependencies = <String>[];

    for (final dep in mod.metadata.dependencies) {
      if (!_mods.containsKey(dep)) {
        missingDependencies.add(dep);
      }
    }

    return missingDependencies;
  }

  /// 모드 충돌 체크
  List<String> checkConflicts(String modId) {
    final mod = _mods[modId];
    if (mod == null) return [];

    return mod.conflicts;
  }

  /// 번역 내보내기
  String exportTranslations({GameLanguage? language}) {
    final data = <String, dynamic>{};

    for (final entry in _translations.entries) {
      final key = entry.key;
      final translation = entry.value;

      if (language != null) {
        data[key] = translation.translations[language];
      } else {
        data[key] = translation.translations.map((lang, text) =>
            MapEntry(lang.name, text));
      }
    }

    return jsonEncode(data);
  }

  /// 번역 가져오기
  Future<void> importTranslations(String jsonData) async {
    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    for (final entry in data.entries) {
      final key = entry.key;
      final translations = entry.value as Map<String, dynamic>;

      final translationMap = <GameLanguage, String>{};

      translations.forEach((langCode, text) {
        final language = GameLanguage.values.firstWhere(
          (l) => l.name == langCode,
          orElse: () => GameLanguage.english,
        );
        translationMap[language] = text as String;
      });

      _translations[key] = TranslationKey(
        key: key,
        context: 'imported',
        translations: translationMap,
      );
    }

    debugPrint('[ModdingI18n] Translations imported');
  }

  /// 사용자 정의 폰트 설정
  Future<void> setCustomFont(String fontPath) async {
    final current = _localeSettings[_currentLanguage];
    if (current == null) return;

    final updated = LocaleSettings(
      language: current.language,
      textDirection: current.textDirection,
      customFont: fontPath,
      customFormats: current.customFormats,
    );

    _localeSettings[_currentLanguage] = updated;
    _localeController.add(updated);

    await _prefs?.setString('custom_font_${_currentLanguage.name}', fontPath);

    debugPrint('[ModdingI18n] Custom font set: $fontPath');
  }

  /// 숫자 형식화
  String formatNumber(double number, {String? pattern}) {
    final settings = _localeSettings[_currentLanguage];

    // 사용자 정의 형식 또는 기본 형식
    final formatPattern = pattern ??
        settings?.customFormats['number'] ??
        '#,##0.###';

    // 간단한 형식화 (실제로는 intl 패키지 사용)
    if (formatPattern.contains('#,##0')) {
      final parts = formatPattern.split('.');
      final integerPart = number.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},');

      if (parts.length > 1) {
        final decimals = parts[1].replaceAll('#', '').length;
        final decimalStr = number.toStringAsFixed(decimals).split('.')[1];
        return '$integerPart.$decimalStr';
      }

      return integerPart;
    }

    return number.toString();
  }

  /// 날짜 형식화
  String formatDate(DateTime date, {String? pattern}) {
    final settings = _localeSettings[_currentLanguage];
    final formatPattern = pattern ??
        settings?.customFormats['date'] ??
        'yyyy-MM-dd';

    // 간단한 형식화
    return formatPattern
        .replaceAll('yyyy', date.year.toString())
        .replaceAll('MM', date.month.toString().padLeft(2, '0'))
        .replaceAll('dd', date.day.toString().padLeft(2, '0'));
  }

  /// 통화 형식화
  String formatCurrency(double amount, {String? currencyCode}) {
    final code = currencyCode ?? _getCurrencyCode(_currentLanguage);

    final formatted = formatNumber(amount);

    switch (_currentLanguage) {
      case GameLanguage.english:
        return '$code$formatted';
      case GameLanguage.korean:
        return '$formatted$code';
      case GameLanguage.japanese:
        return '¥$formatted';
      default:
        return '$code $formatted';
    }
  }

  String _getCurrencyCode(GameLanguage language) {
    switch (language) {
      case GameLanguage.english:
        return '\$';
      case GameLanguage.korean:
        return '₩';
      case GameLanguage.japanese:
        return '¥';
      case GameLanguage.chinese:
        return '¥';
      case GameLanguage.euro:
        return '€';
      default:
        return '\$';
    }
  }

  void dispose() {
    _modController.close();
    _localeController.close();
  }
}

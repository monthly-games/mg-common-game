import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages
enum GameLanguage {
  en,   // English
  ko,   // Korean
  ja,   // Japanese
  zhCN, // Chinese Simplified
  zhTW, // Chinese Traditional
  es,   // Spanish
  pt,   // Portuguese
  fr,   // French
  de,   // German
  ru,   // Russian
  id,   // Indonesian
  th,   // Thai
  vi,   // Vietnamese
  ar,   // Arabic
  tr,   // Turkish
}

/// Language metadata
class LanguageInfo {
  final GameLanguage language;
  final String code;
  final String name;
  final String nativeName;
  final bool rtl;

  const LanguageInfo({
    required this.language,
    required this.code,
    required this.name,
    required this.nativeName,
    this.rtl = false,
  });

  Locale get locale {
    switch (language) {
      case GameLanguage.zhCN:
        return const Locale('zh', 'CN');
      case GameLanguage.zhTW:
        return const Locale('zh', 'TW');
      default:
        return Locale(code);
    }
  }

  static const Map<GameLanguage, LanguageInfo> all = {
    GameLanguage.en: LanguageInfo(
      language: GameLanguage.en,
      code: 'en',
      name: 'English',
      nativeName: 'English',
    ),
    GameLanguage.ko: LanguageInfo(
      language: GameLanguage.ko,
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
    ),
    GameLanguage.ja: LanguageInfo(
      language: GameLanguage.ja,
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
    ),
    GameLanguage.zhCN: LanguageInfo(
      language: GameLanguage.zhCN,
      code: 'zh',
      name: 'Chinese (Simplified)',
      nativeName: '简体中文',
    ),
    GameLanguage.zhTW: LanguageInfo(
      language: GameLanguage.zhTW,
      code: 'zh',
      name: 'Chinese (Traditional)',
      nativeName: '繁體中文',
    ),
    GameLanguage.es: LanguageInfo(
      language: GameLanguage.es,
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
    ),
    GameLanguage.pt: LanguageInfo(
      language: GameLanguage.pt,
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
    ),
    GameLanguage.fr: LanguageInfo(
      language: GameLanguage.fr,
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
    ),
    GameLanguage.de: LanguageInfo(
      language: GameLanguage.de,
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
    ),
    GameLanguage.ru: LanguageInfo(
      language: GameLanguage.ru,
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
    ),
    GameLanguage.id: LanguageInfo(
      language: GameLanguage.id,
      code: 'id',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
    ),
    GameLanguage.th: LanguageInfo(
      language: GameLanguage.th,
      code: 'th',
      name: 'Thai',
      nativeName: 'ภาษาไทย',
    ),
    GameLanguage.vi: LanguageInfo(
      language: GameLanguage.vi,
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
    ),
    GameLanguage.ar: LanguageInfo(
      language: GameLanguage.ar,
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      rtl: true,
    ),
    GameLanguage.tr: LanguageInfo(
      language: GameLanguage.tr,
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
    ),
  };

  static LanguageInfo get(GameLanguage lang) => all[lang]!;
}

/// Localization manager for multi-language support
class LocalizationManager extends ChangeNotifier {
  static LocalizationManager? _instance;
  static LocalizationManager get instance => _instance ??= LocalizationManager._();

  LocalizationManager._();

  static const String _languageKey = 'app_language';

  SharedPreferences? _prefs;
  GameLanguage _currentLanguage = GameLanguage.en;
  GameLanguage _fallbackLanguage = GameLanguage.en;

  final Map<GameLanguage, Map<String, String>> _translations = {};
  final List<GameLanguage> _supportedLanguages = [];

  bool _isInitialized = false;

  /// Current language
  GameLanguage get currentLanguage => _currentLanguage;

  /// Current language info
  LanguageInfo get currentLanguageInfo => LanguageInfo.get(_currentLanguage);

  /// Current locale
  Locale get currentLocale => currentLanguageInfo.locale;

  /// Is RTL language
  bool get isRtl => currentLanguageInfo.rtl;

  /// Supported languages
  List<GameLanguage> get supportedLanguages => List.unmodifiable(_supportedLanguages);

  /// Is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the manager
  Future<void> initialize({
    required List<GameLanguage> supportedLanguages,
    GameLanguage fallbackLanguage = GameLanguage.en,
    String assetsPath = 'assets/i18n',
  }) async {
    _prefs = await SharedPreferences.getInstance();
    _supportedLanguages.clear();
    _supportedLanguages.addAll(supportedLanguages);
    _fallbackLanguage = fallbackLanguage;

    // Load saved language or detect system language
    final savedLanguage = _prefs?.getString(_languageKey);
    if (savedLanguage != null) {
      try {
        _currentLanguage = GameLanguage.values.firstWhere(
          (l) => l.name == savedLanguage,
          orElse: () => _fallbackLanguage,
        );
      } catch (e) {
        _currentLanguage = _fallbackLanguage;
      }
    } else {
      _currentLanguage = _detectSystemLanguage();
    }

    // Load translations for current and fallback languages
    await _loadTranslations(_currentLanguage, assetsPath);
    if (_currentLanguage != _fallbackLanguage) {
      await _loadTranslations(_fallbackLanguage, assetsPath);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Detect system language
  GameLanguage _detectSystemLanguage() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = systemLocale.languageCode;
    final countryCode = systemLocale.countryCode;

    // Handle Chinese variants
    if (languageCode == 'zh') {
      if (countryCode == 'TW' || countryCode == 'HK') {
        return _supportedLanguages.contains(GameLanguage.zhTW)
            ? GameLanguage.zhTW
            : _fallbackLanguage;
      }
      return _supportedLanguages.contains(GameLanguage.zhCN)
          ? GameLanguage.zhCN
          : _fallbackLanguage;
    }

    // Find matching language
    for (final lang in _supportedLanguages) {
      if (LanguageInfo.get(lang).code == languageCode) {
        return lang;
      }
    }

    return _fallbackLanguage;
  }

  /// Load translations from JSON file
  Future<void> _loadTranslations(GameLanguage language, String assetsPath) async {
    if (_translations.containsKey(language)) return;

    try {
      final info = LanguageInfo.get(language);
      String fileName;

      switch (language) {
        case GameLanguage.zhCN:
          fileName = 'zh_CN.json';
          break;
        case GameLanguage.zhTW:
          fileName = 'zh_TW.json';
          break;
        default:
          fileName = '${info.code}.json';
      }

      final jsonString = await rootBundle.loadString('$assetsPath/$fileName');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _translations[language] = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      _translations[language] = {};
      debugPrint('Failed to load translations for $language: $e');
    }
  }

  /// Change language
  Future<void> setLanguage(GameLanguage language) async {
    if (!_supportedLanguages.contains(language)) return;
    if (language == _currentLanguage) return;

    // Load translations if not already loaded
    await _loadTranslations(language, 'assets/i18n');

    _currentLanguage = language;
    await _prefs?.setString(_languageKey, language.name);

    notifyListeners();
  }

  /// Get translated string
  String translate(String key, [Map<String, dynamic>? params]) {
    String? text = _translations[_currentLanguage]?[key];

    // Fallback to default language
    if (text == null && _currentLanguage != _fallbackLanguage) {
      text = _translations[_fallbackLanguage]?[key];
    }

    // Return key if not found
    text ??= key;

    // Replace parameters
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text!.replaceAll('{$paramKey}', value.toString());
      });
    }

    return text!;
  }

  /// Shorthand for translate
  String tr(String key, [Map<String, dynamic>? params]) => translate(key, params);

  /// Get plural translation
  String plural(String key, int count, [Map<String, dynamic>? params]) {
    final pluralParams = {'count': count, ...?params};

    if (count == 0) {
      final zeroKey = '${key}_zero';
      if (_hasKey(zeroKey)) {
        return translate(zeroKey, pluralParams);
      }
    } else if (count == 1) {
      final oneKey = '${key}_one';
      if (_hasKey(oneKey)) {
        return translate(oneKey, pluralParams);
      }
    }

    final manyKey = '${key}_many';
    if (_hasKey(manyKey)) {
      return translate(manyKey, pluralParams);
    }

    return translate(key, pluralParams);
  }

  /// Check if key exists
  bool _hasKey(String key) {
    return _translations[_currentLanguage]?.containsKey(key) == true ||
        _translations[_fallbackLanguage]?.containsKey(key) == true;
  }

  /// Check if key exists (public)
  bool hasKey(String key) => _hasKey(key);

  /// Get all translations for current language
  Map<String, String> get allTranslations =>
      Map.unmodifiable(_translations[_currentLanguage] ?? {});

  /// Preload additional languages
  Future<void> preloadLanguages(List<GameLanguage> languages) async {
    for (final language in languages) {
      if (!_translations.containsKey(language)) {
        await _loadTranslations(language, 'assets/i18n');
      }
    }
  }

  /// Clear cached translations (except current)
  void clearCache() {
    final currentTranslations = _translations[_currentLanguage];
    final fallbackTranslations = _translations[_fallbackLanguage];

    _translations.clear();

    if (currentTranslations != null) {
      _translations[_currentLanguage] = currentTranslations;
    }
    if (fallbackTranslations != null && _currentLanguage != _fallbackLanguage) {
      _translations[_fallbackLanguage] = fallbackTranslations;
    }
  }

  /// Add translations programmatically
  void addTranslations(GameLanguage language, Map<String, String> translations) {
    _translations[language] ??= {};
    _translations[language]!.addAll(translations);
    notifyListeners();
  }

  /// Reset to system language
  Future<void> resetToSystemLanguage() async {
    await _prefs?.remove(_languageKey);
    final systemLang = _detectSystemLanguage();
    await setLanguage(systemLang);
  }
}

/// Shortcut accessor
LocalizationManager get localization => LocalizationManager.instance;

/// Extension for easy access
extension LocalizationExtension on String {
  String get tr => LocalizationManager.instance.translate(this);

  String trParams(Map<String, dynamic> params) =>
      LocalizationManager.instance.translate(this, params);

  String trPlural(int count, [Map<String, dynamic>? params]) =>
      LocalizationManager.instance.plural(this, count, params);
}

/// Localization delegate for MaterialApp
class GameLocalizationsDelegate extends LocalizationsDelegate<LocalizationManager> {
  const GameLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return LocalizationManager.instance.supportedLanguages.any((lang) {
      final info = LanguageInfo.get(lang);
      return info.code == locale.languageCode;
    });
  }

  @override
  Future<LocalizationManager> load(Locale locale) async {
    return LocalizationManager.instance;
  }

  @override
  bool shouldReload(GameLocalizationsDelegate old) => false;
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 모드
enum ThemeMode {
  light,
  dark,
  system,
}

/// 테마 색상
class AppColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onError;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onError,
  });

  /// 라이트 테마
  static const AppColors light = AppColors(
    primary: Color(0xFF6366F1), // Indigo 500
    secondary: Color(0xFFEC4899), // Pink 500
    accent: Color(0xFFF59E0B), // Amber 500
    background: Color(0xFFFAFAFA), // Gray 50
    surface: Color(0xFFFFFFFF), // White
    error: Color(0xFFEF4444), // Red 500
    success: Color(0xFF10B981), // Emerald 500
    warning: Color(0xFFF59E0B), // Amber 500
    info: Color(0xFF3B82F6), // Blue 500
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF18181B), // Gray 900
    onSurface: Color(0xFF18181B),
    onError: Color(0xFFFFFFFF),
  );

  /// 다크 테마
  static const AppColors dark = AppColors(
    primary: Color(0xFF818CF8), // Indigo 400
    secondary: Color(0xFFF472B6), // Pink 400
    accent: Color(0xFFFBBF24), // Amber 400
    background: Color(0xFF0F0F11), // Gray 950
    surface: Color(0xFF18181B), // Gray 900
    error: Color(0xFFF87171), // Red 400
    success: Color(0xFF34D399), // Emerald 400
    warning: Color(0xFFFBBF24), // Amber 400
    info: Color(0xFF60A5FA), // Blue 400
    onPrimary: Color(0xFF18181B),
    onSecondary: Color(0xFF18181B),
    onBackground: Color(0xFFFAFAFA),
    onSurface: Color(0xFFFAFAFA),
    onError: Color(0xFF18181B),
  );
}

/// 테마 데이터
class AppThemeData {
  final AppColors colors;
  final String fontFamily;
  final double borderRadius;
  final double iconSize;
  final EdgeInsets spacing;

  const AppThemeData({
    required this.colors,
    this.fontFamily = 'Pretendard',
    this.borderRadius = 12.0,
    this.iconSize = 24.0,
    this.spacing = const EdgeInsets.all(16.0),
  });

  /// 라이트 테마 데이터
  static const AppThemeData lightTheme = AppThemeData(
    colors: AppColors.light,
  );

  /// 다크 테마 데이터
  static const AppThemeData darkTheme = AppThemeData(
    colors: AppColors.dark,
  );

  /// Material ThemeData 변환
  ThemeData toMaterialTheme() {
    final isDark = colors == AppColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        error: colors.error,
        onError: colors.onError,
        background: colors.background,
        onBackground: colors.onBackground,
        surface: colors.surface,
        onSurface: colors.onSurface,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.onBackground.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.onBackground.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          color: colors.onBackground.withOpacity(0.5),
          fontFamily: fontFamily,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: colors.onBackground.withOpacity(0.7),
          fontFamily: fontFamily,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.onBackground,
          fontFamily: fontFamily,
        ),
      ),

      // Scaffold Theme
      scaffoldBackgroundColor: colors.background,

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colors.onBackground.withOpacity(0.1),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// 테마 매니저
class ThemeManager {
  static final ThemeManager _instance = ThemeManager._();
  static ThemeManager get instance => _instance;

  ThemeManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  // ============================================
  // Getters
  // ============================================
  ThemeMode get themeMode => _themeMode;
  Stream<ThemeMode> get onThemeChanged => _themeController.stream;

  /// 현재 Material ThemeMode 가져오기
  ::ThemeMode get currentMaterialThemeMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return ::ThemeMode.light;
      case ThemeMode.dark:
        return ::ThemeMode.dark;
      case ThemeMode.system:
        return ::ThemeMode.system;
    }
  }

  /// 다크 모드인지 확인
  bool isDarkMode(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  /// 현재 테마 데이터 가져오기
  AppThemeData getCurrentTheme(BuildContext context) {
    return isDarkMode(context) ? AppThemeData.darkTheme : AppThemeData.lightTheme;
  }

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 저장된 테마 모드 로드
    final savedMode = _prefs!.getInt('theme_mode');
    if (savedMode != null) {
      _themeMode = ThemeMode.values[savedMode];
    }
  }

  // ============================================
  // 테마 관리
  // ============================================

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;

      // 설정 저장
      await _prefs!.setInt('theme_mode', mode.index);

      // 알림
      _themeController.add(mode);

      debugPrint('[Theme] Theme mode changed: $mode');
    }
  }

  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }

  void toggleTheme() {
    final newMode = isDarkMode(
      WidgetsBinding.instance.platformDispatcher.dispatchToPlatform
    ) ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _themeController.close();
  }
}

/// 테마 확장
extension ThemeExtension on BuildContext {
  /// 현재 테마 데이터
  AppThemeData get appTheme => ThemeManager.instance.getCurrentTheme(this);

  /// 현재 색상
  AppColors get colors => appTheme.colors;

  /// 다크 모드 여부
  bool get isDarkMode => ThemeManager.instance.isDarkMode(this);
}

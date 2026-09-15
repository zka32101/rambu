/// Theme Manager
/// ゲーム全体のテーマ・ビジュアル統一管理

import 'package:flutter/material.dart';

/// カラー パレット
class GameColorPalette {
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFFFFB81C);

  static const Color shogiBoardBrown = Color(0xFF8B6F47);
  static const Color shogiBoardLight = Color(0xFFE8D4B8);
  static const Color victoryGold = Color(0xFFFFD700);
  static const Color defeatRed = Color(0xFFDC143C);
}

/// テーマ モード
enum ThemeMode {
  light,
  dark,
  auto,
}

/// ゲーム テーマ
class GameTheme {
  final ThemeData themeData;
  final GameColorPalette colorPalette;
  final String themeName;

  GameTheme({
    required this.themeData,
    required this.colorPalette,
    required this.themeName,
  });

  static GameTheme darkTheme() {
    return GameTheme(
      themeData: ThemeData.dark().copyWith(
        primaryColor: GameColorPalette.primary,
        scaffoldBackgroundColor: GameColorPalette.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: GameColorPalette.surface,
          elevation: 0,
        ),
      ),
      colorPalette: GameColorPalette(),
      themeName: 'Dark',
    );
  }

  static GameTheme lightTheme() {
    return GameTheme(
      themeData: ThemeData.light().copyWith(
        primaryColor: GameColorPalette.primary,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      colorPalette: GameColorPalette(),
      themeName: 'Light',
    );
  }
}

/// テーマ マネージャー（Singleton）
class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();

  late GameTheme _currentTheme;
  late ThemeMode _themeMode;

  ThemeManager._internal();

  factory ThemeManager() {
    return _instance;
  }

  /// 初期化
  void initialize({ThemeMode mode = ThemeMode.dark}) {
    _themeMode = mode;
    _currentTheme = GameTheme.darkTheme();
  }

  /// 現在のテーマを取得
  GameTheme get currentTheme => _currentTheme;

  /// テーマを変更
  void setTheme(GameTheme theme) {
    _currentTheme = theme;
  }

  /// テーマモードを変更
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    switch (mode) {
      case ThemeMode.dark:
        _currentTheme = GameTheme.darkTheme();
        break;
      case ThemeMode.light:
        _currentTheme = GameTheme.lightTheme();
        break;
      case ThemeMode.auto:
        _currentTheme = GameTheme.darkTheme();
        break;
    }
  }

  /// テーマデータを取得
  ThemeData get themeData => _currentTheme.themeData;

  /// カラーパレットを取得
  GameColorPalette get colors => _currentTheme.colorPalette;
}

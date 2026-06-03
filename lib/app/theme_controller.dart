import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The four theme modes the user can choose from.
enum AppThemeMode { system, light, dark, oled }

/// Predefined theme styles beyond the default Material 3 seed theme.
enum AppThemeStyle { classic, cyberpunk }

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _keyMode = 'app_theme_mode';
  static const _keyStyle = 'app_theme_style';

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  AppThemeStyle _style = AppThemeStyle.classic;
  AppThemeStyle get style => _style;

  void _load() {
    final storedMode = _prefs.getString(_keyMode);
    _mode = AppThemeMode.values.firstWhere(
      (e) => e.name == storedMode,
      orElse: () => AppThemeMode.system,
    );
    final storedStyle = _prefs.getString(_keyStyle);
    _style = AppThemeStyle.values.firstWhere(
      (e) => e.name == storedStyle,
      orElse: () => AppThemeStyle.classic,
    );
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _prefs.setString(_keyMode, mode.name);
    notifyListeners();
  }

  Future<void> setStyle(AppThemeStyle style) async {
    if (_style == style) return;
    _style = style;
    await _prefs.setString(_keyStyle, style.name);
    notifyListeners();
  }

  /// Maps [AppThemeMode] to Flutter's [ThemeMode].
  /// OLED is dark under the hood; the app selects the OLED [ThemeData]
  /// separately by checking [isOled].
  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.oled:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isOled => _mode == AppThemeMode.oled;
}

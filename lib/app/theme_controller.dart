import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The four theme modes the user can choose from.
enum AppThemeMode { system, light, dark, oled }

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  void _load() {
    final stored = _prefs.getString(_key);
    _mode = AppThemeMode.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _prefs.setString(_key, mode.name);
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

import 'package:caltrack/app/theme_controller.dart';
import 'package:caltrack/core/themes/classic_theme.dart';
import 'package:caltrack/core/themes/cyberpunk_theme.dart';
import 'package:flutter/material.dart';

/// Resolve a full [ThemeData] from a [AppThemeStyle] + brightness + OLED flag.
///
/// Every style is required to define all three variants (light, dark, OLED).
/// Missing entries produce a compile-time warning from the exhaustive switch.
ThemeData buildThemeForStyle({
  required AppThemeStyle style,
  required Brightness brightness,
  bool isOled = false,
}) {
  switch (style) {
    case AppThemeStyle.classic:
      return buildClassicTheme(brightness: brightness, isOled: isOled);
    case AppThemeStyle.cyberpunk:
      return buildCyberpunkTheme(brightness: brightness, isOled: isOled);
  }
}
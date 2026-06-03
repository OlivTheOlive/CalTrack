import 'package:caltrack/app/theme_controller.dart';
import 'package:caltrack/core/themes/theme_data.dart';
import 'package:flutter/material.dart';

/// Thin wrapper — delegates to the style-driven [buildThemeForStyle].
ThemeData buildCalTrackTheme({
  AppThemeStyle style = AppThemeStyle.classic,
  Brightness brightness = Brightness.light,
}) {
  return buildThemeForStyle(
    style: style,
    brightness: brightness,
    isOled: false,
  );
}

/// Pure-black OLED variant. Delegates to the same style system.
ThemeData buildCalTrackOledTheme({
  AppThemeStyle style = AppThemeStyle.classic,
}) {
  return buildThemeForStyle(
    style: style,
    brightness: Brightness.dark,
    isOled: true,
  );
}

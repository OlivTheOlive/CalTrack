import 'package:caltrack/core/themes/theme_components.dart';
import 'package:flutter/material.dart';

/// Cyberpunk theme: neon cyan/magenta/green accents on dark navy or true
/// black surfaces. All three brightness variants are defined explicitly.
ThemeData buildCyberpunkTheme({required Brightness brightness, bool isOled = false}) {
  switch (brightness) {
    case Brightness.light:
      return _cyberpunkLight();
    case Brightness.dark:
      return isOled ? _cyberpunkOled() : _cyberpunkDark();
  }
}

ThemeData _cyberpunkLight() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00838F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB2EBF2),
    onPrimaryContainer: Color(0xFF002F33),
    secondary: Color(0xFFAA00FF),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE040FB),
    onSecondaryContainer: Color(0xFF1A002E),
    tertiary: Color(0xFF76FF03),
    onTertiary: Color(0xFF1B5E00),
    tertiaryContainer: Color(0xFFB9F6CA),
    onTertiaryContainer: Color(0xFF003300),
    error: Color(0xFFD50000),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFF410000),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F5F5),
    surfaceContainer: Color(0xFFEFEFEF),
    surfaceContainerHigh: Color(0xFFE8E8E8),
    surfaceContainerHighest: Color(0xFFE0E0E0),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFF4DD0E1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
  return _cyberpunkBase(colorScheme, scaffoldBg: Colors.white);
}

ThemeData _cyberpunkDark() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4DD0E1),
    onPrimary: Color(0xFF003F44),
    primaryContainer: Color(0xFF006064),
    onPrimaryContainer: Color(0xFFB2EBF2),
    secondary: Color(0xFFE040FB),
    onSecondary: Color(0xFF3D0066),
    secondaryContainer: Color(0xFF7B1FA2),
    onSecondaryContainer: Color(0xFFF3E5F5),
    tertiary: Color(0xFF76FF03),
    onTertiary: Color(0xFF1B5E00),
    tertiaryContainer: Color(0xFF2E7D32),
    onTertiaryContainer: Color(0xFFB9F6CA),
    error: Color(0xFFFF5252),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0F0F23),
    onSurface: Color(0xFFE6E1E5),
    surfaceContainerLowest: Color(0xFF0B0B1A),
    surfaceContainerLow: Color(0xFF111133),
    surfaceContainer: Color(0xFF12123A),
    surfaceContainerHigh: Color(0xFF141440),
    surfaceContainerHighest: Color(0xFF16213E),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF00838F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
  return _cyberpunkBase(colorScheme, scaffoldBg: const Color(0xFF0F0F23));
}

ThemeData _cyberpunkOled() {
  final oled = _cyberpunkDark().copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF4DD0E1),
      onPrimary: Color(0xFF003F44),
      primaryContainer: Color(0xFF006064),
      onPrimaryContainer: Color(0xFFB2EBF2),
      secondary: Color(0xFFE040FB),
      onSecondary: Color(0xFF3D0066),
      secondaryContainer: Color(0xFF7B1FA2),
      onSecondaryContainer: Color(0xFFF3E5F5),
      tertiary: Color(0xFF76FF03),
      onTertiary: Color(0xFF1B5E00),
      tertiaryContainer: Color(0xFF2E7D32),
      onTertiaryContainer: Color(0xFFB9F6CA),
      error: Color(0xFFFF5252),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Colors.black,
      onSurface: Color(0xFFE6E1E5),
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: Color(0xFF0A0A0A),
      surfaceContainer: Color(0xFF0D0D0D),
      surfaceContainerHigh: Color(0xFF111111),
      surfaceContainerHighest: Color(0xFF0D0D0D),
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      inverseSurface: Color(0xFFE6E1E5),
      onInverseSurface: Color(0xFF313033),
      inversePrimary: Color(0xFF00838F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
  );
  // Re-apply shared component theming so navigation bars, snack bars etc.
  // pick up the true-black OLED surfaces instead of the dark navy ones.
  return applySharedComponents(oled);
}

ThemeData _cyberpunkBase(ColorScheme colorScheme, {required Color scaffoldBg}) {
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: scaffoldBg,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: buttonShape,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
    ),
  );
  return applySharedComponents(theme);
}
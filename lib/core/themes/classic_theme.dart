import 'package:caltrack/core/themes/theme_components.dart';
import 'package:flutter/material.dart';

/// Build a theme using the default Material 3 seed color (#2E7D6B).
ThemeData buildClassicTheme({required Brightness brightness, bool isOled = false}) {
  const seed = Color(0xFF2E7D6B);
  final base = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );

  if (!isOled) {
    return _buildFromScheme(base);
  }

  final colorScheme = base.copyWith(
    surface: Colors.black,
    surfaceContainerHighest: const Color(0xFF0D0D0D),
    surfaceContainerHigh: const Color(0xFF111111),
    surfaceContainer: const Color(0xFF141414),
    surfaceContainerLow: const Color(0xFF181818),
    surfaceContainerLowest: Colors.black,
    surfaceDim: Colors.black,
    surfaceBright: const Color(0xFF1C1C1C),
  );
  return _buildFromScheme(colorScheme).copyWith(
    scaffoldBackgroundColor: Colors.black,
  );
}

ThemeData _buildFromScheme(ColorScheme colorScheme) {
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
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
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  return applySharedComponents(theme);
}
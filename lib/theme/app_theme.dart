import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static const Color seed = Color(0xFF5B4BD6);

  // Cached: ColorScheme.fromSeed is not free and must not run on every rebuild.
  static final ThemeData light = _build(Brightness.light, AppColors.light);
  static final ThemeData dark = _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.pageBg,
      textTheme: buildTextTheme(colors),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: Space.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusToken.sm),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusToken.sm),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusToken.md),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

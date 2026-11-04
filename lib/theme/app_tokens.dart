import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 4pt spacing grid.
abstract final class Space {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

abstract final class RadiusToken {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class SizeToken {
  static const double controlMd = 40;
  static const double controlLg = 48;
  static const double touchTarget = 48;
  static const double sidebarWidth = 240;
  static const double contentMaxWidth = 1120;
  static const double compactBreakpoint = 600;
  static const double mediumBreakpoint = 900;
  static const double largeBreakpoint = 1200;
}

enum AppBreakpoint { compact, medium, expanded, large }

AppBreakpoint breakpointOf(double width) {
  if (width < SizeToken.compactBreakpoint) return AppBreakpoint.compact;
  if (width < SizeToken.mediumBreakpoint) return AppBreakpoint.medium;
  if (width < SizeToken.largeBreakpoint) return AppBreakpoint.expanded;
  return AppBreakpoint.large;
}

extension AppThemeX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  TextTheme get textStyles => Theme.of(this).textTheme;

  AppBreakpoint get breakpoint => breakpointOf(MediaQuery.sizeOf(this).width);

  bool get isDesktop =>
      breakpoint == AppBreakpoint.expanded ||
      breakpoint == AppBreakpoint.large;
}

/// Semantic type scale. Components must not hardcode fontSize / fontWeight.
TextTheme buildTextTheme(AppColors colors) {
  TextStyle style(double size, double height, FontWeight weight) => TextStyle(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        color: colors.textPrimary,
      );

  return TextTheme(
    displaySmall: style(28, 34, FontWeight.w500),
    headlineSmall: style(20, 28, FontWeight.w500),
    titleMedium: style(15, 22, FontWeight.w500),
    bodyMedium: style(13, 20, FontWeight.w400),
    bodySmall: style(12, 18, FontWeight.w400),
    labelMedium: style(12, 16, FontWeight.w500),
    labelSmall: style(11, 16, FontWeight.w400),
  );
}

import 'package:flutter/material.dart';

import '../models/task_item.dart';

/// Semantic colors. Every visual color in the app must come from here so light
/// and dark themes stay consistent and contrast can be audited in one place.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.onBrand,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    required this.overdue,
    required this.success,
    required this.pageBg,
    required this.surfaceRaised,
    required this.borderSubtle,
    required this.selectedBg,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color brand;
  final Color onBrand;
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;
  final Color overdue;
  final Color success;
  final Color pageBg;
  final Color surfaceRaised;
  final Color borderSubtle;
  final Color selectedBg;
  final Color textPrimary;
  final Color textSecondary;

  static const light = AppColors(
    brand: Color(0xFF5B4BD6),
    onBrand: Color(0xFFFFFFFF),
    priorityHigh: Color(0xFFC0392B),
    priorityMedium: Color(0xFF93610C),
    priorityLow: Color(0xFF1E7A5A),
    overdue: Color(0xFFB3261E),
    success: Color(0xFF1E7A5A),
    pageBg: Color(0xFFF7F8FB),
    surfaceRaised: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE4E6EC),
    selectedBg: Color(0xFFEEEDFE),
    textPrimary: Color(0xFF1F2233),
    textSecondary: Color(0xFF626675),
  );

  static const dark = AppColors(
    brand: Color(0xFFA99BFF),
    onBrand: Color(0xFF17142E),
    priorityHigh: Color(0xFFFF9B93),
    priorityMedium: Color(0xFFE8BE79),
    priorityLow: Color(0xFF7CD7B4),
    overdue: Color(0xFFFF9B93),
    success: Color(0xFF7CD7B4),
    pageBg: Color(0xFF11131B),
    surfaceRaised: Color(0xFF1B1D26),
    borderSubtle: Color(0xFF2E303B),
    selectedBg: Color(0xFF2A2750),
    textPrimary: Color(0xFFEFF0F6),
    textSecondary: Color(0xFFA2A6B5),
  );

  Color priority(TaskPriority priority) => switch (priority) {
        TaskPriority.high => priorityHigh,
        TaskPriority.medium => priorityMedium,
        TaskPriority.low => priorityLow,
      };

  Color category(TaskCategory category) => switch (category) {
        TaskCategory.work => brand,
        TaskCategory.personal => priorityMedium,
        TaskCategory.study => priorityLow,
        TaskCategory.health => priorityHigh,
        TaskCategory.other => textSecondary,
      };

  @override
  ThemeExtension<AppColors> copyWith() => this;

  @override
  ThemeExtension<AppColors> lerp(
    covariant ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      priorityHigh: mix(priorityHigh, other.priorityHigh),
      priorityMedium: mix(priorityMedium, other.priorityMedium),
      priorityLow: mix(priorityLow, other.priorityLow),
      overdue: mix(overdue, other.overdue),
      success: mix(success, other.success),
      pageBg: mix(pageBg, other.pageBg),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      borderSubtle: mix(borderSubtle, other.borderSubtle),
      selectedBg: mix(selectedBg, other.selectedBg),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
    );
  }
}

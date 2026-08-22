import 'package:flutter/material.dart';

import 'lens_colors.dart';

abstract final class LensTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: LensColors.accent,
      brightness: Brightness.dark,
      surface: LensColors.panel,
      error: LensColors.error,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LensColors.background,
      dividerColor: LensColors.border,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: LensColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: LensColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: LensColors.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          color: LensColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: LensColors.panelRaised,
          border: Border.all(color: LensColors.borderStrong),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: LensColors.textPrimary,
          fontSize: 11,
        ),
      ),
    );
  }
}

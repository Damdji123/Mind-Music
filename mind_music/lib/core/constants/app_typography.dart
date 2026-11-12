import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography definitions strictly matching the Inter font specifications in DESIGN.md.
/// Works 100% offline without network fetching delays.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  static TextStyle displayLarge({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 40,
        fontWeight: fontWeight ?? FontWeight.w700,
        height: 48 / 40,
        letterSpacing: letterSpacing ?? (-0.02 * 40),
        color: color,
      );

  static TextStyle headlineLarge({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 28,
        fontWeight: fontWeight ?? FontWeight.w700,
        height: 34 / 28,
        letterSpacing: letterSpacing ?? (-0.015 * 28),
        color: color,
      );

  static TextStyle headlineMedium({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 22,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 28 / 22,
        letterSpacing: letterSpacing ?? (-0.01 * 22),
        color: color,
      );

  static TextStyle headlineSmall({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 18,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 24 / 18,
        letterSpacing: letterSpacing ?? (-0.005 * 18),
        color: color,
      );

  static TextStyle titleMedium({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 22 / 16,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle bodyLarge({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 24 / 16,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle bodyMedium({
    Color color = AppColors.onSurfaceVariant,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 20 / 14,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle bodySmall({
    Color color = AppColors.onSurfaceMuted,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 12,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 16 / 12,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle labelLarge({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 13,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 18 / 13,
        letterSpacing: letterSpacing ?? (0.01 * 13),
        color: color,
      );

  static TextStyle labelMedium({
    Color color = AppColors.onSurfaceVariant,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 11,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 14 / 11,
        letterSpacing: letterSpacing ?? (0.02 * 11),
        color: color,
      );

  static TextStyle labelSmall({
    Color color = AppColors.onSurfaceMuted,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 10,
        fontWeight: fontWeight ?? FontWeight.w500,
        height: 12 / 10,
        letterSpacing: letterSpacing ?? (0.03 * 10),
        color: color,
      );
}

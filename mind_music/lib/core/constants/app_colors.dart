import 'package:flutter/material.dart';

/// Design tokens and color system for Mind-Music ("Liquid Glass Media").
/// Sourced directly from DESIGN.md and Stitch UX specifications.
class AppColors {
  AppColors._();

  // Background & Surface Foundations
  static const Color background = Color(0xFF0B1326);
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceDim = Color(0xFF0B1326);
  static const Color surfaceBright = Color(0xFF31394D);
  static const Color surfaceContainerLowest = Color(0xFF060E20);
  static const Color surfaceContainerLow = Color(0xFF131B2E);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);
  static const Color surfaceVariant = Color(0xFF2D3449);

  // Text & On-Surface
  static const Color onBackground = Color(0xFFDAE2FD);
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFBDC8D1);
  static const Color onSurfaceMuted = Color(0x73FFFFFF); // ~45% white for metadata
  static const Color onSurfaceSecondary = Color(0xB3FFFFFF); // ~70% white

  // Primary Accent: Electric Sky Cyan (Active Playback, Core Actions)
  static const Color primary = Color(0xFF8ED5FF);
  static const Color primaryContainer = Color(0xFF38BDF8);
  static const Color onPrimary = Color(0xFF00354A);
  static const Color onPrimaryContainer = Color(0xFF004965);
  static const Color primaryFixed = Color(0xFFC4E7FF);
  static const Color primaryFixedDim = Color(0xFF7BD0FF);
  static const Color surfaceTint = Color(0xFF7BD0FF);

  // Secondary Accent: Neon Violet (AI Copilot, Neural Engine, Voice)
  static const Color secondary = Color(0xFFDDB8FF);
  static const Color secondaryContainer = Color(0xFF62259B);
  static const Color secondaryHighlight = Color(0xFFC084FC);
  static const Color onSecondary = Color(0xFF490081);
  static const Color onSecondaryContainer = Color(0xFFD1A1FF);

  // Tertiary Accent: Liquid Amber Gold (Premium, Subscriptions, Hi-Res)
  static const Color tertiary = Color(0xFFFFC174);
  static const Color tertiaryContainer = Color(0xFFF59E0B);
  static const Color onTertiary = Color(0xFF472A00);
  static const Color onTertiaryContainer = Color(0xFF613B00);

  // Feedback & Semantic
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color success = Color(0xFF34D399); // Mint Emerald
  static const Color warning = Color(0xFFFBBF24);

  // Outlines & Borders
  static const Color outline = Color(0xFF87929A);
  static const Color outlineVariant = Color(0xFF3E484F);
  static const Color glassBorderSubtle = Color(0x1FFFFFFF); // 12% white subtle border
  static const Color glassBorder = Color(0x29FFFFFF); // 16% white border

  // Glass Translucency Tokens
  static const Color glassUltraThin = Color(0x0DFFFFFF); // 5%
  static const Color glassDefault = Color(0x1AFFFFFF); // 10%
  static const Color glassFloating = Color(0x29FFFFFF); // 16%
  static const Color glassActive = Color(0x33FFFFFF); // 20%
  static const Color glassDarkBase = Color(0xA60F172A); // 65% of #0F172A for floating dock

  // Glass Specular Gradients
  static const LinearGradient glassSpecularStroke = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x59FFFFFF), // 35% specular shine
      Color(0x14FFFFFF), // 8% mid reflection
      Color(0x05FFFFFF), // 2% subtle rim
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient premiumGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFFFC174),
      Color(0x40F59E0B),
    ],
  );

  static const LinearGradient aiVioletCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF38BDF8),
      Color(0xFFC084FC),
    ],
  );
}

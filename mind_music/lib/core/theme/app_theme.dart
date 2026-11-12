import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

enum AppThemeMode {
  liquidGlass,
  oledDark,
  cyberpunk,
  sunset,
}

class AppTheme {
  AppTheme._();

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.oledDark:
        return _buildOledTheme();
      case AppThemeMode.cyberpunk:
        return _buildCyberpunkTheme();
      case AppThemeMode.sunset:
        return _buildSunsetTheme();
      case AppThemeMode.liquidGlass:
        return _buildLiquidGlassTheme();
    }
  }

  static ThemeData _buildLiquidGlassTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryContainer,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondaryHighlight,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiaryContainer,
        onTertiary: AppColors.onTertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        error: AppColors.error,
        onError: AppColors.onError,
        outline: AppColors.outline,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.onSurface,
        size: 24,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.onSurface),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.glassDefault,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderLg,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primaryContainer,
        unselectedItemColor: AppColors.onSurfaceMuted,
      ),
    );
  }

  static ThemeData _buildOledTheme() {
    return _buildLiquidGlassTheme().copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: _buildLiquidGlassTheme().colorScheme.copyWith(
            surface: Colors.black,
            surfaceContainerLowest: Colors.black,
            surfaceContainerLow: const Color(0xFF070707),
            surfaceContainer: const Color(0xFF0F0F0F),
          ),
    );
  }

  static ThemeData _buildCyberpunkTheme() {
    return _buildLiquidGlassTheme().copyWith(
      scaffoldBackgroundColor: const Color(0xFF08020F),
      colorScheme: _buildLiquidGlassTheme().colorScheme.copyWith(
            primary: const Color(0xFF00F0FF), // Cyber Neon Cyan
            secondary: const Color(0xFFFF007F), // Neon Pink
            surface: const Color(0xFF110524),
          ),
    );
  }

  static ThemeData _buildSunsetTheme() {
    return _buildLiquidGlassTheme().copyWith(
      scaffoldBackgroundColor: const Color(0xFF16091B),
      colorScheme: _buildLiquidGlassTheme().colorScheme.copyWith(
            primary: const Color(0xFFFF7E47), // Sunset Coral
            secondary: const Color(0xFFFFB547), // Golden Glow
            surface: const Color(0xFF230F2C),
          ),
    );
  }
}

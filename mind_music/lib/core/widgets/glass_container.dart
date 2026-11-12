import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum GlassElevation {
  level1, // Ambient inactive glass (card, background pod)
  level2, // Active interactive card / player container
  level3, // Focused & AI luminous element
}

/// A liquid glassmorphic container implementing optical refraction, specular highlights,
/// and chromatic back-glows according to DESIGN.md.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final GlassElevation elevation;
  final Color? customFillColor;
  final Gradient? customGradient;
  final Border? customBorder;
  final VoidCallback? onTap;
  final bool hasSpecularBorder;
  final bool hasGlow;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(AppDimensions.gutter),
    this.margin,
    this.borderRadius,
    this.elevation = GlassElevation.level1,
    this.customFillColor,
    this.customGradient,
    this.customBorder,
    this.onTap,
    this.hasSpecularBorder = true,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppDimensions.borderLg;

    final blurAmount = switch (elevation) {
      GlassElevation.level1 => AppDimensions.blurAmbient,
      GlassElevation.level2 => AppDimensions.blurFloating,
      GlassElevation.level3 => AppDimensions.blurIntense,
    };

    final decoration = _buildDecoration();

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          splashColor: AppColors.primaryContainer.withValues(alpha: 0.15),
          highlightColor: AppColors.primaryContainer.withValues(alpha: 0.08),
          child: content,
        ),
      );
    }

    return content;
  }

  BoxDecoration _buildDecoration() {
    final effectiveRadius = borderRadius ?? AppDimensions.borderLg;

    List<BoxShadow> shadows = [];

    switch (elevation) {
      case GlassElevation.level1:
        shadows = [
          const BoxShadow(
            color: Color(0x40000000), // 25% black
            offset: Offset(0, 8),
            blurRadius: 32,
          ),
        ];
        break;
      case GlassElevation.level2:
        shadows = [
          const BoxShadow(
            color: Color(0x59000000), // 35% black
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ];
        break;
      case GlassElevation.level3:
        shadows = [
          BoxShadow(
            color: (glowColor ?? AppColors.primaryContainer).withValues(alpha: 0.45),
            offset: Offset.zero,
            blurRadius: 24,
            spreadRadius: -2,
          ),
          const BoxShadow(
            color: Color(0x80000000), // 50% black
            offset: Offset(0, 20),
            blurRadius: 48,
          ),
        ];
        break;
    }

    if (hasGlow && glowColor != null) {
      shadows.add(
        BoxShadow(
          color: glowColor!.withValues(alpha: 0.35),
          offset: Offset.zero,
          blurRadius: 24,
        ),
      );
    }

    // Default fill colors per elevation level
    Color baseFill;
    Gradient? gradient = customGradient;

    switch (elevation) {
      case GlassElevation.level1:
        baseFill = customFillColor ?? AppColors.glassDefault;
        break;
      case GlassElevation.level2:
        baseFill = customFillColor ?? AppColors.glassFloating;
        gradient ??= const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x26FFFFFF), // 15%
            Color(0x0DFFFFFF), // 5%
          ],
        );
        break;
      case GlassElevation.level3:
        baseFill = customFillColor ?? AppColors.glassActive;
        break;
    }

    // Border: Specular or custom
    BoxBorder? border = customBorder;
    if (border == null && hasSpecularBorder) {
      border = Border.all(
        color: switch (elevation) {
          GlassElevation.level1 => Colors.white.withValues(alpha: 0.12),
          GlassElevation.level2 => Colors.white.withValues(alpha: 0.22),
          GlassElevation.level3 => AppColors.primaryContainer.withValues(alpha: 0.40),
        },
        width: 1.0,
      );
    }

    return BoxDecoration(
      color: gradient == null ? baseFill : null,
      gradient: gradient,
      borderRadius: effectiveRadius,
      border: border,
      boxShadow: shadows,
    );
  }
}

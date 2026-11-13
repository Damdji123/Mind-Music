import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? customGlowColor;
  final bool isPrimary;
  final bool isRound;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44.0,
    this.iconSize = 22.0,
    this.iconColor,
    this.customGlowColor,
    this.isPrimary = false,
    this.isRound = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = isRound
        ? BorderRadius.circular(size / 2)
        : AppDimensions.borderSm;

    final glow = isPrimary || customGlowColor != null;
    final effectiveGlowColor = customGlowColor ?? AppColors.primaryContainer;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: effectiveGlowColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          splashColor: AppColors.primaryContainer.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: isPrimary
                  ? AppColors.primaryContainer.withValues(alpha: 0.25)
                  : AppColors.glassDefault,
              border: Border.all(
                color: isPrimary
                    ? AppColors.primaryContainer.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ??
                    (isPrimary ? AppColors.primaryFixed : AppColors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

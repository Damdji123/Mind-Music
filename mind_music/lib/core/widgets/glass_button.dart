import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

enum GlassButtonVariant {
  primary,
  secondary,
  aiAccent,
  premiumGold,
}

class GlassButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.width,
    this.height = 46.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    Color fillColor;
    Gradient? gradient;
    Border? border;
    List<BoxShadow> shadows = [];
    Color textColor = AppColors.onSurface;

    switch (variant) {
      case GlassButtonVariant.primary:
        fillColor = const Color(0x2EFFFFFF); // 18% white
        border = Border.all(color: const Color(0x66FFFFFF), width: 1.0);
        shadows = [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ];
        break;

      case GlassButtonVariant.secondary:
        fillColor = const Color(0x14FFFFFF); // 8% white
        border = Border.all(color: const Color(0x26FFFFFF), width: 1.0);
        textColor = AppColors.onSurfaceVariant;
        break;

      case GlassButtonVariant.aiAccent:
        fillColor = Colors.transparent;
        gradient = const LinearGradient(
          colors: [
            Color(0x3338BDF8), // 20% Cyan
            Color(0x33C084FC), // 20% Violet
          ],
        );
        border = Border.all(color: AppColors.secondaryHighlight.withValues(alpha: 0.5), width: 1.0);
        shadows = [
          BoxShadow(
            color: AppColors.secondaryHighlight.withValues(alpha: 0.3),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ];
        break;

      case GlassButtonVariant.premiumGold:
        fillColor = Colors.transparent;
        gradient = const LinearGradient(
          colors: [
            Color(0x33F59E0B),
            Color(0x33FFC174),
          ],
        );
        border = Border.all(color: AppColors.tertiaryContainer.withValues(alpha: 0.7), width: 1.0);
        textColor = AppColors.tertiary;
        shadows = [
          BoxShadow(
            color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ];
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: AppDimensions.borderFull,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: AppDimensions.borderFull,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppDimensions.borderFull,
              onTap: onPressed,
              splashColor: AppColors.primaryContainer.withValues(alpha: 0.25),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: gradient == null ? fillColor : null,
                  gradient: gradient,
                  borderRadius: AppDimensions.borderFull,
                  border: border,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8.0),
                    ],
                    Text(
                      label,
                      style: AppTypography.labelLarge(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

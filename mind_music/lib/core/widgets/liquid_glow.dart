import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Provides the ethereal background lighting required for realistic glass refraction.
/// Emulates colored LEDs cast through frosted acrylic (Cyan, Violet, Gold orbs).
class LiquidGlowBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryGlow;
  final Color? secondaryGlow;
  final bool animate;

  const LiquidGlowBackground({
    super.key,
    required this.child,
    this.primaryGlow,
    this.secondaryGlow,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final cyan = primaryGlow ?? AppColors.primaryContainer;
    final violet = secondaryGlow ?? AppColors.secondaryContainer;

    return Stack(
      children: [
        // Dark Abyssal Background
        Container(color: AppColors.background),

        // Ambient Photon Orb 1: Electric Cyan (Top Right)
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cyan.withValues(alpha: 0.22),
                  cyan.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Ambient Photon Orb 2: Neon Violet (Center Left)
        Positioned(
          top: 250,
          left: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  violet.withValues(alpha: 0.20),
                  violet.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Ambient Photon Orb 3: Subtle Amber / Deep Glow (Bottom Center)
        Positioned(
          bottom: -80,
          right: 40,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.tertiaryContainer.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Smooth backdrop blur across the glowing orbs
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const SizedBox.expand(),
          ),
        ),

        // Foreground application content
        SafeArea(child: child),
      ],
    );
  }
}

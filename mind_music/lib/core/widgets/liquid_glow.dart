import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Provides the fluid ethereal background lighting required for realistic glass refraction
/// and liquidmorphic ambient radiance (Cyan, Violet, Gold orbs).
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
        // Cached RepaintBoundary for Background Canvas & Liquid Photon Orbs
        // (Isolates heavy background drawing so scrolling & tapping don't repaint the canvas)
        RepaintBoundary(
          child: Stack(
            children: [
              // Dark Abyssal Liquid Canvas
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF080C14),
                      Color(0xFF0F172A),
                      Color(0xFF070B12),
                    ],
                  ),
                ),
              ),

              // Ambient Liquid Photon Orb 1: Electric Cyan (Top Right)
              Positioned(
                top: -90,
                right: -70,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cyan.withValues(alpha: 0.35),
                        cyan.withValues(alpha: 0.22),
                        cyan.withValues(alpha: 0.08),
                        cyan.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),

              // Ambient Liquid Photon Orb 2: Neon Violet (Center Left)
              Positioned(
                top: 220,
                left: -110,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        violet.withValues(alpha: 0.30),
                        violet.withValues(alpha: 0.18),
                        violet.withValues(alpha: 0.06),
                        violet.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),

              // Ambient Liquid Photon Orb 3: Subtle Gold / Teal Glow (Bottom Center)
              Positioned(
                bottom: -70,
                right: 30,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.tertiaryContainer.withValues(alpha: 0.22),
                        AppColors.tertiaryContainer.withValues(alpha: 0.12),
                        AppColors.tertiaryContainer.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Foreground application content without double-nesting SafeArea
        child,
      ],
    );
  }
}

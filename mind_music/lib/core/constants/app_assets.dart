import 'package:flutter/material.dart';

class AppAssets {
  AppAssets._();

  static const String logo = 'assets/images/Music Logo.png';
  static const String fallbackLogo = 'lib/assets/images/Music Logo.png';
}

class AppLogo extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final bool hasGlow;

  const AppLogo({
    super.key,
    this.size = 36.0,
    this.borderRadius,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                  blurRadius: size * 0.4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          AppAssets.logo,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              AppAssets.fallbackLogo,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1E293B),
                child: const Icon(
                  Icons.music_note,
                  color: Color(0xFF38BDF8),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppDimensions.margin,
      right: AppDimensions.margin,
      bottom: 16.0,
      child: RepaintBoundary(
        child: Container(
          height: 64.0,
          decoration: BoxDecoration(
            borderRadius: AppDimensions.borderFull,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000), // 40% shadow
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppDimensions.borderFull,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 14.0,
                sigmaY: 14.0,
              ),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: AppColors.glassDarkBase, // rgba(15, 23, 42, 0.65)
                borderRadius: AppDimensions.borderFull,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_filled,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.library_music_outlined,
                    label: 'Library',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.queue_music,
                    label: 'Playlists',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.auto_awesome,
                    label: 'AI Copilot',
                    isAi: true,
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

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isAi = false,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = isAi ? AppColors.secondaryHighlight : AppColors.primaryContainer;
    final inactiveColor = AppColors.onSurfaceMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppDimensions.borderFull,
        onTap: () => onTabSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                )
              else
                Text(
                  label,
                  style: AppTypography.labelSmall(color: inactiveColor).copyWith(fontSize: 9),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

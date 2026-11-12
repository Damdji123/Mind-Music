import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';

class MediaStatsRow extends StatelessWidget {
  final int musicCount;
  final int videoCount;
  final int folderCount;
  final void Function(int tabIndex)? onCategoryTap;

  const MediaStatsRow({
    super.key,
    this.musicCount = 523,
    this.videoCount = 184,
    this.folderCount = 31,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            context,
            index: 1,
            icon: Icons.music_note,
            iconColor: AppColors.primaryContainer,
            title: 'Music',
            subtitle: '$musicCount files',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceMd),
        Expanded(
          child: _buildStatTile(
            context,
            index: 2,
            icon: Icons.smart_display_outlined,
            iconColor: AppColors.secondaryHighlight,
            title: 'Videos',
            subtitle: '$videoCount files',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceMd),
        Expanded(
          child: _buildStatTile(
            context,
            index: 3,
            icon: Icons.folder_outlined,
            iconColor: AppColors.tertiary,
            title: 'Folders',
            subtitle: '$folderCount direct',
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return GlassContainer(
      elevation: GlassElevation.level1,
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
      borderRadius: AppDimensions.borderMd,
      onTap: () => onCategoryTap?.call(index),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.titleMedium(color: AppColors.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

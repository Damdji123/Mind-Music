import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/media_item_model.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';

class ContinueListeningCard extends StatelessWidget {
  final MediaItemModel? mediaItem;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback? onPlayTap;
  final VoidCallback? onCardTap;

  const ContinueListeningCard({
    super.key,
    this.mediaItem,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = const Duration(minutes: 3, seconds: 56),
    this.onPlayTap,
    this.onCardTap,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = mediaItem != null;
    final title = mediaItem?.title ?? 'No Active Media';
    final artist = mediaItem?.artist ?? 'Scan storage to play your music & video';
    final isVideo = mediaItem?.isVideo ?? false;
    final format = mediaItem?.format ?? 'Offline';
    final isHiRes = mediaItem?.isHiRes ?? false;

    final double progressValue = (hasMedia && duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GlassContainer(
      elevation: GlassElevation.level2,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      borderRadius: AppDimensions.borderLg,
      onTap: onCardTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVideo ? Icons.smart_display : Icons.music_note,
                color: isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isVideo ? 'CONTINUE WATCHING' : 'CONTINUE LISTENING',
                  style: AppTypography.labelSmall(
                    color: isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isHiRes
                      ? AppColors.tertiaryContainer.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: AppDimensions.borderFull,
                  border: Border.all(
                    color: isHiRes
                        ? AppColors.tertiaryContainer.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isHiRes ? '$format 24b' : format,
                  style: AppTypography.labelSmall(
                    color: isHiRes ? AppColors.tertiary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Track Artwork Capsule with inner inset glow
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isVideo
                        ? const [Color(0xFF2E1065), Color(0xFF0F172A)]
                        : const [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer)
                          .withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isVideo ? Icons.videocam : Icons.audiotrack,
                    color: isVideo ? AppColors.secondaryHighlight : AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Track Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSmall(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            artist,
                            style: AppTypography.bodyMedium(color: AppColors.onSurfaceSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primaryContainer,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play / Pause Circle
              GlassIconButton(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                size: 48,
                iconSize: 26,
                isPrimary: true,
                onPressed: onPlayTap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Scrub bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
              ),
              Text(
                _formatDuration(duration),
                style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

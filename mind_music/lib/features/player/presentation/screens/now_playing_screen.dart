import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/media_item_model.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../equalizer/presentation/screens/equalizer_screen.dart';
import '../../../sleep_timer/presentation/screens/advanced_sleep_timer_screen.dart';
import 'full_screen_video_player.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _isFavorite = false;
  double _dragPosition = -1.0;
  bool _isDragging = false;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackEngineService>();
    final media = playback.currentMedia;
    final isVideo = playback.mode == PlaybackMode.video;

    final duration = playback.duration;
    final position = _isDragging
        ? Duration(milliseconds: _dragPosition.toInt())
        : playback.position;

    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Scaffold(
      body: LiquidGlowBackground(
        primaryGlow: isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
        secondaryGlow: isVideo ? const Color(0xFF6366F1) : AppColors.secondaryContainer,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.margin,
                  vertical: AppDimensions.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassIconButton(
                      icon: Icons.keyboard_arrow_down,
                      size: 40,
                      iconSize: 24,
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Dual-Mode Audio / Video Segmented Pill
                    _buildModeToggle(playback),
                    Row(
                      children: [
                        // Quick Sleep Timer Chip
                        _buildSleepTimerChip(context, playback),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: Icons.more_vert,
                          size: 40,
                          iconSize: 20,
                          onPressed: () => _showMediaOptions(context, media),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Middle Content Area (Audio Artwork vs Video Viewport)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Audio / Video Viewport
                      if (isVideo)
                        _buildVideoViewport(playback)
                      else
                        _buildAudioArtwork(media),

                      const SizedBox(height: 18),

                      // Track Metadata & Action Icons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  media?.title ?? 'No Track Playing',
                                  style: AppTypography.headlineMedium(color: AppColors.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        media?.artist ?? 'Unknown Artist',
                                        style: AppTypography.titleMedium(color: AppColors.onSurfaceSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.primaryContainer,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${media?.album ?? 'Album'}',
                                      style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? AppColors.error : AppColors.onSurfaceSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isFavorite ? '❤️ Added to Favorites' : 'Removed from Favorites'),
                                  duration: const Duration(milliseconds: 1200),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.playlist_add,
                              color: AppColors.onSurfaceSecondary,
                            ),
                            onPressed: () => _showAddToPlaylistDialog(context, media),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Format Badges (Lossless 24b/96k, Dolby Atmos, 4K)
                      Row(
                        children: [
                          _buildBadge(
                            icon: Icons.workspace_premium,
                            label: media?.isHiRes == true ? 'Lossless • 24b/96k' : (media?.format ?? 'AUDIO'),
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            icon: Icons.surround_sound,
                            label: 'Dolby Atmos',
                            color: AppColors.primaryContainer,
                          ),
                          if (isVideo) ...[
                            const SizedBox(width: 8),
                            _buildBadge(
                              icon: Icons.hd,
                              label: '1080p • 60fps',
                              color: AppColors.secondaryHighlight,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // AI Copilot Realtime Insights Pill
                      _buildAiCopilotInsightCard(context, media),

                      const SizedBox(height: 20),

                      // 3. Interactive Scrub Bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                          activeTrackColor: isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                          thumbColor: isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
                          overlayColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: currentMs,
                          min: 0.0,
                          max: maxMs,
                          onChangeStart: (val) {
                            setState(() {
                              _isDragging = true;
                              _dragPosition = val;
                            });
                          },
                          onChanged: (val) {
                            setState(() {
                              _dragPosition = val;
                            });
                          },
                          onChangeEnd: (val) {
                            playback.seek(Duration(milliseconds: val.toInt()));
                            setState(() {
                              _isDragging = false;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                            ),
                            Text(
                              'Buffer 100% Local',
                              style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. Main Control Deck (Shuffle, Prev, 10s Rewind, Play/Pause, 10s Fwd, Next, Repeat)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Shuffle
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: playback.isShuffle
                                  ? AppColors.primaryContainer
                                  : AppColors.onSurfaceMuted,
                              size: 22,
                            ),
                            onPressed: playback.toggleShuffle,
                          ),
                          // 10s Rewind
                          IconButton(
                            icon: const Icon(Icons.replay_10, size: 26),
                            color: AppColors.onSurfaceSecondary,
                            onPressed: () {
                              final newPos = playback.position - const Duration(seconds: 10);
                              playback.seek(newPos < Duration.zero ? Duration.zero : newPos);
                            },
                          ),
                          // Skip Previous
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 34),
                            color: AppColors.onSurface,
                            onPressed: playback.skipPrevious,
                          ),
                          // Play / Pause Hero Button
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isVideo
                                          ? AppColors.secondaryHighlight
                                          : AppColors.primaryContainer)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (isVideo
                                            ? AppColors.secondaryHighlight
                                            : AppColors.primaryContainer)
                                        .withValues(alpha: 0.3),
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: isVideo
                                          ? AppColors.secondaryHighlight
                                          : AppColors.primaryContainer,
                                      width: 1.5,
                                    ),
                                    padding: EdgeInsets.zero,
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: playback.playPause,
                                  child: Icon(
                                    playback.isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Skip Next
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 34),
                            color: AppColors.onSurface,
                            onPressed: playback.skipNext,
                          ),
                          // 10s Forward
                          IconButton(
                            icon: const Icon(Icons.forward_10, size: 26),
                            color: AppColors.onSurfaceSecondary,
                            onPressed: () {
                              final newPos = playback.position + const Duration(seconds: 10);
                              playback.seek(newPos > playback.duration ? playback.duration : newPos);
                            },
                          ),
                          // Repeat Mode
                          IconButton(
                            icon: Icon(
                              playback.loopMode == LoopMode.one
                                  ? Icons.repeat_one
                                  : (playback.loopMode == LoopMode.all
                                      ? Icons.repeat
                                      : Icons.repeat),
                              color: playback.loopMode != LoopMode.off
                                  ? AppColors.primaryContainer
                                  : AppColors.onSurfaceMuted,
                              size: 22,
                            ),
                            onPressed: playback.toggleLoopMode,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 5. Up-Next Queue Quick Drawer
                      _buildQueueSection(context, playback),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Audio Artwork Viewport ---
  Widget _buildAudioArtwork(MediaItemModel? media) {
    return Center(
      child: Container(
        width: 290,
        height: 290,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x3338BDF8), Color(0x33C084FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.audiotrack,
                  size: 96,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Video Viewport ---
  Widget _buildVideoViewport(PlaybackEngineService playback) {
    final controller = playback.videoController;

    return Center(
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black,
          border: Border.all(
            color: AppColors.secondaryHighlight.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryHighlight.withValues(alpha: 0.3),
              blurRadius: 32,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (controller != null && controller.value.isInitialized)
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                )
              else
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_display, size: 64, color: AppColors.secondaryHighlight),
                    SizedBox(height: 8),
                    Text('Local 4K Video Preview Active', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              // Fullscreen Trigger Pill
              Positioned(
                top: 12,
                right: 12,
                child: GlassIconButton(
                  icon: Icons.fullscreen,
                  size: 36,
                  iconSize: 20,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FullScreenVideoPlayer(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Mode Toggle: Audio vs Video ---
  Widget _buildModeToggle(PlaybackEngineService playback) {
    final isVideo = playback.mode == PlaybackMode.video;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AppDimensions.borderFull,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillButton(
            label: 'Audio',
            icon: Icons.graphic_eq,
            isSelected: !isVideo,
            color: AppColors.primaryContainer,
            onTap: () {
              if (isVideo && playback.currentMedia != null) {
                playback.playMedia(playback.currentMedia!.copyWith(isVideo: false));
              }
            },
          ),
          _buildPillButton(
            label: 'Video',
            icon: Icons.smart_display,
            isSelected: isVideo,
            color: AppColors.secondaryHighlight,
            onTap: () {
              if (!isVideo && playback.currentMedia != null) {
                playback.playMedia(playback.currentMedia!.copyWith(isVideo: true));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: AppDimensions.borderFull,
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
          border: isSelected ? Border.all(color: color.withValues(alpha: 0.6)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? color : AppColors.onSurfaceMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sleep Timer Chip in Header ---
  Widget _buildSleepTimerChip(BuildContext context, PlaybackEngineService playback) {
    final isActive = playback.isSleepTimerActive;
    final remaining = playback.remainingSleepDuration;
    final text = isActive && remaining != null
        ? '${remaining.inMinutes}m'
        : 'Timer';

    return GestureDetector(
      onTap: () => _showSleepTimerPicker(context, playback),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.secondaryContainer.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: AppDimensions.borderFull,
          border: Border.all(
            color: isActive
                ? AppColors.secondaryHighlight
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bedtime,
              size: 14,
              color: isActive ? AppColors.secondaryHighlight : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTypography.labelSmall(
                color: isActive ? AppColors.secondaryHighlight : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Badge Widget ---
  Widget _buildBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppDimensions.borderFull,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSmall(color: color)),
        ],
      ),
    );
  }

  // --- AI Copilot Realtime Insights Card ---
  Widget _buildAiCopilotInsightCard(BuildContext context, MediaItemModel? media) {
    return GlassContainer(
      elevation: GlassElevation.level1,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: AppDimensions.borderMd,
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: AppColors.secondaryHighlight,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Copilot Insight',
                  style: AppTypography.labelSmall(color: AppColors.secondaryHighlight).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Calm twilight vibe • Matches your "Evening Chill" habit.',
                  style: AppTypography.bodySmall(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ AI Copilot: Generated 10 matching tracks for your evening session!'),
                  backgroundColor: AppColors.secondaryContainer,
                ),
              );
            },
            child: Text(
              'More AI',
              style: AppTypography.labelSmall(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // --- Up-Next Queue Section ---
  Widget _buildQueueSection(BuildContext context, PlaybackEngineService playback) {
    final queue = playback.queue;

    return GlassContainer(
      elevation: GlassElevation.level1,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      borderRadius: AppDimensions.borderLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.queue_music, color: AppColors.primaryContainer, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Up Next (${queue.length})',
                    style: AppTypography.titleMedium(color: AppColors.onSurface),
                  ),
                ],
              ),
              Text(
                'Auto-Queue Active',
                style: AppTypography.labelSmall(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (queue.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Queue is empty. Select files from Library.',
                style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: queue.length.clamp(0, 4),
              itemBuilder: (ctx, i) {
                final item = queue[i];
                final isCurrent = i == playback.queueIndex;

                return Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primaryContainer.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCurrent ? Icons.volume_up : (item.isVideo ? Icons.videocam : Icons.audiotrack),
                        color: isCurrent ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: AppTypography.titleMedium(
                        color: isCurrent ? AppColors.primaryContainer : AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.artist} • ${item.format}',
                      style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                    ),
                    trailing: Text(
                      item.formattedDuration,
                      style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                    ),
                    onTap: () => playback.setQueue(queue, startIndex: i),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Modals & Pickers ---
  void _showSleepTimerPicker(BuildContext context, PlaybackEngineService playback) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
            padding: const EdgeInsets.all(AppDimensions.spaceXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sleep Timer with Audio Fade-out', style: AppTypography.headlineSmall()),
                const SizedBox(height: 8),
                Text(
                  'Music automatically fades out smoothly in the final minute.',
                  style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [15, 30, 45, 60, 90].map((minutes) {
                    return ActionChip(
                      label: Text('$minutes min'),
                      onPressed: () {
                        playback.startSleepTimer(Duration(minutes: minutes), fadeOut: true);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🌙 Sleep Timer set for $minutes minutes!'),
                            backgroundColor: AppColors.secondaryContainer,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    side: const BorderSide(color: AppColors.primaryContainer),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Ouvrir Minuteur Avancé & Fondu'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdvancedSleepTimerScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (playback.isSleepTimerActive)
                  TextButton(
                    onPressed: () {
                      playback.cancelSleepTimer();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Cancel Active Timer', style: TextStyle(color: AppColors.error)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMediaOptions(BuildContext context, MediaItemModel? media) {
    if (media == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.primaryContainer),
                  title: const Text('File Information'),
                  subtitle: Text('${media.filePath}\nFormat: ${media.format} • Size: ${media.formattedSize}'),
                ),
                ListTile(
                  leading: const Icon(Icons.equalizer, color: AppColors.secondaryHighlight),
                  title: const Text('Sound Equalizer & DSP'),
                  subtitle: const Text('Adjust bass boost, 10-band studio EQ presets'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, MediaItemModel? media) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: const Text('Add to Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add, color: AppColors.primaryContainer),
              title: const Text('Chill Evening Mix'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to "Chill Evening Mix"')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: AppColors.secondaryHighlight),
              title: const Text('Afrobeats Workout'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to "Afrobeats Workout"')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

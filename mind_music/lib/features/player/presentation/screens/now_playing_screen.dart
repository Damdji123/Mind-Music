import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/media_item_model.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/utils/media_actions_helper.dart';
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

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  double _dragPosition = -1.0;
  bool _isDragging = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

    final maxMs =
        duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Scaffold(
      body: LiquidGlowBackground(
        primaryGlow:
            isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
        secondaryGlow:
            isVideo ? const Color(0xFF6366F1) : AppColors.secondaryContainer,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.margin,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),

                      // Audio / Video Viewport with Liquid Morphism
                      if (isVideo)
                        _buildVideoViewport(playback)
                      else
                        _buildLiquidAudioArtwork(media, playback.isPlaying),

                      const SizedBox(height: 16),

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
                                  style: AppTypography.headlineMedium(
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        media?.artist ?? 'Unknown Artist',
                                        style: AppTypography.titleMedium(
                                          color: AppColors.onSurfaceSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.primaryContainer,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '• ${media?.album ?? 'Local Storage'}',
                                        style: AppTypography.bodySmall(
                                          color: AppColors.onSurfaceMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? AppColors.error
                                  : AppColors.onSurfaceSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isFavorite
                                      ? '❤️ Added to Favorites'
                                      : 'Removed from Favorites'),
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
                            onPressed: () =>
                                _showAddToPlaylistDialog(context, media),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Format Badges (Horizontal scrollable to prevent overflow)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildBadge(
                              icon: Icons.graphic_eq,
                              label: media?.isHiRes == true
                                  ? 'Lossless • 24b/96k'
                                  : (media?.format ?? 'AUDIO'),
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
                            const SizedBox(width: 8),
                            _buildBadge(
                              icon: Icons.offline_bolt,
                              label: 'Offline Direct',
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // AI Copilot Realtime Insights Pill
                      _buildAiCopilotInsightCard(context, media),

                      const SizedBox(height: 16),

                      // 3. Interactive Scrub Bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7.0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16.0,
                          ),
                          activeTrackColor: isVideo
                              ? AppColors.secondaryHighlight
                              : AppColors.primaryContainer,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.15),
                          thumbColor: isVideo
                              ? AppColors.secondaryHighlight
                              : AppColors.primaryContainer,
                          overlayColor:
                              AppColors.primaryContainer.withValues(alpha: 0.2),
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
                              style: AppTypography.labelSmall(
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              'Buffer 100% Local',
                              style: AppTypography.labelSmall(
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: AppTypography.labelSmall(
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Secondary Quick Seeking & Equalizer Bar (Never overflows)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                foregroundColor: AppColors.onSurfaceSecondary,
                              ),
                              icon: const Icon(Icons.replay_10, size: 20),
                              label: const Text(
                                '-10s',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                final newPos = playback.position -
                                    const Duration(seconds: 10);
                                playback.seek(newPos < Duration.zero
                                    ? Duration.zero
                                    : newPos);
                              },
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EqualizerScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      size: 14,
                                      color: AppColors.primaryContainer,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Equalizer',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                foregroundColor: AppColors.onSurfaceSecondary,
                              ),
                              icon: const Text(
                                '+10s',
                                style: TextStyle(fontSize: 12),
                              ),
                              label: const Icon(Icons.forward_10, size: 20),
                              onPressed: () {
                                final newPos = playback.position +
                                    const Duration(seconds: 10);
                                playback.seek(newPos > playback.duration
                                    ? playback.duration
                                    : newPos);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 4. Hero Main Control Deck: 5 Spacious, Beautifully Balanced Controls
                      // [Shuffle]  [Previous]  [Hero Play/Pause]  [Next]  [Repeat/Loop]
                      // ZERO OVERFLOW GUARANTEE: 5 controls fit comfortably across any phone width!
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 1. Shuffle Button
                            IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: playback.isShuffle
                                    ? AppColors.primaryContainer
                                    : AppColors.onSurfaceMuted,
                                size: 24,
                              ),
                              tooltip: 'Shuffle',
                              onPressed: playback.toggleShuffle,
                            ),

                            // 2. Skip Previous
                            IconButton(
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                size: 38,
                              ),
                              color: AppColors.onSurface,
                              tooltip: 'Previous',
                              onPressed: playback.skipPrevious,
                            ),

                            // 3. Hero Centered Play / Pause Button with Liquid Glass Glow
                            _buildHeroPlayButton(playback, isVideo),

                            // 4. Skip Next
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 38,
                              ),
                              color: AppColors.onSurface,
                              tooltip: 'Next',
                              onPressed: playback.skipNext,
                            ),

                            // 5. Repeat / Loop Mode (Always 100% visible on right)
                            IconButton(
                              icon: Icon(
                                playback.loopMode == LoopMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                color: playback.loopMode != LoopMode.off
                                    ? AppColors.primaryContainer
                                    : AppColors.onSurfaceMuted,
                                size: 24,
                              ),
                              tooltip: 'Loop Mode',
                              onPressed: playback.toggleLoopMode,
                            ),
                          ],
                        ),
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

  // --- Hero Play / Pause Button with Liquid Morphism & Caustic Glass ---
  Widget _buildHeroPlayButton(PlaybackEngineService playback, bool isVideo) {
    final glowColor =
        isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseScale = playback.isPlaying
            ? 1.0 + (_pulseController.value * 0.04)
            : 1.0;

        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: playback.isPlaying
                        ? 0.45 + (_pulseController.value * 0.2)
                        : 0.3,
                  ),
                  blurRadius: playback.isPlaying ? 36 : 24,
                  spreadRadius: playback.isPlaying ? 3 : 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(36),
                onTap: playback.playPause,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor.withValues(alpha: 0.40),
                        const Color(0xFF0F172A).withValues(alpha: 0.90),
                      ],
                    ),
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.85),
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      playback.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Liquidmorphic & Glassmorphic Audio Artwork Viewport ---
  Widget _buildLiquidAudioArtwork(MediaItemModel? media, bool isPlaying) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt dynamically to available screen width (max 280, min 200)
        final double size =
            (constraints.maxWidth * 0.72).clamp(200.0, 280.0);

        return Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double auraPulse = isPlaying
                  ? 0.25 + (_pulseController.value * 0.15)
                  : 0.18;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Liquid Photon Aura Pool behind artwork
                  Container(
                    width: size * 1.15,
                    height: size * 1.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryContainer
                              .withValues(alpha: auraPulse),
                          AppColors.secondaryContainer
                              .withValues(alpha: auraPulse * 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // 2. Frosted Glassmorphic Artwork Capsule
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E293B).withValues(alpha: 0.85),
                          const Color(0xFF0F172A).withValues(alpha: 0.95),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer
                              .withValues(alpha: 0.3),
                          blurRadius: 36,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Refractive specular top-left shine
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                            // Central Musical Glyph
                            Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryContainer
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  size: 46,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),

                            // Dynamic Live Visualizer Bars at the bottom
                            Positioned(
                              left: 24,
                              right: 24,
                              bottom: 16,
                              child: _buildDynamicVisualizer(isPlaying),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
            },
          ),
        );
      },
    );
  }

  // --- Dynamic Animated Waveform Visualizer ---
  Widget _buildDynamicVisualizer(bool isPlaying) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        final heights = [12.0, 20.0, 28.0, 16.0, 24.0, 14.0, 8.0];
        final factor = isPlaying
            ? (0.4 + (((i * 3 + (_pulseController.value * 7)) % 7) / 7.0))
            : 0.3;
        final h = heights[i] * factor;

        return Container(
          width: 4,
          height: h.clamp(6.0, 30.0),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.primaryContainer,
                AppColors.secondaryHighlight,
              ],
            ),
          ),
        );
      }),
    );
  }

  // --- Video Viewport ---
  Widget _buildVideoViewport(PlaybackEngineService playback) {
    final controller = playback.videoController;

    return Center(
      child: Container(
        width: double.infinity,
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black,
          border: Border.all(
            color: AppColors.secondaryHighlight.withValues(alpha: 0.35),
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
                    Icon(
                      Icons.smart_display,
                      size: 64,
                      color: AppColors.secondaryHighlight,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Local 4K Video Preview Active',
                      style: TextStyle(color: Colors.white70),
                    ),
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
                playback
                    .playMedia(playback.currentMedia!.copyWith(isVideo: false));
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
                playback
                    .playMedia(playback.currentMedia!.copyWith(isVideo: true));
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
          color: isSelected
              ? color.withValues(alpha: 0.25)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.6))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : AppColors.onSurfaceMuted,
            ),
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
  Widget _buildSleepTimerChip(
      BuildContext context, PlaybackEngineService playback) {
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
              color: isActive
                  ? AppColors.secondaryHighlight
                  : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTypography.labelSmall(
                color: isActive
                    ? AppColors.secondaryHighlight
                    : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Badge Widget ---
  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
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
  Widget _buildAiCopilotInsightCard(
      BuildContext context, MediaItemModel? media) {
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
                  style: AppTypography.labelSmall(
                    color: AppColors.secondaryHighlight,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Calm ambient vibe • Matches your offline listening habit.',
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
                  content: Text(
                    '✨ AI Copilot: Analyzing local track audio tags & BPM...',
                  ),
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
  Widget _buildQueueSection(
      BuildContext context, PlaybackEngineService playback) {
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
                  const Icon(
                    Icons.queue_music,
                    color: AppColors.primaryContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Up Next (${queue.length})',
                    style: AppTypography.titleMedium(color: AppColors.onSurface),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showReorderableQueueSheet(context, playback),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.reorder, size: 14, color: AppColors.primaryContainer),
                      SizedBox(width: 4),
                      Text(
                        'Reorder & Manage',
                        style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isCurrent
                        ? AppColors.primaryContainer.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.primaryContainer
                                .withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCurrent ? Icons.play_arrow : Icons.music_note,
                        size: 16,
                        color: isCurrent
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTypography.bodyMedium(
                            color: isCurrent
                                ? AppColors.primaryContainer
                                : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item.formattedDuration,
                        style: AppTypography.labelSmall(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Interactive Drag-and-Drop Up-Next Queue Sheet ---
  void _showReorderableQueueSheet(
      BuildContext context, PlaybackEngineService playback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final queue = playback.queue;

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Up-Next Queue',
                            style: AppTypography.headlineSmall(),
                          ),
                          Text(
                            '${queue.length} tracks • Drag handle to reorder',
                            style: AppTypography.labelSmall(
                                color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                      if (queue.length > 1)
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          onPressed: () {
                            playback.clearQueue();
                            setSheetState(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.glassBorderSubtle, height: 1),
                  const SizedBox(height: 8),
                  if (queue.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Queue is empty. Select tracks from Library.',
                          style: TextStyle(color: AppColors.onSurfaceMuted),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ReorderableListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: queue.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          playback.reorderQueue(oldIndex, newIndex);
                          setSheetState(() {});
                        },
                        itemBuilder: (c, i) {
                          final item = queue[i];
                          final isCurrent = i == playback.queueIndex;

                          return Container(
                            key: ValueKey('${item.id}_$i'),
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isCurrent
                                  ? AppColors.primaryContainer
                                      .withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.primaryContainer
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCurrent
                                      ? Icons.play_arrow_rounded
                                      : Icons.music_note_rounded,
                                  color: isCurrent
                                      ? AppColors.primaryContainer
                                      : AppColors.onSurfaceMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      playback.setQueue(playback.queue,
                                          startIndex: i);
                                      setSheetState(() {});
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: AppTypography.titleMedium(
                                            color: isCurrent
                                                ? AppColors.primaryContainer
                                                : AppColors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${item.artist} • ${item.formattedDuration}',
                                          style: AppTypography.labelSmall(
                                              color: AppColors.onSurfaceMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  color: AppColors.onSurfaceMuted,
                                  tooltip: 'Remove from Queue',
                                  onPressed: () {
                                    playback.removeFromQueue(i);
                                    setSheetState(() {});
                                  },
                                ),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: AppColors.onSurfaceMuted,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Modal Helpers ---
  void _showSleepTimerPicker(
      BuildContext context, PlaybackEngineService playback) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const AdvancedSleepTimerScreen(),
    );
  }

  void _showMediaOptions(BuildContext context, MediaItemModel? media) {
    if (media == null) return;
    MediaActionsHelper.showMediaOptionsSheet(context, media);
  }

  void _showAddToPlaylistDialog(
      BuildContext context, MediaItemModel? media) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add to Playlist', style: AppTypography.titleMedium()),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.primaryContainer),
                title: const Text('Create New Playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening Playlist Creator...'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play),
                title: const Text('Favorites'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to Favorites')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

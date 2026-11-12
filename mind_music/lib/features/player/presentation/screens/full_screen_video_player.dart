import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/widgets/glass_icon_button.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  const FullScreenVideoPlayer({super.key});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;
  double _volume = 0.85;
  double _brightness = 0.75;
  BoxFit _videoFit = BoxFit.contain;
  String _aspectRatioLabel = '16:9';

  @override
  void initState() {
    super.initState();
    // Enable immersive landscape or sticky immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _toggleAspectRatio() {
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover;
        _aspectRatioLabel = 'Fill';
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fitWidth;
        _aspectRatioLabel = 'Fit Width';
      } else {
        _videoFit = BoxFit.contain;
        _aspectRatioLabel = '16:9';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackEngineService>();
    final controller = playback.videoController;
    final media = playback.currentMedia;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        // Gesture Brightness (Left vertical drag) & Volume (Right vertical drag)
        onVerticalDragUpdate: (details) {
          final isLeft = details.globalPosition.dx < MediaQuery.of(context).size.width / 2;
          setState(() {
            if (isLeft) {
              _brightness = (_brightness - details.delta.dy / 200).clamp(0.0, 1.0);
            } else {
              _volume = (_volume - details.delta.dy / 200).clamp(0.0, 1.0);
            }
          });
        },
        // Double-tap seek
        onDoubleTapDown: (details) {
          final isRight = details.globalPosition.dx > MediaQuery.of(context).size.width / 2;
          final offset = isRight ? const Duration(seconds: 10) : const Duration(seconds: -10);
          playback.seek(playback.position + offset);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Viewport
            if (controller != null && controller.value.isInitialized)
              FittedBox(
                fit: _videoFit,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.movie_creation_outlined, size: 72, color: AppColors.secondaryHighlight),
                    const SizedBox(height: 12),
                    Text(
                      media?.title ?? '4K Video Playing',
                      style: AppTypography.headlineSmall(color: Colors.white),
                    ),
                  ],
                ),
              ),

            // Controls Overlay
            if (_showControls) ...[
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      GlassIconButton(
                        icon: Icons.arrow_back,
                        size: 38,
                        iconSize: 20,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media?.title ?? '4K Video Player',
                              style: AppTypography.titleMedium(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '4K HDR • 60fps • 100% Local',
                              style: AppTypography.labelSmall(color: AppColors.secondaryHighlight),
                            ),
                          ],
                        ),
                      ),
                      // Aspect Ratio Toggle
                      TextButton.icon(
                        icon: const Icon(Icons.aspect_ratio, size: 16, color: Colors.white70),
                        label: Text(_aspectRatioLabel, style: const TextStyle(color: Colors.white70)),
                        onPressed: _toggleAspectRatio,
                      ),
                      // Audio Track Selector
                      TextButton.icon(
                        icon: const Icon(Icons.audiotrack, size: 16, color: Colors.white70),
                        label: const Text('ENG 5.1', style: TextStyle(color: Colors.white70)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio stream: English 5.1 Surround selected')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Center Controls (10s Rewind, Play/Pause, 10s Forward)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassIconButton(
                      icon: Icons.replay_10,
                      size: 54,
                      iconSize: 28,
                      onPressed: () {
                        playback.seek(playback.position - const Duration(seconds: 10));
                      },
                    ),
                    const SizedBox(width: 32),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x6638BDF8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          playback.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: playback.playPause,
                      ),
                    ),
                    const SizedBox(width: 32),
                    GlassIconButton(
                      icon: Icons.forward_10,
                      size: 54,
                      iconSize: 28,
                      onPressed: () {
                        playback.seek(playback.position + const Duration(seconds: 10));
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Scrub & Status Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HUD: Brightness & Volume Indicator Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.light_mode, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${(_brightness * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.volume_up, color: AppColors.primaryContainer, size: 16),
                              const SizedBox(width: 4),
                              Text('${(_volume * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Video Scrub Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          activeTrackColor: AppColors.secondaryHighlight,
                          thumbColor: AppColors.secondaryHighlight,
                        ),
                        child: Slider(
                          value: playback.position.inMilliseconds.toDouble().clamp(
                                0.0,
                                playback.duration.inMilliseconds.toDouble() > 0
                                    ? playback.duration.inMilliseconds.toDouble()
                                    : 1.0,
                              ),
                          min: 0.0,
                          max: playback.duration.inMilliseconds.toDouble() > 0
                              ? playback.duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (val) {
                            playback.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(playback.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(_formatDuration(playback.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../../core/widgets/native_ad_card.dart';
import '../widgets/continue_listening_card.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/media_stats_row.dart';
import '../widgets/quick_ai_bar.dart';
import '../../../ai_copilot/presentation/screens/ai_voice_assistant_screen.dart';
import '../../../library/presentation/screens/local_library_screen.dart';
import '../../../player/presentation/screens/now_playing_screen.dart';
import '../../../playlists/presentation/screens/playlists_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<StorageScannerService>();
    final playback = context.watch<PlaybackEngineService>();

    return Scaffold(
      body: LiquidGlowBackground(
        child: Stack(
          children: [
            // Scrollable Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Custom Header with AppLogo (Positioned cleanly below status bar & camera notch)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.margin,
                      MediaQuery.of(context).padding.top + 16.0,
                      AppDimensions.margin,
                      AppDimensions.spaceMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const AppLogo(size: 46),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mind-Music',
                                      style: AppTypography.headlineMedium(color: AppColors.onSurface).copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Version 1.0 • Liquid Glass',
                                      style: AppTypography.labelSmall(color: AppColors.primaryContainer).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassIconButton(
                              icon: Icons.sync,
                              size: 42,
                              iconSize: 22,
                              onPressed: () {
                                scanner.scanDeviceStorage();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🔍 Scanning local device storage for music & video...'),
                                    backgroundColor: AppColors.surfaceContainerHigh,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            GlassIconButton(
                              icon: Icons.settings_rounded,
                              size: 42,
                              iconSize: 22,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Scanning Progress Indicator if active
                if (scanner.isScanning)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Indexing local media files...',
                                style: AppTypography.labelSmall(color: AppColors.primary),
                              ),
                              Text(
                                '${(scanner.scanProgress * 100).toInt()}%',
                                style: AppTypography.labelSmall(color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: scanner.scanProgress > 0 ? scanner.scanProgress : null,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(AppColors.primaryContainer),
                            minHeight: 3,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                // Native Ad Card (Free Tier: Tasteful ad in non-critical screen; Pro Tier: Auto-Hidden)
                const SliverToBoxAdapter(
                  child: NativeAdCard(screenName: 'HomeScreen'),
                ),

                // Continue Listening
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                    child: ContinueListeningCard(
                      mediaItem: playback.currentMedia ??
                          (scanner.audioFiles.isNotEmpty ? scanner.audioFiles.first : null),
                      isPlaying: playback.isPlaying,
                      position: playback.position,
                      duration: playback.duration > Duration.zero
                          ? playback.duration
                          : (playback.currentMedia?.duration ?? const Duration(minutes: 3, seconds: 56)),
                      onCardTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                        );
                      },
                      onPlayTap: () {
                        if (playback.currentMedia == null && scanner.audioFiles.isNotEmpty) {
                          playback.setQueue(scanner.audioFiles, startIndex: 0);
                        } else {
                          playback.playPause();
                        }
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spaceLg)),

                // Quick AI Copilot
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                    child: QuickAiBar(
                      onOpenAssistant: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiVoiceAssistantScreen()),
                        );
                      },
                      onCommandSubmitted: (cmd) {
                        final lower = cmd.toLowerCase();
                        if (lower.contains('play') || lower.contains('joue')) {
                          if (scanner.audioFiles.isNotEmpty) {
                            playback.setQueue(scanner.audioFiles, startIndex: 0);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✨ AI Copilot: Playing matching media for "$cmd"'),
                              backgroundColor: AppColors.secondaryContainer,
                            ),
                          );
                        } else if (lower.contains('timer') || lower.contains('sleep') || lower.contains('arrête')) {
                          playback.startSleepTimer(const Duration(minutes: 45), fadeOut: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🌙 AI Copilot: Sleep timer set for 45 minutes with gentle fade-out.'),
                              backgroundColor: AppColors.secondaryContainer,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✨ AI Copilot Executing: "$cmd"'),
                              backgroundColor: AppColors.secondaryContainer,
                            ),
                          );
                        }
                      },
                      onVoiceTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiVoiceAssistantScreen()),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spaceLg)),

                // Local Media Files Stats connected to StorageScannerService
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                    child: MediaStatsRow(
                      musicCount: scanner.audioFiles.length,
                      videoCount: scanner.videoFiles.length,
                      folderCount: scanner.folders.keys.length,
                      onCategoryTap: (index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocalLibraryScreen(initialTabIndex: index),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spaceLg)),

                // Recommended AI Smart Mixes Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Smart Mixes & Collections',
                          style: AppTypography.titleMedium(color: AppColors.onSurface),
                        ),
                        Text(
                          'View All (${scanner.folders.keys.length})',
                          style: AppTypography.labelSmall(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spaceSm)),

                // Horizontal Mix Cards Carousel
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                      children: [
                        _buildMixCard(
                          title: 'Daily Chill & Focus',
                          trackCount: '${scanner.audioFiles.length} tracks',
                          duration: '1h 42m',
                          icon: Icons.grain,
                          accentColor: AppColors.primaryContainer,
                          onTap: () {
                            if (scanner.audioFiles.isNotEmpty) {
                              playback.setQueue(scanner.audioFiles, startIndex: 0);
                            }
                          },
                        ),
                        const SizedBox(width: AppDimensions.spaceMd),
                        _buildMixCard(
                          title: 'Videos & Visuals',
                          trackCount: '${scanner.videoFiles.length} videos',
                          duration: '45m total',
                          icon: Icons.smart_display_outlined,
                          accentColor: AppColors.secondaryHighlight,
                          onTap: () {
                            if (scanner.videoFiles.isNotEmpty) {
                              playback.playMedia(scanner.videoFiles.first);
                            }
                          },
                        ),
                        const SizedBox(width: AppDimensions.spaceMd),
                        _buildMixCard(
                          title: 'Late Night Ambient',
                          trackCount: '19 tracks',
                          duration: '1h 15m',
                          icon: Icons.nightlife,
                          accentColor: AppColors.tertiary,
                          onTap: () {
                            if (scanner.audioFiles.length > 1) {
                              playback.setQueue(scanner.audioFiles, startIndex: 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding to ensure content clears floating navbar
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.bottomNavClearance),
                ),
              ],
            ),

            // Floating Liquid Glass Navigation Pod
            FloatingNavBar(
              currentIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocalLibraryScreen()),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
                  );
                } else if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiVoiceAssistantScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixCard({
    required String title,
    required String trackCount,
    required String duration,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      elevation: GlassElevation.level1,
      width: 220,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      borderRadius: AppDimensions.borderMd,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              Text(
                'AI MIX',
                style: AppTypography.labelSmall(color: accentColor).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium(color: AppColors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$trackCount • $duration',
                style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

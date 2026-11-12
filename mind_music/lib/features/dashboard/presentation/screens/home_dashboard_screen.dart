import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../../core/widgets/native_ad_card.dart';
import '../../../../core/widgets/premium_badge.dart';
import '../widgets/continue_listening_card.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/media_stats_row.dart';
import '../widgets/quick_ai_bar.dart';
import '../../../ai_copilot/presentation/screens/ai_voice_assistant_screen.dart';
import '../../../library/presentation/screens/local_library_screen.dart';
import '../../../player/presentation/screens/now_playing_screen.dart';
import '../../../playlists/presentation/screens/playlists_screen.dart';

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
                // Top Custom Header with AppLogo
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.margin,
                      AppDimensions.spaceSm,
                      AppDimensions.margin,
                      AppDimensions.spaceMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const AppLogo(size: 38),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mind-Music',
                                  style: AppTypography.headlineSmall(color: AppColors.onSurface),
                                ),
                                Text(
                                  'Liquid Glass Edition',
                                  style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const PremiumBadge(),
                            const SizedBox(width: 8),
                            GlassIconButton(
                              icon: Icons.sync,
                              size: 38,
                              iconSize: 20,
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
                              icon: Icons.tune,
                              size: 38,
                              iconSize: 20,
                              onPressed: () => _showThemeAndSettingsDialog(context),
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

  void _showThemeAndSettingsDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Text('App Preferences', style: AppTypography.headlineSmall()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aesthetic Theme Engine', style: AppTypography.labelMedium()),
            const SizedBox(height: 8),
            _buildThemeOption(ctx, themeProvider, AppThemeMode.liquidGlass, 'Liquid Glass (Default)'),
            _buildThemeOption(ctx, themeProvider, AppThemeMode.oledDark, 'OLED Ultra Dark'),
            _buildThemeOption(ctx, themeProvider, AppThemeMode.cyberpunk, 'Cyberpunk Neon'),
            _buildThemeOption(ctx, themeProvider, AppThemeMode.sunset, 'Sunset Glow'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext ctx,
    ThemeProvider provider,
    AppThemeMode mode,
    String title,
  ) {
    final isSelected = provider.currentMode == mode;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
      ),
      title: Text(title, style: AppTypography.bodyMedium(color: AppColors.onSurface)),
      onTap: () {
        provider.setTheme(mode);
        Navigator.pop(ctx);
      },
    );
  }
}

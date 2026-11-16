import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/playlist_model.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/services/playlist_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../../core/widgets/native_ad_card.dart';
import '../../../player/presentation/screens/now_playing_screen.dart';
import 'create_ai_playlist_screen.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<List<Color>> _coverGradients = [
    [const Color(0xFF0284C7), const Color(0xFF7C3AED)],
    [const Color(0xFFD97706), const Color(0xFFDC2626)],
    [const Color(0xFF059669), const Color(0xFF0284C7)],
    [const Color(0xFF9333EA), const Color(0xFFEC4899)],
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistService = context.watch<PlaylistService>();
    final playbackService = context.watch<PlaybackEngineService>();
    final adsService = context.watch<AdsService>();
    final playlists = playlistService.filteredPlaylists;
    final featured = playlistService.featuredAiMix;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidGlowBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.margin,
                    vertical: AppDimensions.spaceSm,
                  ),
                  children: [
                    // Header with Title & CTA
                    _buildSubHeader(context, playlistService),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // Search Bar
                    _buildSearchBar(playlistService),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // Filter Chips
                    _buildFilterChips(playlistService),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // Featured Bento Card
                    if (featured != null && playlistService.selectedFilter != 'user') ...[
                      _buildFeaturedAiCard(context, featured, playbackService, playlistService),
                      const SizedBox(height: AppDimensions.spaceLg),
                    ],

                    // Native ad for free tier
                    if (adsService.shouldShowAds) ...[
                      const NativeAdCard(),
                      const SizedBox(height: AppDimensions.spaceMd),
                    ],

                    // Playlist Grid / List
                    _buildPlaylistsSection(context, playlists, playbackService, playlistService),

                    const SizedBox(height: 100), // Spacing for mini-player
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const AppLogo(size: 32),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MYPLAYER',
                        style: AppTypography.labelSmall(
                          color: AppColors.onSurfaceMuted,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Playlists & Mix',
                        style: AppTypography.titleMedium(color: AppColors.onSurface),
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
            children: [
              GlassIconButton(
                icon: Icons.settings,
                size: 40,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings opened')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(BuildContext context, PlaylistService playlistService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Playlists', style: AppTypography.headlineLarge()),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${playlistService.allPlaylists.length}',
                      style: AppTypography.labelSmall(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Collections locales & mix IA synchronisés',
                style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            GlassIconButton(
              icon: Icons.swap_vert,
              size: 42,
              onPressed: () => _showSortModal(context),
            ),
            const SizedBox(width: 8),
            GlassButton(
              label: 'Créer',
              icon: const Icon(Icons.add, size: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateAiPlaylistScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(PlaylistService service) {
    return GlassTextField(
      controller: _searchController,
      hintText: 'Rechercher dans mes playlists...',
      leading: const Icon(Icons.search, color: AppColors.onSurfaceMuted, size: 20),
      onChanged: (val) => service.setSearchQuery(val),
      onVoicePressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recherche vocale activée...')),
        );
      },
    );
  }

  Widget _buildFilterChips(PlaylistService service) {
    final filters = [
      {'id': 'all', 'label': 'Toutes (${service.allPlaylists.length})', 'icon': null},
      {
        'id': 'user',
        'label': 'Créées par moi (${service.allPlaylists.where((p) => !p.isAiGenerated).length})',
        'icon': null,
      },
      {
        'id': 'ai',
        'label': 'Mix IA & Smart (${service.allPlaylists.where((p) => p.isAiGenerated).length})',
        'icon': Icons.auto_awesome,
      },
      {
        'id': 'favorites',
        'label': 'Favoris (${service.allPlaylists.where((p) => p.isFavorite).length})',
        'icon': Icons.favorite,
      },
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final isSelected = service.selectedFilter == f['id'];
          final IconData? icon = f['icon'] as IconData?;

          return Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => service.setFilter(f['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryContainer : AppColors.glassBorderSubtle,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected && icon == null) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected ? AppColors.primaryContainer : AppColors.secondaryHighlight,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      f['label'] as String,
                      style: AppTypography.labelMedium(
                        color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedAiCard(
    BuildContext context,
    PlaylistModel playlist,
    PlaybackEngineService playback,
    PlaylistService playlistService,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        customGradient: LinearGradient(
          colors: [
            AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
            AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.secondaryHighlight, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'GÉNÉRÉ CE MATIN',
                        style: AppTypography.labelSmall(
                          color: AppColors.secondaryHighlight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.primaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      playlist.formattedDuration,
                      style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _coverGradients[playlist.coverGradientIndex % _coverGradients.length],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.grain, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: AppTypography.titleMedium(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playlist.description,
                        style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    if (playlist.tracks.isNotEmpty) {
                      playback.setQueue(playlist.tracks, startIndex: 0);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsSection(
    BuildContext context,
    List<PlaylistModel> playlists,
    PlaybackEngineService playback,
    PlaylistService service,
  ) {
    if (playlists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.queue_music, size: 48, color: AppColors.onSurfaceMuted),
              const SizedBox(height: 12),
              Text('Aucune playlist trouvée', style: AppTypography.titleMedium()),
              const SizedBox(height: 4),
              Text(
                'Créez une nouvelle playlist ou modifiez vos filtres.',
                style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (ctx, i) {
        final pl = playlists[i];
        final gradient = _coverGradients[pl.coverGradientIndex % _coverGradients.length];

        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlistId: pl.id),
                ),
              );
            },
            child: GlassContainer(
              padding: const EdgeInsets.all(AppDimensions.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover
                  Stack(
                    children: [
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            pl.isAiGenerated ? Icons.smart_toy : Icons.music_note,
                            size: 38,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: () => service.toggleFavorite(pl.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              pl.isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: pl.isFavorite ? AppColors.error : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (pl.bpmRange != null)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pl.bpmRange!,
                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pl.name,
                          style: AppTypography.titleMedium(color: AppColors.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildPlaylistContextMenu(context, pl, playback, service),
                    ],
                  ),
                  Text(
                    '${pl.trackCount} titres • ${pl.formattedDuration}',
                    style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistContextMenu(
    BuildContext context,
    PlaylistModel pl,
    PlaybackEngineService playback,
    PlaylistService service,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.onSurfaceMuted),
      color: AppColors.surfaceContainerLowest,
      onSelected: (val) {
        if (val == 'details') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlistId: pl.id),
            ),
          );
        } else if (val == 'play') {
          if (pl.tracks.isNotEmpty) {
            playback.setQueue(pl.tracks, startIndex: 0);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
            );
          }
        } else if (val == 'duplicate') {
          service.duplicatePlaylist(pl.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playlist "${pl.name}" dupliquée')),
          );
        } else if (val == 'delete') {
          service.deletePlaylist(pl.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playlist supprimée')),
          );
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.queue_music, size: 18, color: AppColors.onSurface),
              SizedBox(width: 8),
              Text('Détails & Titres'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'play',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18, color: AppColors.primaryContainer),
              SizedBox(width: 8),
              Text('Lire la playlist'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18, color: AppColors.onSurface),
              SizedBox(width: 8),
              Text('Dupliquer'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Supprimer'),
            ],
          ),
        ),
      ],
    );
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trier les playlists', style: AppTypography.headlineSmall()),
            const SizedBox(height: 12),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.date_range, color: AppColors.primaryContainer),
                title: const Text('Récemment ajoutées'),
                onTap: () => Navigator.pop(ctx),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.sort_by_alpha, color: AppColors.primaryContainer),
                title: const Text('Ordre alphabétique (A-Z)'),
                onTap: () => Navigator.pop(ctx),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.music_note, color: AppColors.secondaryHighlight),
                title: const Text('Nombre de morceaux'),
                onTap: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

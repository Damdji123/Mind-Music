import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/media_item_model.dart';
import '../../../../core/models/playlist_model.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/services/playlist_service.dart';
import '../../../../core/utils/media_actions_helper.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../player/presentation/screens/now_playing_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  static final List<List<Color>> _coverGradients = [
    [const Color(0xFF0284C7), const Color(0xFF7C3AED)],
    [const Color(0xFFD97706), const Color(0xFFDC2626)],
    [const Color(0xFF059669), const Color(0xFF0284C7)],
    [const Color(0xFF9333EA), const Color(0xFFEC4899)],
  ];

  @override
  Widget build(BuildContext context) {
    final playlistService = context.watch<PlaylistService>();
    final playbackService = context.watch<PlaybackEngineService>();

    final playlistIndex = playlistService.allPlaylists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Playlist introuvable',
            style: TextStyle(color: AppColors.onSurfaceMuted),
          ),
        ),
      );
    }

    final playlist = playlistService.allPlaylists[playlistIndex];
    final gradient = _coverGradients[playlist.coverGradientIndex % _coverGradients.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidGlowBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(context, playlist, playlistService),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.margin,
                          vertical: AppDimensions.spaceSm,
                        ),
                        child: _buildHeader(context, playlist, gradient, playbackService, playlistService),
                      ),
                    ),
                    if (playlist.tracks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.margin,
                          AppDimensions.spaceSm,
                          AppDimensions.margin,
                          100, // padding for mini-player
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildReorderableTrackList(
                            context,
                            playlist,
                            playbackService,
                            playlistService,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlaylistModel playlist, PlaylistService service) {
    return Container(
      height: 60,
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
          Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back,
                size: 38,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'Détails de la playlist',
                style: AppTypography.titleMedium(color: AppColors.onSurface),
              ),
            ],
          ),
          Row(
            children: [
              GlassIconButton(
                icon: playlist.isFavorite ? Icons.favorite : Icons.favorite_border,
                iconColor: playlist.isFavorite ? AppColors.error : AppColors.onSurface,
                size: 38,
                onPressed: () => service.toggleFavorite(playlist.id),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.more_vert,
                size: 38,
                onPressed: () => _showPlaylistMenu(context, playlist, service),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    PlaylistModel playlist,
    List<Color> gradient,
    PlaybackEngineService playback,
    PlaylistService service,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    playlist.isAiGenerated ? Icons.auto_awesome : Icons.music_note,
                    size: 42,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (playlist.isAiGenerated) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.secondaryHighlight, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'SMART AI MIX',
                                  style: AppTypography.labelSmall(
                                    color: AppColors.secondaryHighlight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (playlist.bpmRange != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              playlist.bpmRange!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      playlist.name,
                      style: AppTypography.headlineSmall(color: AppColors.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (playlist.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        playlist.description,
                        style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${playlist.trackCount} titres • ${playlist.formattedDuration}',
                      style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions: Play All & Shuffle
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: const Text('Tout lire', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: playlist.tracks.isEmpty
                      ? null
                      : () {
                          playback.setQueue(playlist.tracks, startIndex: 0);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                          );
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.glassBorderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.shuffle, size: 20),
                  label: const Text('Aléatoire'),
                  onPressed: playlist.tracks.isEmpty
                      ? null
                      : () {
                          final shuffled = List<MediaItemModel>.from(playlist.tracks)..shuffle();
                          playback.setQueue(shuffled, startIndex: 0);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_off, size: 56, color: AppColors.onSurfaceMuted),
          const SizedBox(height: 12),
          Text('Cette playlist est vide', style: AppTypography.titleMedium()),
          const SizedBox(height: 6),
          Text(
            'Ajoutez des morceaux depuis votre bibliothèque locale.',
            style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableTrackList(
    BuildContext context,
    PlaylistModel playlist,
    PlaybackEngineService playback,
    PlaylistService service,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Titres (${playlist.tracks.length})',
                style: AppTypography.titleMedium(color: AppColors.onSurface),
              ),
              Text(
                'Glisser pour réorganiser',
                style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: playlist.tracks.length,
          buildDefaultDragHandles: false,
          // ignore: deprecated_member_use
          onReorder: (oldIndex, newIndex) {
            service.reorderTrack(playlist.id, oldIndex, newIndex);
          },
          itemBuilder: (ctx, index) {
            final track = playlist.tracks[index];
            final isCurrent = playback.currentMedia?.id == track.id;

            return Container(
              key: ValueKey('${track.id}_$index'),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: isCurrent
                    ? AppColors.primaryContainer.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCurrent
                        ? AppColors.primaryContainer.withValues(alpha: 0.4)
                        : AppColors.glassBorderSubtle,
                    width: 0.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primaryContainer.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          track.isVideo ? Icons.movie : Icons.music_note,
                          color: isCurrent ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                          size: 22,
                        ),
                      ),
                      if (isCurrent && playback.isPlaying)
                        const Icon(
                          Icons.equalizer,
                          color: AppColors.primaryContainer,
                          size: 22,
                        ),
                    ],
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? AppColors.primaryContainer : AppColors.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${track.artist} • ${track.formattedDuration}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent
                          ? AppColors.primaryContainer.withValues(alpha: 0.8)
                          : AppColors.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.onSurfaceMuted),
                        onPressed: () => _showTrackOptions(context, playlist, track, service, playback),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.drag_handle, color: AppColors.onSurfaceMuted, size: 22),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    playback.setQueue(playlist.tracks, startIndex: index);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showTrackOptions(
    BuildContext context,
    PlaylistModel playlist,
    MediaItemModel track,
    PlaylistService service,
    PlaybackEngineService playback,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_play, color: AppColors.primaryContainer),
                title: const Text('Lire ensuite'),
                onTap: () {
                  playback.playNext(track);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${track.title}" sera lu ensuite')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                title: const Text('Retirer de la playlist'),
                onTap: () {
                  service.removeTrackFromPlaylist(playlist.id, track.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${track.title}" retiré de la playlist')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.onSurface),
                title: const Text('Partager le fichier'),
                onTap: () {
                  Navigator.pop(ctx);
                  MediaActionsHelper.shareMedia(context, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.secondaryHighlight),
                title: const Text('Modifier les métadonnées'),
                onTap: () {
                  Navigator.pop(ctx);
                  MediaActionsHelper.showEditMetadataDialog(context, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.onSurfaceMuted),
                title: const Text('Détails du fichier'),
                onTap: () {
                  Navigator.pop(ctx);
                  MediaActionsHelper.showFileDetailsDialog(context, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text('Supprimer définitivement du stockage', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  MediaActionsHelper.confirmDeleteMedia(context, track);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaylistMenu(BuildContext context, PlaylistModel playlist, PlaylistService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.onSurface),
                title: const Text('Dupliquer la playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  service.duplicatePlaylist(playlist.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playlist "${playlist.name}" dupliquée')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primaryContainer),
                title: const Text('Renommer la playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, playlist, service);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Supprimer la playlist', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  service.deletePlaylist(playlist.id);
                  Navigator.of(context).pop(); // Exit detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist supprimée')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PlaylistModel playlist, PlaylistService service) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderMd),
        title: const Text('Renommer la playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nouveau nom de la playlist',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Annuler', style: TextStyle(color: AppColors.onSurfaceMuted)),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Enregistrer'),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                service.updatePlaylist(playlist.copyWith(name: newName));
              }
              Navigator.pop(dialogCtx);
            },
          ),
        ],
      ),
    );
  }
}

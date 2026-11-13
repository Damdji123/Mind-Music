import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/media_folder_model.dart';
import '../../../../core/models/media_item_model.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../player/presentation/screens/now_playing_screen.dart';

enum LibraryTab { all, music, videos, folders, favorites }
enum SortOrder { name, artist, date, size }
enum FolderMediaFilter { all, audioOnly, videoOnly }

class LocalLibraryScreen extends StatefulWidget {
  final int initialTabIndex;

  const LocalLibraryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LocalLibraryScreen> createState() => _LocalLibraryScreenState();
}

class _LocalLibraryScreenState extends State<LocalLibraryScreen> {
  late LibraryTab _selectedTab;
  SortOrder _sortOrder = SortOrder.name;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, FolderMediaFilter> _folderFilters = {};

  @override
  void initState() {
    super.initState();
    _selectedTab = switch (widget.initialTabIndex) {
      1 => LibraryTab.music,
      2 => LibraryTab.videos,
      3 => LibraryTab.folders,
      4 => LibraryTab.favorites,
      _ => LibraryTab.all,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MediaItemModel> _getFilteredItems(StorageScannerService scanner) {
    List<MediaItemModel> items;
    switch (_selectedTab) {
      case LibraryTab.music:
        items = List.from(scanner.audioFiles);
        break;
      case LibraryTab.videos:
        items = List.from(scanner.videoFiles);
        break;
      case LibraryTab.favorites:
        items = List.from(scanner.favoriteFiles);
        break;
      case LibraryTab.folders:
      case LibraryTab.all:
        items = List.from(scanner.allMedia);
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((i) {
        return i.title.toLowerCase().contains(q) ||
            i.artist.toLowerCase().contains(q) ||
            i.folderName.toLowerCase().contains(q);
      }).toList();
    }

    switch (_sortOrder) {
      case SortOrder.name:
        items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOrder.artist:
        items.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case SortOrder.date:
        items.sort((a, b) => b.dateModified.compareTo(a.dateModified));
        break;
      case SortOrder.size:
        items.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
        break;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<StorageScannerService>();
    final playback = context.watch<PlaybackEngineService>();
    final filteredItems = _getFilteredItems(scanner);

    return Scaffold(
      body: LiquidGlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.margin,
                  vertical: AppDimensions.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
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
                                  'Library',
                                  style: AppTypography.headlineSmall(color: AppColors.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'SQLite Indexed • ${scanner.allMedia.length} real files',
                                  style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
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
                          icon: Icons.sync,
                          size: 38,
                          iconSize: 20,
                          onPressed: () {
                            scanner.scanDeviceStorage();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Scanning device storage for audio & video...'),
                                backgroundColor: AppColors.surfaceContainerHigh,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<SortOrder>(
                          color: AppColors.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderMd),
                          icon: const Icon(Icons.sort, color: AppColors.onSurface),
                          onSelected: (order) {
                            setState(() {
                              _sortOrder = order;
                            });
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: SortOrder.name, child: Text('Sort by Name')),
                            const PopupMenuItem(value: SortOrder.artist, child: Text('Sort by Artist')),
                            const PopupMenuItem(value: SortOrder.date, child: Text('Sort by Date Added')),
                            const PopupMenuItem(value: SortOrder.size, child: Text('Sort by File Size')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scanning indicator if active
              if (scanner.isScanning)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: scanner.scanProgress > 0 ? scanner.scanProgress : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primaryContainer),
                        minHeight: 3,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

              // 2. Search Field with Voice Trigger
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: GlassTextField(
                  controller: _searchController,
                  hintText: 'Search real files, artists, directories...',
                  leading: const Icon(Icons.search, color: AppColors.primaryContainer, size: 20),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  onVoicePressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎙️ Voice Search: Say a song or folder to filter...')),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 3. Segmented Filter Tabs matching document
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTabChip(
                        label: 'All (${scanner.allMedia.length})',
                        icon: Icons.layers,
                        tab: LibraryTab.all,
                      ),
                      const SizedBox(width: 8),
                      _buildTabChip(
                        label: 'Music (${scanner.audioFiles.length})',
                        icon: Icons.music_note,
                        tab: LibraryTab.music,
                      ),
                      const SizedBox(width: 8),
                      _buildTabChip(
                        label: 'Videos (${scanner.videoFiles.length})',
                        icon: Icons.smart_display,
                        tab: LibraryTab.videos,
                      ),
                      const SizedBox(width: 8),
                      _buildTabChip(
                        label: 'Folders (${scanner.folders.keys.length})',
                        icon: Icons.folder,
                        tab: LibraryTab.folders,
                      ),
                      const SizedBox(width: 8),
                      _buildTabChip(
                        label: 'Favorites (${scanner.favoriteFiles.length})',
                        icon: Icons.favorite,
                        tab: LibraryTab.favorites,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Scrollable List with empty states & folder views
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                  children: [
                    // AI Smart Curation Card from Stitch design
                    _buildAiSmartCurationCard(context, scanner),
                    const SizedBox(height: 16),

                    // Section Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTabHeading(),
                          style: AppTypography.titleMedium(color: AppColors.onSurface),
                        ),
                        Text(
                          _selectedTab == LibraryTab.folders
                              ? '${scanner.folders.keys.length} folders'
                              : '${filteredItems.length} items',
                          style: AppTypography.labelSmall(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Render Content or Clean Empty State
                    if (_selectedTab == LibraryTab.folders)
                      if (scanner.folders.isEmpty)
                        _buildEmptyState(
                          icon: Icons.folder_open,
                          title: 'No Media Folders Found',
                          message:
                              'Mind-Music discovers real folders on your device storage containing audio and video files.',
                          actionLabel: 'Scan Device Storage',
                          onAction: () => scanner.scanDeviceStorage(),
                        )
                      else
                        ..._buildFolderViews(scanner, playback)
                    else if (filteredItems.isEmpty)
                      _buildEmptyState(
                        icon: _getEmptyStateIcon(),
                        title: _getEmptyStateTitle(),
                        message: _getEmptyStateMessage(),
                        actionLabel: 'Scan Device Storage',
                        onAction: () => scanner.scanDeviceStorage(),
                      )
                    else
                      ...filteredItems.map(
                        (item) => _buildMediaListTile(context, item, playback, scanner),
                      ),

                    const SizedBox(height: 96), // Clearance for mini player
                  ],
                ),
              ),

              // 5. Docked Mini Player
              if (playback.currentMedia != null)
                _buildDockedMiniPlayer(context, playback),
            ],
          ),
        ),
      ),
    );
  }

  String _getTabHeading() {
    switch (_selectedTab) {
      case LibraryTab.music:
        return 'Audio Tracks';
      case LibraryTab.videos:
        return 'Video Files';
      case LibraryTab.folders:
        return 'Storage Directories';
      case LibraryTab.favorites:
        return 'Favorite Media';
      case LibraryTab.all:
        return 'All Indexed Media';
    }
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedTab) {
      case LibraryTab.music:
        return Icons.music_off;
      case LibraryTab.videos:
        return Icons.videocam_off;
      case LibraryTab.favorites:
        return Icons.favorite_border;
      case LibraryTab.folders:
        return Icons.folder_open;
      case LibraryTab.all:
        return Icons.library_music;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedTab) {
      case LibraryTab.music:
        return 'No Music Files Found';
      case LibraryTab.videos:
        return 'No Video Files Found';
      case LibraryTab.favorites:
        return 'No Favorites Added';
      case LibraryTab.folders:
        return 'No Storage Folders Found';
      case LibraryTab.all:
        return 'No Media Files Found';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedTab) {
      case LibraryTab.music:
        return 'No real audio files were discovered in your device storage (/Music, /Download). Tap Scan Storage to search.';
      case LibraryTab.videos:
        return 'No video files were discovered in your device storage (/Movies, /DCIM, /Download). Tap Scan Storage to search.';
      case LibraryTab.favorites:
        return 'Tap the heart icon on any music or video file in your library to add it to your favorites.';
      case LibraryTab.folders:
        return 'Directories containing audio and video files will appear here once scanned from device storage.';
      case LibraryTab.all:
        return 'Mind-Music plays real audio and video files directly from your physical storage via SQLite caching.';
    }
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
      child: GlassContainer(
        elevation: GlassElevation.level1,
        padding: const EdgeInsets.all(AppDimensions.spaceXl),
        borderRadius: AppDimensions.borderLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: AppColors.primaryContainer, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleMedium(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall(color: AppColors.onSurfaceSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GlassButton(
              label: actionLabel,
              icon: const Icon(Icons.sync, size: 18),
              variant: GlassButtonVariant.primary,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  // --- Segmented Tab Chip ---
  Widget _buildTabChip({
    required String label,
    required IconData icon,
    required LibraryTab tab,
  }) {
    final isSelected = _selectedTab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppDimensions.borderFull,
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: isSelected ? Colors.white : AppColors.onSurfaceSecondary,
              ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // --- AI Smart Curation Card ---
  Widget _buildAiSmartCurationCard(BuildContext context, StorageScannerService scanner) {
    return GlassContainer(
      elevation: GlassElevation.level2,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      borderRadius: AppDimensions.borderLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryHighlight.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.secondaryHighlight, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Smart Curation',
                style: AppTypography.titleMedium(color: AppColors.onSurface),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: AppDimensions.borderFull,
                ),
                child: Text(
                  'SQLITE',
                  style: AppTypography.labelSmall(color: AppColors.primaryContainer).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${scanner.untaggedCount} untagged files detected on storage.',
            style: AppTypography.labelLarge(color: AppColors.tertiary),
          ),
          const SizedBox(height: 4),
          Text(
            'Let Mind-Music AI analyze file tags, organize folders, and curate lossless mixes.',
            style: AppTypography.bodySmall(color: AppColors.onSurfaceSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Organize Automatically',
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  variant: GlassButtonVariant.aiAccent,
                  height: 38,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✨ Indexed ${scanner.allMedia.length} real files across ${scanner.folders.length} folders!'),
                        backgroundColor: AppColors.secondaryContainer,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderFull),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ Reviewing current SQLite folder taxonomy...'),
                    ),
                  );
                },
                child: const Text('Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Media List Tile with Favorite Toggle ---
  Widget _buildMediaListTile(
    BuildContext context,
    MediaItemModel item,
    PlaybackEngineService playback,
    StorageScannerService scanner,
  ) {
    final isCurrent = playback.currentMedia?.id == item.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        elevation: isCurrent ? GlassElevation.level2 : GlassElevation.level1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: AppDimensions.borderMd,
        onTap: () {
          playback.playMedia(item);
        },
        child: Row(
          children: [
            // Artwork Capsule
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: item.isVideo
                    ? const Color(0xFF2E1065)
                    : const Color(0xFF1E293B),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primaryContainer
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                item.isVideo ? Icons.movie_outlined : Icons.audiotrack,
                color: isCurrent
                    ? AppColors.primaryContainer
                    : (item.isVideo ? AppColors.secondaryHighlight : AppColors.primary),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.titleMedium(
                      color: isCurrent ? AppColors.primaryContainer : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.artist,
                          style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
                      const SizedBox(width: 6),
                      Text(
                        item.format,
                        style: AppTypography.labelSmall(
                          color: item.isHiRes ? AppColors.tertiary : AppColors.onSurfaceMuted,
                        ).copyWith(fontWeight: item.isHiRes ? FontWeight.w700 : FontWeight.w400),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
                      const SizedBox(width: 6),
                      Text(
                        item.formattedSize,
                        style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Favorite toggle button
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite ? Colors.redAccent : AppColors.onSurfaceMuted,
                size: 20,
              ),
              onPressed: () {
                scanner.toggleFavorite(item.id);
              },
            ),

            // Play Trigger
            GlassIconButton(
              icon: (isCurrent && playback.isPlaying) ? Icons.pause : Icons.play_arrow,
              size: 34,
              iconSize: 18,
              isPrimary: isCurrent,
              onPressed: () {
                if (isCurrent) {
                  playback.playPause();
                } else {
                  playback.playMedia(item);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Folder Views for Folders Tab matching document requirements ---
  List<Widget> _buildFolderViews(
    StorageScannerService scanner,
    PlaybackEngineService playback,
  ) {
    return scanner.folders.entries.map((entry) {
      final folderName = entry.key;
      final allFiles = entry.value;
      final audioFiles = allFiles.where((f) => !f.isVideo).toList();
      final videoFiles = allFiles.where((f) => f.isVideo).toList();

      final currentFilter = _folderFilters[folderName] ?? FolderMediaFilter.all;

      final displayedFiles = switch (currentFilter) {
        FolderMediaFilter.audioOnly => audioFiles,
        FolderMediaFilter.videoOnly => videoFiles,
        FolderMediaFilter.all => allFiles,
      };

      // Find matching folder model if available
      final folderModel = scanner.folderModels.firstWhere(
        (m) => m.name == folderName,
        orElse: () => MediaFolderModel(
          path: folderName,
          name: folderName,
          audioCount: audioFiles.length,
          videoCount: videoFiles.length,
          totalSizeBytes: allFiles.fold(0, (sum, f) => sum + f.sizeInBytes),
          lastModified: DateTime.now(),
        ),
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          elevation: GlassElevation.level1,
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          borderRadius: AppDimensions.borderMd,
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiary.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.folder, color: AppColors.tertiary, size: 24),
            ),
            title: Text(folderName, style: AppTypography.titleMedium()),
            subtitle: Text(
              '${folderModel.audioCount} audio • ${folderModel.videoCount} video • ${folderModel.formattedSize}',
              style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
            ),
            children: [
              const SizedBox(height: 8),
              // Document explicit action buttons:
              // "Joue uniquement les musiques de ce dossier"
              // "Montre-moi toutes les vidéos de ce dossier"
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (audioFiles.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.25),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.primaryContainer, width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderFull),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Joue les musiques'),
                        onPressed: () {
                          playback.setQueue(audioFiles, startIndex: 0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Playing ${audioFiles.length} audio tracks in "$folderName"'),
                              backgroundColor: AppColors.primaryContainer,
                            ),
                          );
                        },
                      ),
                    const SizedBox(width: 8),
                    if (videoFiles.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondaryHighlight,
                          side: BorderSide(
                            color: currentFilter == FolderMediaFilter.videoOnly
                                ? AppColors.secondaryHighlight
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderFull),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.movie, size: 16),
                        label: Text('Vidéos (${videoFiles.length})'),
                        onPressed: () {
                          setState(() {
                            _folderFilters[folderName] =
                                currentFilter == FolderMediaFilter.videoOnly
                                    ? FolderMediaFilter.all
                                    : FolderMediaFilter.videoOnly;
                          });
                        },
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: BorderSide(
                          color: currentFilter == FolderMediaFilter.audioOnly
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderFull),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.audiotrack, size: 16),
                      label: Text('Musiques (${audioFiles.length})'),
                      onPressed: () {
                        setState(() {
                          _folderFilters[folderName] =
                              currentFilter == FolderMediaFilter.audioOnly
                                  ? FolderMediaFilter.all
                                  : FolderMediaFilter.audioOnly;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ...displayedFiles.map(
                (file) => _buildMediaListTile(context, file, playback, scanner),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // --- Docked Mini Player ---
  Widget _buildDockedMiniPlayer(BuildContext context, PlaybackEngineService playback) {
    final media = playback.currentMedia;
    final isVideo = playback.mode == PlaybackMode.video;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppDimensions.margin,
          0,
          AppDimensions.margin,
          8,
        ),
        child: GlassContainer(
          elevation: GlassElevation.level3,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          borderRadius: AppDimensions.borderFull,
          glowColor: isVideo ? AppColors.secondaryHighlight : AppColors.primaryContainer,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isVideo ? AppColors.secondaryContainer : const Color(0xFF1E293B),
                ),
                child: Icon(
                  isVideo ? Icons.videocam : Icons.audiotrack,
                  color: isVideo ? AppColors.secondaryHighlight : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media?.title ?? '',
                      style: AppTypography.titleMedium(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${media?.artist ?? ''} • Tap for Now Playing',
                      style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 22),
                color: AppColors.onSurface,
                onPressed: playback.skipPrevious,
              ),
              GlassIconButton(
                icon: playback.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 38,
                iconSize: 20,
                isPrimary: true,
                onPressed: playback.playPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 22),
                color: AppColors.onSurface,
                onPressed: playback.skipNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

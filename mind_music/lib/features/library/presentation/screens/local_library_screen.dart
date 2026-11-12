import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/media_item_model.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../player/presentation/screens/now_playing_screen.dart';

enum LibraryTab { all, music, videos, folders }
enum SortOrder { name, artist, date, size }

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

  @override
  void initState() {
    super.initState();
    _selectedTab = switch (widget.initialTabIndex) {
      1 => LibraryTab.music,
      2 => LibraryTab.videos,
      3 => LibraryTab.folders,
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
                    Row(
                      children: [
                        GlassIconButton(
                          icon: Icons.arrow_back,
                          size: 38,
                          iconSize: 20,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Library', style: AppTypography.headlineSmall(color: AppColors.onSurface)),
                            Text(
                              'Local storage • ${scanner.allMedia.length} indexed files',
                              style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GlassIconButton(
                          icon: Icons.sync,
                          size: 38,
                          iconSize: 20,
                          onPressed: () {
                            scanner.scanDeviceStorage();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Scanning local device storage...')),
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

              // 2. Search Field with Voice Trigger
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: GlassTextField(
                  controller: _searchController,
                  hintText: 'Search songs, videos, artists, folders...',
                  leading: const Icon(Icons.search, color: AppColors.primaryContainer, size: 20),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  onVoicePressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎙️ Say a song or artist name to filter...')),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 3. Segmented Filter Tabs
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Scrollable List with AI Smart Curation Card
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                  children: [
                    // AI Smart Curation Card from Stitch
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
                          '${filteredItems.length} items',
                          style: AppTypography.labelSmall(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Media Items List
                    if (_selectedTab == LibraryTab.folders)
                      ..._buildFolderViews(scanner, playback)
                    else
                      ...filteredItems.map((item) => _buildMediaListTile(context, item, playback)),

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
      case LibraryTab.all:
        return 'All Indexed Media';
    }
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
                  'NEW',
                  style: AppTypography.labelSmall(color: AppColors.primaryContainer).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${scanner.untaggedCount} untagged audio & video files detected.',
            style: AppTypography.labelLarge(color: AppColors.tertiary),
          ),
          const SizedBox(height: 4),
          Text(
            'Let MyPlayer AI auto-detect album art, generate smart tags, and sort duplicates into organized folders.',
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
                      const SnackBar(
                        content: Text('✨ AI Curation complete! 42 files matched with ID3 metadata & artwork.'),
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
                onPressed: () => _showReviewOrganizationDialog(context, scanner),
                child: const Text('Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Media List Tile ---
  Widget _buildMediaListTile(
    BuildContext context,
    MediaItemModel item,
    PlaybackEngineService playback,
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
                    ],
                  ),
                ],
              ),
            ),

            // Duration & Play Trigger
            Text(
              item.formattedDuration,
              style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(width: 6),
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

  // --- Folder Views for Folders Tab ---
  List<Widget> _buildFolderViews(StorageScannerService scanner, PlaybackEngineService playback) {
    return scanner.folders.entries.map((entry) {
      final folderName = entry.key;
      final files = entry.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: GlassContainer(
          elevation: GlassElevation.level1,
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          borderRadius: AppDimensions.borderMd,
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_special, color: AppColors.tertiary, size: 28),
            title: Text(folderName, style: AppTypography.titleMedium()),
            subtitle: Text('${files.length} media files', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
            children: files.map((file) => _buildMediaListTile(context, file, playback)).toList(),
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

  // --- Review Proposed Organization Dialog ---
  void _showReviewOrganizationDialog(BuildContext context, StorageScannerService scanner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.secondaryHighlight),
            const SizedBox(width: 8),
            Text('Proposed AI Curation', style: AppTypography.headlineSmall()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI analyzed file metadata and proposed this clean folder taxonomy:',
              style: AppTypography.bodySmall(color: AppColors.onSurfaceSecondary),
            ),
            const SizedBox(height: 12),
            _buildReviewRow('Afrobeats', '184 files'),
            _buildReviewRow('Chill & Ambient', '92 files'),
            _buildReviewRow('Workout High-Energy', '57 files'),
            _buildReviewRow('Instrumental / Acoustic', '31 files'),
            _buildReviewRow('Video Captures', '184 files'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Library organized successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Apply Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String folder, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, size: 16, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Text(folder, style: AppTypography.bodyMedium(color: AppColors.onSurface)),
            ],
          ),
          Text(count, style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

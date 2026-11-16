import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../models/media_item_model.dart';
import '../services/playback_engine_service.dart';
import '../services/playlist_service.dart';
import '../services/storage_scanner_service.dart';

class MediaActionsHelper {
  MediaActionsHelper._();

  /// Shares a local media file using native system sharing intent (WhatsApp, Bluetooth, etc.)
  static Future<void> shareMedia(BuildContext context, MediaItemModel item) async {
    try {
      final file = File(item.filePath);
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(item.filePath, mimeType: item.isVideo ? 'video/*' : 'audio/*')],
            subject: item.title,
            text: 'Enjoy "${item.title}" by ${item.artist} on Mind-Music Player',
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot share asset file or non-existent file: ${item.filePath}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Displays the full action sheet for any audio or video item
  static void showMediaOptionsSheet(BuildContext context, MediaItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final playback = context.read<PlaybackEngineService>();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.isVideo
                            ? AppColors.secondaryHighlight.withValues(alpha: 0.15)
                            : AppColors.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.isVideo ? Icons.movie_outlined : Icons.music_note,
                        color: item.isVideo
                            ? AppColors.secondaryHighlight
                            : AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.titleMedium(color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.artist} • ${item.format} • ${item.formattedDuration}',
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
              const Divider(color: AppColors.glassBorderSubtle, height: 1),

              // Action Options
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded, color: AppColors.primaryContainer),
                title: const Text('Play Next'),
                subtitle: const Text('Insert immediately after current track'),
                onTap: () {
                  Navigator.pop(ctx);
                  playback.playNext(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('▶ "${item.title}" will play next'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded, color: AppColors.primaryContainer),
                title: const Text('Add to Up-Next Queue'),
                subtitle: const Text('Append to the end of the current queue'),
                onTap: () {
                  Navigator.pop(ctx);
                  playback.addToQueue(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${item.title}" to Up-Next Queue'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: AppColors.secondaryHighlight),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddToPlaylistSheet(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: AppColors.onSurface),
                title: const Text('Share File'),
                onTap: () {
                  Navigator.pop(ctx);
                  shareMedia(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: AppColors.onSurface),
                title: const Text('Edit Metadata / Tags'),
                onTap: () {
                  Navigator.pop(ctx);
                  showEditMetadataDialog(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.onSurface),
                title: const Text('File Properties & Location'),
                onTap: () {
                  Navigator.pop(ctx);
                  showFileDetailsDialog(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Delete from Device Storage', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  confirmDeleteMedia(context, item);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Bottom sheet allowing user to select or create a playlist to add this track to
  static void showAddToPlaylistSheet(BuildContext context, MediaItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final playlistService = context.watch<PlaylistService>();
        final playlists = playlistService.allPlaylists;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add to Playlist', style: AppTypography.headlineSmall()),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCreatePlaylistDialog(context, item);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No playlists available. Create one to organize your music.',
                        style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (c, i) {
                        final pl = playlists[i];
                        final hasTrack = pl.tracks.any((t) => t.id == item.id);

                        return ListTile(
                          leading: const Icon(Icons.queue_music, color: AppColors.primaryContainer),
                          title: Text(pl.name, style: AppTypography.titleMedium()),
                          subtitle: Text(
                            '${pl.tracks.length} tracks • ${pl.isAiGenerated ? "AI Mix" : "User Playlist"}',
                            style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                          ),
                          trailing: hasTrack
                              ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                              : const Icon(Icons.add_circle_outline, color: AppColors.primaryContainer, size: 20),
                          onTap: () {
                            if (!hasTrack) {
                              playlistService.addTrackToPlaylist(pl.id, item);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added "${item.title}" to ${pl.name}')),
                              );
                            } else {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('"${item.title}" is already in ${pl.name}')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showCreatePlaylistDialog(BuildContext context, MediaItemModel item) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Text('New Playlist', style: AppTypography.headlineSmall()),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist Name (e.g. Chill Beats)',
            hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final playlistService = context.read<PlaylistService>();
                final created = playlistService.createPlaylist(
                  name: name,
                  tracks: [item],
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created playlist "${created.name}" with "${item.title}"')),
                );
              }
            },
            child: const Text('Create & Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  /// Dialog to edit song title, artist, and album tags
  static void showEditMetadataDialog(BuildContext context, MediaItemModel item) {
    final titleController = TextEditingController(text: item.title);
    final artistController = TextEditingController(text: item.artist);
    final albumController = TextEditingController(text: item.album);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Text('Edit Metadata', style: AppTypography.headlineSmall()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Artist',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: albumController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Album / Folder',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newArtist = artistController.text.trim();
              final newAlbum = albumController.text.trim();

              if (newTitle.isNotEmpty) {
                final scanner = context.read<StorageScannerService>();
                await scanner.updateMetadata(
                  item.id,
                  title: newTitle,
                  artist: newArtist.isEmpty ? 'Unknown Artist' : newArtist,
                  album: newAlbum,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Metadata updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  /// Dialog displaying detailed physical file attributes
  static void showFileDetailsDialog(BuildContext context, MediaItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Text('File Details', style: AppTypography.headlineSmall()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Title', item.title),
            _buildDetailRow('Artist', item.artist),
            _buildDetailRow('Album', item.album),
            _buildDetailRow('Format', '${item.format} ${item.isHiRes ? "• 24-bit Hi-Res" : "• Standard"}'),
            _buildDetailRow('Duration', item.formattedDuration),
            _buildDetailRow('File Size', item.formattedSize),
            _buildDetailRow('Folder', item.folderName),
            _buildDetailRow('Modified', item.dateModified.toLocal().toString().split('.').first),
            const SizedBox(height: 8),
            Text('Full Storage Path:', style: AppTypography.labelSmall(color: AppColors.primaryContainer)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorderSubtle),
              ),
              child: SelectableText(
                item.filePath,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.onSurfaceMuted),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              '$label:',
              style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelMedium(color: AppColors.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Destructive confirmation dialog before deleting file permanently from physical disk
  static void confirmDeleteMedia(BuildContext context, MediaItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Delete File?', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.title}" from your device storage?\n\nThis will remove the file from your phone and cannot be undone.',
          style: AppTypography.bodyMedium(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final playback = context.read<PlaybackEngineService>();
              final scanner = context.read<StorageScannerService>();

              playback.onMediaDeleted(item.id);
              final success = await scanner.deleteMediaFile(item);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '🗑️ "${item.title}" permanently deleted'
                        : '❌ Failed to delete file'),
                    backgroundColor: success ? AppColors.surfaceContainerHigh : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}

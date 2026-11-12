import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/media_item_model.dart';
import '../models/playlist_model.dart';

class PlaylistService extends ChangeNotifier {
  final List<PlaylistModel> _playlists = [];
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'user', 'ai', 'favorites'

  PlaylistService() {
    _initDefaultPlaylists();
  }

  List<PlaylistModel> get allPlaylists => List.unmodifiable(_playlists);

  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  List<PlaylistModel> get filteredPlaylists {
    return _playlists.where((pl) {
      // 1. Filter Tab
      if (_selectedFilter == 'user' && pl.isAiGenerated) return false;
      if (_selectedFilter == 'ai' && !pl.isAiGenerated) return false;
      if (_selectedFilter == 'favorites' && !pl.isFavorite) return false;

      // 2. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = pl.name.toLowerCase().contains(query);
        final matchDesc = pl.description.toLowerCase().contains(query);
        final matchTag = pl.tags.any((t) => t.toLowerCase().contains(query));
        return matchTitle || matchDesc || matchTag;
      }
      return true;
    }).toList();
  }

  PlaylistModel? get featuredAiMix {
    try {
      return _playlists.firstWhere((p) => p.isAiGenerated);
    } catch (_) {
      return _playlists.isNotEmpty ? _playlists.first : null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void toggleFavorite(String playlistId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final current = _playlists[index];
      _playlists[index] = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
    }
  }

  PlaylistModel createPlaylist({
    required String name,
    String description = '',
    List<MediaItemModel> tracks = const [],
    bool isAiMix = false,
    String? bpmRange,
    List<String> tags = const [],
    int gradientIndex = 0,
  }) {
    final newPlaylist = PlaylistModel(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      name: name.trim().isEmpty ? 'Untitled Playlist' : name.trim(),
      description: description.trim(),
      tracks: List.from(tracks),
      isAiGenerated: isAiMix,
      bpmRange: bpmRange,
      tags: tags,
      createdAt: DateTime.now(),
      coverGradientIndex: gradientIndex,
    );
    _playlists.insert(0, newPlaylist);
    notifyListeners();
    return newPlaylist;
  }

  void updatePlaylist(PlaylistModel updated) {
    final index = _playlists.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _playlists[index] = updated;
      notifyListeners();
    }
  }

  void deletePlaylist(String playlistId) {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
  }

  PlaylistModel duplicatePlaylist(String playlistId) {
    final original = _playlists.firstWhere((p) => p.id == playlistId);
    final copy = original.copyWith(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
    );
    _playlists.insert(0, copy);
    notifyListeners();
    return copy;
  }

  void addTrackToPlaylist(String playlistId, MediaItemModel track) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final pl = _playlists[index];
      if (!pl.tracks.any((t) => t.id == track.id)) {
        final newTracks = List<MediaItemModel>.from(pl.tracks)..add(track);
        _playlists[index] = pl.copyWith(tracks: newTracks);
        notifyListeners();
      }
    }
  }

  void removeTrackFromPlaylist(String playlistId, String mediaId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final pl = _playlists[index];
      final newTracks = pl.tracks.where((t) => t.id != mediaId).toList();
      _playlists[index] = pl.copyWith(tracks: newTracks);
      notifyListeners();
    }
  }

  void reorderTrack(String playlistId, int oldIndex, int newIndex) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final pl = _playlists[index];
      final updatedList = List<MediaItemModel>.from(pl.tracks);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = updatedList.removeAt(oldIndex);
      updatedList.insert(newIndex, item);
      _playlists[index] = pl.copyWith(tracks: updatedList);
      notifyListeners();
    }
  }

  // --- AI Smart Mix Generation Engine ---
  PlaylistModel generateAiMix({
    required String mood,
    required List<MediaItemModel> availablePool,
    int targetCount = 15,
    String? targetBpm,
    bool preferHiRes = false,
  }) {
    List<MediaItemModel> filtered = List.from(availablePool);
    if (preferHiRes) {
      final hiresOnly = filtered.where((t) => t.isHiRes).toList();
      if (hiresOnly.isNotEmpty) {
        filtered = hiresOnly;
      }
    }

    filtered.shuffle();
    final selected = filtered.take(targetCount).toList();

    final title = '$mood AI Mix';
    final desc = 'Auto-generated $mood session from local library';
    final tags = [mood, if (preferHiRes) 'Hi-Res 24-bit', ?targetBpm];

    return createPlaylist(
      name: title,
      description: desc,
      tracks: selected,
      isAiMix: true,
      bpmRange: targetBpm ?? 'BPM 90-120',
      tags: tags,
      gradientIndex: Random().nextInt(4),
    );
  }

  void _initDefaultPlaylists() {
    final sampleTracks1 = [
      MediaItemModel(
        id: 'track_cyber_1',
        title: 'Neon Driftways',
        artist: 'Kavinsky & Lorn',
        album: 'Cyber Odyssey',
        duration: const Duration(minutes: 4, seconds: 12),
        filePath: 'C:/Music/cyber_1.flac',
        format: 'FLAC',
        isHiRes: true,
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
      MediaItemModel(
        id: 'track_cyber_2',
        title: 'Tokyo Midnight Rain',
        artist: 'Tycho',
        album: 'Simulated Horizons',
        duration: const Duration(minutes: 5, seconds: 30),
        filePath: 'C:/Music/cyber_2.flac',
        format: 'FLAC',
        isHiRes: true,
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
      MediaItemModel(
        id: 'track_cyber_3',
        title: 'Subsurface Echoes',
        artist: 'Carbon Based Lifeforms',
        album: 'Hydrophonic Garden',
        duration: const Duration(minutes: 6, seconds: 4),
        filePath: 'C:/Music/cyber_3.mp3',
        format: 'MP3',
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
    ];

    final sampleTracks2 = [
      MediaItemModel(
        id: 'track_lofi_1',
        title: 'Late Night Coffee',
        artist: 'ChilledCow',
        album: 'Midnight Study',
        duration: const Duration(minutes: 2, seconds: 45),
        filePath: 'C:/Music/coffee.mp3',
        format: 'MP3',
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
      MediaItemModel(
        id: 'track_lofi_2',
        title: 'Autumn Rain On Window',
        artist: 'Idealism',
        album: 'Rainy Days',
        duration: const Duration(minutes: 3, seconds: 10),
        filePath: 'C:/Music/rain.wav',
        format: 'WAV',
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
    ];

    _playlists.addAll([
      PlaylistModel(
        id: 'pl_focus_ambient',
        name: 'Focus Ambient Cyberpunk',
        description: '24 titres • BPM 90-115 • Ambient, Synthwave',
        tracks: sampleTracks1,
        isAiGenerated: true,
        isFavorite: true,
        bpmRange: 'BPM 90-115',
        tags: const ['Ambient', 'Synthwave', 'Focus', 'AI Mix'],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        coverGradientIndex: 0,
      ),
      PlaylistModel(
        id: 'pl_nocturne_lofi',
        name: 'Nocturne Lo-Fi Beats',
        description: 'Sons feutrés & crépuscule d\'automne',
        tracks: sampleTracks2,
        isAiGenerated: false,
        isFavorite: true,
        bpmRange: 'BPM 70-85',
        tags: const ['Lo-Fi', 'Study', 'Chill'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        coverGradientIndex: 1,
      ),
      PlaylistModel(
        id: 'pl_afrobeats_energy',
        name: 'Afrobeats High Energy',
        description: 'Rythmes percutants pour entraînement & run',
        tracks: sampleTracks1,
        isAiGenerated: false,
        isFavorite: false,
        bpmRange: 'BPM 115-130',
        tags: const ['Workout', 'Afrobeats', 'High BPM'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        coverGradientIndex: 2,
      ),
      PlaylistModel(
        id: 'pl_hires_acoustic',
        name: 'High-Res Acoustic Sessions',
        description: 'Master Studio 24-bit / 96kHz pure direct',
        tracks: sampleTracks1,
        isAiGenerated: true,
        isFavorite: false,
        bpmRange: 'BPM 80-100',
        tags: const ['FLAC 24-bit', 'Studio Master', 'Acoustic'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        coverGradientIndex: 3,
      ),
    ]);
  }
}

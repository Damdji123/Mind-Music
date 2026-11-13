import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_music/core/database/database_service.dart';
import 'package:mind_music/core/models/media_folder_model.dart';
import 'package:mind_music/core/models/media_item_model.dart';
import 'package:mind_music/core/models/playlist_model.dart';
import 'package:mind_music/core/services/ads_service.dart';
import 'package:mind_music/core/services/playback_engine_service.dart';
import 'package:mind_music/core/services/storage_scanner_service.dart';
import 'package:mind_music/core/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall methodCall) async {
        return <String, dynamic>{};
      },
    );
    SharedPreferences.setMockInitialValues({});
    dbService = DatabaseService();
    await dbService.clearAll();
  });

  group('SQLite DatabaseService Comprehensive Tests', () {
    test('Upserts and retrieves media items by type and favorites', () async {
      final audioItem = MediaItemModel(
        id: 'track-101',
        title: 'Lossless Echoes',
        artist: 'Master Audio',
        album: 'Acoustic Studio',
        filePath: '/storage/emulated/0/Music/echoes.flac',
        format: 'FLAC',
        isHiRes: true,
        sizeInBytes: 45 * 1024 * 1024,
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      final videoItem = MediaItemModel(
        id: 'video-202',
        title: 'Concert Live 4K',
        artist: 'Master Audio',
        album: 'Concerts',
        filePath: '/storage/emulated/0/Movies/concert.mp4',
        format: 'MP4',
        isVideo: true,
        sizeInBytes: 350 * 1024 * 1024,
        dateModified: DateTime.now(),
        folderName: 'Movies',
      );

      await dbService.upsertMediaItems([audioItem, videoItem]);

      final allMedia = await dbService.getAllMedia();
      expect(allMedia.length, 2);

      final audios = await dbService.getAudioItems();
      expect(audios.length, 1);
      expect(audios.first.title, 'Lossless Echoes');
      expect(audios.first.isHiRes, isTrue);

      final videos = await dbService.getVideoItems();
      expect(videos.length, 1);
      expect(videos.first.title, 'Concert Live 4K');
      expect(videos.first.isVideo, isTrue);

      // Toggle favorite
      await dbService.toggleFavorite('track-101');
      final favorites = await dbService.getFavoriteItems();
      expect(favorites.length, 1);
      expect(favorites.first.id, 'track-101');
      expect(favorites.first.isFavorite, isTrue);

      // Record play
      await dbService.recordMediaPlay('track-101');
      final recent = await dbService.getRecentlyPlayed();
      expect(recent.length, 1);
      expect(recent.first.playCount, 1);
      expect(recent.first.lastPlayed, isNotNull);
    });

    test('Upserts and retrieves physical folders with audio and video counters', () async {
      final folder1 = MediaFolderModel(
        path: '/storage/emulated/0/Music',
        name: 'Music',
        audioCount: 14,
        videoCount: 0,
        totalSizeBytes: 320 * 1024 * 1024,
        lastModified: DateTime.now(),
      );

      final folder2 = MediaFolderModel(
        path: '/storage/emulated/0/Download',
        name: 'Download',
        audioCount: 5,
        videoCount: 8,
        totalSizeBytes: 850 * 1024 * 1024,
        lastModified: DateTime.now(),
      );

      await dbService.upsertFolders([folder1, folder2]);

      final folders = await dbService.getAllFolders();
      expect(folders.length, 2);
      expect(folders.any((f) => f.name == 'Music' && f.audioCount == 14), isTrue);
      expect(folders.any((f) => f.name == 'Download' && f.videoCount == 8), isTrue);
    });

    test('Manages playlists and track junction persistence', () async {
      final track = MediaItemModel(
        id: 'track-pl-1',
        title: 'Deep Focus Ambient',
        artist: 'Neural AI',
        album: 'Focus Sessions',
        filePath: '/storage/emulated/0/Music/focus.flac',
        format: 'FLAC',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      await dbService.upsertMediaItems([track]);

      final playlist = PlaylistModel(
        id: 'pl-focus-1',
        name: 'Deep Focus',
        description: 'BPM 90 Lossless Focus',
        tracks: [track],
        isAiGenerated: true,
        tags: const ['Focus', 'FLAC'],
        createdAt: DateTime.now(),
      );

      await dbService.upsertPlaylist(playlist);

      final playlists = await dbService.getAllPlaylists();
      expect(playlists.length, 1);
      expect(playlists.first.name, 'Deep Focus');
      expect(playlists.first.isAiGenerated, isTrue);
      expect(playlists.first.tracks.length, 1);
      expect(playlists.first.tracks.first.id, 'track-pl-1');

      // Delete playlist
      await dbService.deletePlaylist('pl-focus-1');
      final updatedPlaylists = await dbService.getAllPlaylists();
      expect(updatedPlaylists.isEmpty, isTrue);
    });

    test('Library statistics aggregation returns accurate counts', () async {
      final statsBefore = await dbService.getLibraryStats();
      expect(statsBefore['musicCount'], 0);
      expect(statsBefore['videoCount'], 0);

      await dbService.upsertMediaItems([
        MediaItemModel(
          id: 's-1',
          title: 'Song 1',
          filePath: '/storage/s1.mp3',
          format: 'MP3',
          dateModified: DateTime.now(),
          folderName: 'Audio',
        ),
        MediaItemModel(
          id: 's-2',
          title: 'Video 1',
          filePath: '/storage/v1.mp4',
          format: 'MP4',
          isVideo: true,
          dateModified: DateTime.now(),
          folderName: 'Video',
        ),
      ]);

      await dbService.upsertFolders([
        MediaFolderModel(
          path: '/storage/Audio',
          name: 'Audio',
          lastModified: DateTime.now(),
        ),
      ]);

      final statsAfter = await dbService.getLibraryStats();
      expect(statsAfter['musicCount'], 1);
      expect(statsAfter['videoCount'], 1);
      expect(statsAfter['foldersCount'], 1);
    });
  });

  group('StorageScannerService & Real Storage Integration Tests', () {
    test('StorageScannerService starts with real empty library and no mock data', () async {
      final scanner = StorageScannerService(dbService: dbService);
      await scanner.init();

      // Zero fake mock tracks must exist
      expect(scanner.allMedia.isEmpty, isTrue);
      expect(scanner.audioFiles.isEmpty, isTrue);
      expect(scanner.videoFiles.isEmpty, isTrue);
      expect(scanner.folders.isEmpty, isTrue);
      expect(scanner.isScanning, isFalse);
    });

    test('StorageScannerService favorite toggling updates SQLite store', () async {
      final item = MediaItemModel(
        id: 'real-song-1',
        title: 'Original Track',
        artist: 'Indie Artist',
        filePath: '/storage/emulated/0/Music/track.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      await dbService.upsertMediaItems([item]);

      final scanner = StorageScannerService(dbService: dbService);
      await scanner.init();
      expect(scanner.allMedia.length, 1);
      expect(scanner.allMedia.first.isFavorite, isFalse);

      await scanner.toggleFavorite('real-song-1');
      expect(scanner.favoriteFiles.length, 1);
      expect(scanner.favoriteFiles.first.id, 'real-song-1');

      final dbFavorites = await dbService.getFavoriteItems();
      expect(dbFavorites.length, 1);
      expect(dbFavorites.first.id, 'real-song-1');
    });

    test('PlaybackEngineService records playback in SQLite and validates real paths', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final realItem = MediaItemModel(
        id: 'real-play-1',
        title: 'Acoustic Sunrise',
        artist: 'Real Artist',
        filePath: 'assets/audio/test.mp3', // Allowed asset path
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      await dbService.upsertMediaItems([realItem]);

      await playback.playMedia(realItem);

      expect(playback.currentMedia?.id, 'real-play-1');
      expect(playback.isPlaying, isTrue);

      final recents = await dbService.getRecentlyPlayed();
      expect(recents.isNotEmpty, isTrue);
      expect(recents.first.id, 'real-play-1');
      expect(recents.first.playCount, 1);
    });
  });
}

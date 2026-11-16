import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_music/core/database/database_service.dart';
import 'package:mind_music/core/models/media_item_model.dart';
import 'package:mind_music/core/models/playlist_model.dart';
import 'package:mind_music/core/services/ads_service.dart';
import 'package:mind_music/core/services/playback_engine_service.dart';
import 'package:mind_music/core/services/playlist_service.dart';
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (MethodCall methodCall) async {
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (MethodCall methodCall) async {
        return true;
      },
    );
    SharedPreferences.setMockInitialValues({});
    dbService = DatabaseService();
    await dbService.clearAll();
  });

  group('Option 1: Queue Reordering & Management Tests', () {
    test('reorderQueue correctly moves items in Up-Next queue', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final trackA = MediaItemModel(
        id: 't-1',
        title: 'Track A',
        artist: 'Artist 1',
        filePath: 'assets/audio/a.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final trackB = MediaItemModel(
        id: 't-2',
        title: 'Track B',
        artist: 'Artist 2',
        filePath: 'assets/audio/b.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final trackC = MediaItemModel(
        id: 't-3',
        title: 'Track C',
        artist: 'Artist 3',
        filePath: 'assets/audio/c.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      playback.setQueue([trackA, trackB, trackC], startIndex: 0);

      expect(playback.queue.length, 3);
      expect(playback.queue[0].id, 't-1');
      expect(playback.queue[1].id, 't-2');
      expect(playback.queue[2].id, 't-3');
      expect(playback.currentIndex, 0);

      // Reorder trackA (index 0) to after trackC (newIndex 3 in Flutter reorder semantics)
      playback.reorderQueue(0, 3);

      expect(playback.queue[0].id, 't-2');
      expect(playback.queue[1].id, 't-3');
      expect(playback.queue[2].id, 't-1');
      // Current index should track trackA's new position
      expect(playback.currentIndex, 2);
    });

    test('playNext inserts item immediately after current track', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final track1 = MediaItemModel(
        id: 't-1',
        title: 'Track 1',
        filePath: 'assets/audio/1.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final track2 = MediaItemModel(
        id: 't-2',
        title: 'Track 2',
        filePath: 'assets/audio/2.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final trackPriority = MediaItemModel(
        id: 't-priority',
        title: 'Play Next Track',
        filePath: 'assets/audio/priority.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      playback.setQueue([track1, track2], startIndex: 0);
      playback.playNext(trackPriority);

      expect(playback.queue.length, 3);
      expect(playback.queue[0].id, 't-1');
      expect(playback.queue[1].id, 't-priority');
      expect(playback.queue[2].id, 't-2');
    });

    test('addToQueue, removeFromQueue, and clearQueue work as expected', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final track1 = MediaItemModel(
        id: 't-1',
        title: 'Track 1',
        filePath: 'assets/audio/1.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final track2 = MediaItemModel(
        id: 't-2',
        title: 'Track 2',
        filePath: 'assets/audio/2.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      playback.addToQueue(track1);
      playback.addToQueue(track2);
      expect(playback.queue.length, 2);

      playback.removeFromQueue(0);
      expect(playback.queue.length, 1);
      expect(playback.queue.first.id, 't-2');

      playback.clearQueue();
      expect(playback.queue.isEmpty, isTrue);
    });

    test('onMediaDeleted removes track from queue', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final track1 = MediaItemModel(
        id: 'del-1',
        title: 'Track To Delete',
        filePath: 'assets/audio/del.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final track2 = MediaItemModel(
        id: 'keep-2',
        title: 'Track To Keep',
        filePath: 'assets/audio/keep.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      playback.setQueue([track1, track2], startIndex: 1);
      playback.onMediaDeleted('del-1');

      expect(playback.queue.length, 1);
      expect(playback.queue.first.id, 'keep-2');
    });
  });

  group('Option 1: Audio Session & Focus Handling Tests', () {
    test('BecomingNoisy pauses playback when active', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final track = MediaItemModel(
        id: 'noisy-1',
        title: 'Noisy Track',
        filePath: 'assets/audio/test.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      await playback.playMedia(track);
      expect(playback.isPlaying, isTrue);

      // Simulate becoming noisy event (e.g. headphone unplugged)
      playback.handleBecomingNoisy();
      expect(playback.isPlaying, isFalse);
    });

    test('Transient interruption ducks volume to 0.2 and restores to 1.0', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final track = MediaItemModel(
        id: 'duck-1',
        title: 'Duck Track',
        filePath: 'assets/audio/test.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      await playback.playMedia(track);
      expect(playback.isPlaying, isTrue);

      // Simulate transient interruption begin (ducking)
      playback.handleInterruption(
        AudioInterruptionEvent(
          true,
          AudioInterruptionType.duck,
        ),
      );
      expect(playback.volume, 0.2);

      // Simulate transient interruption end
      playback.handleInterruption(
        AudioInterruptionEvent(
          false,
          AudioInterruptionType.duck,
        ),
      );
      expect(playback.volume, 1.0);
    });

    test('Call interruption pauses and auto-resumes when call ends', () async {
      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads, dbService: dbService);

      final track = MediaItemModel(
        id: 'call-1',
        title: 'Call Track',
        filePath: 'assets/audio/test.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      await playback.playMedia(track);
      expect(playback.isPlaying, isTrue);

      // Incoming call begins (pause)
      playback.handleInterruption(
        AudioInterruptionEvent(
          true,
          AudioInterruptionType.pause,
        ),
      );
      expect(playback.isPlaying, isFalse);

      // Call ends (resume)
      playback.handleInterruption(
        AudioInterruptionEvent(
          false,
          AudioInterruptionType.pause,
        ),
      );
      expect(playback.isPlaying, isTrue);
    });
  });

  group('Option 1: Physical File & Metadata Operations Tests', () {
    test('updateMediaMetadata updates SQLite and StorageScannerService collections', () async {
      final item = MediaItemModel(
        id: 'meta-1',
        title: 'Old Title',
        artist: 'Old Artist',
        album: 'Old Album',
        filePath: '/storage/music/meta.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'music',
      );

      await dbService.upsertMediaItems([item]);

      final scanner = StorageScannerService(dbService: dbService);
      await scanner.init();

      expect(scanner.audioFiles.first.title, 'Old Title');

      await scanner.updateMetadata(
        'meta-1',
        title: 'Remastered Echoes',
        artist: 'Mind-Music Pro',
        album: 'Studio High-End',
      );

      // Verify in scanner in-memory list
      expect(scanner.audioFiles.first.title, 'Remastered Echoes');
      expect(scanner.audioFiles.first.artist, 'Mind-Music Pro');
      expect(scanner.audioFiles.first.album, 'Studio High-End');

      // Verify in SQLite database
      final dbItem = await dbService.getMediaItemById('meta-1');
      expect(dbItem, isNotNull);
      expect(dbItem!.title, 'Remastered Echoes');
      expect(dbItem.artist, 'Mind-Music Pro');
      expect(dbItem.album, 'Studio High-End');
    });

    test('deleteMediaFile deletes from SQLite, cascades playlists, and updates scanner', () async {
      // Create a temporary file on disk
      final tempDir = await Directory.systemTemp.createTemp('mind_music_test');
      final tempFile = File('${tempDir.path}/test_delete.mp3');
      await tempFile.writeAsString('mock audio bytes');
      expect(await tempFile.exists(), isTrue);

      final item = MediaItemModel(
        id: 'del-real-1',
        title: 'File to delete',
        artist: 'Artist',
        filePath: tempFile.path,
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'temp',
      );

      await dbService.upsertMediaItems([item]);

      // Add to playlist
      final playlist = PlaylistModel(
        id: 'pl-del-test',
        name: 'Test Playlist',
        tracks: [item],
        createdAt: DateTime.now(),
      );
      await dbService.upsertPlaylist(playlist);

      final scanner = StorageScannerService(dbService: dbService);
      await scanner.init();
      expect(scanner.allMedia.any((m) => m.id == 'del-real-1'), isTrue);

      // Delete file via scanner
      final success = await scanner.deleteMediaFile(item);
      expect(success, isTrue);

      // Physical file must be deleted
      expect(await tempFile.exists(), isFalse);

      // In-memory scanner collection must no longer contain the file
      expect(scanner.allMedia.any((m) => m.id == 'del-real-1'), isFalse);

      // SQLite must not contain the item
      final dbItem = await dbService.getMediaItemById('del-real-1');
      expect(dbItem, isNull);

      // Playlist tracks in SQLite should also have cleaned it up
      final plFromDb = await dbService.getAllPlaylists();
      if (plFromDb.isNotEmpty) {
        expect(plFromDb.first.tracks.any((t) => t.id == 'del-real-1'), isFalse);
      }

      await tempDir.delete(recursive: true);
    });
  });

  group('Option 1: Playlist Reordering & Persistence Tests', () {
    test('PlaylistService reorderTrack updates track order in memory and SQLite', () async {
      final track1 = MediaItemModel(
        id: 'pl-t1',
        title: 'Song One',
        filePath: 'assets/audio/1.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final track2 = MediaItemModel(
        id: 'pl-t2',
        title: 'Song Two',
        filePath: 'assets/audio/2.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      final track3 = MediaItemModel(
        id: 'pl-t3',
        title: 'Song Three',
        filePath: 'assets/audio/3.mp3',
        format: 'MP3',
        dateModified: DateTime.now(),
        folderName: 'Music',
      );

      await dbService.upsertMediaItems([track1, track2, track3]);

      final playlistService = PlaylistService(dbService: dbService);
      await playlistService.init();

      final pl = playlistService.createPlaylist(
        name: 'Chill Vibes',
        tracks: [track1, track2, track3],
      );

      expect(pl.tracks[0].id, 'pl-t1');
      expect(pl.tracks[1].id, 'pl-t2');
      expect(pl.tracks[2].id, 'pl-t3');

      // Move track1 from index 0 to after track3 (index 3 in Flutter reordering)
      playlistService.reorderTrack(pl.id, 0, 3);

      final reordered = playlistService.allPlaylists.firstWhere((p) => p.id == pl.id);
      expect(reordered.tracks[0].id, 'pl-t2');
      expect(reordered.tracks[1].id, 'pl-t3');
      expect(reordered.tracks[2].id, 'pl-t1');

      // Verify SQLite persisted the new order
      final freshService = PlaylistService(dbService: dbService);
      await freshService.init();
      final persisted = freshService.allPlaylists.firstWhere((p) => p.id == pl.id);
      expect(persisted.tracks[0].id, 'pl-t2');
      expect(persisted.tracks[1].id, 'pl-t3');
      expect(persisted.tracks[2].id, 'pl-t1');
    });
  });
}

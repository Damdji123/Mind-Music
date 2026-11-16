import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_music/core/database/database_service.dart';
import 'package:mind_music/core/models/media_item_model.dart';
import 'package:mind_music/core/services/ads_service.dart';
import 'package:mind_music/core/services/playback_engine_service.dart';
import 'package:mind_music/core/services/playlist_service.dart';
import 'package:mind_music/core/services/storage_scanner_service.dart';
import 'package:mind_music/core/services/subscription_service.dart';
import 'package:mind_music/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;
  late SubscriptionService subService;
  late AdsService adsService;
  late PlaybackEngineService playbackService;
  late PlaylistService playlistService;
  late StorageScannerService scannerService;

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

    subService = SubscriptionService();
    adsService = AdsService(subService);
    playbackService = PlaybackEngineService(adsService, dbService: dbService);
    playlistService = PlaylistService(dbService: dbService);
    scannerService = StorageScannerService(dbService: dbService);

    await playlistService.init();
    await scannerService.init();
  });

  Widget buildTestableWidget(String playlistId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DatabaseService>.value(value: dbService),
        ChangeNotifierProvider<SubscriptionService>.value(value: subService),
        ChangeNotifierProvider<AdsService>.value(value: adsService),
        ChangeNotifierProvider<PlaybackEngineService>.value(value: playbackService),
        ChangeNotifierProvider<PlaylistService>.value(value: playlistService),
        ChangeNotifierProvider<StorageScannerService>.value(value: scannerService),
      ],
      child: MaterialApp(
        home: PlaylistDetailScreen(playlistId: playlistId),
      ),
    );
  }

  testWidgets('PlaylistDetailScreen displays header, metadata, and tracks correctly', (tester) async {
    final track1 = MediaItemModel(
      id: 'dt-1',
      title: 'Acoustic Morning',
      artist: 'Acoustic Lab',
      album: 'Dawn',
      filePath: 'assets/audio/morning.mp3',
      format: 'MP3',
      dateModified: DateTime.now(),
      folderName: 'Music',
    );
    final track2 = MediaItemModel(
      id: 'dt-2',
      title: 'Sunset Waves',
      artist: 'Waveform',
      album: 'Dusk',
      filePath: 'assets/audio/sunset.mp3',
      format: 'MP3',
      dateModified: DateTime.now(),
      folderName: 'Music',
    );

    final pl = playlistService.createPlaylist(
      name: 'Summer Chill',
      description: 'Relaxing tunes for warm summer days',
      tracks: [track1, track2],
      isAiMix: true,
      bpmRange: '90 - 110 BPM',
    );

    await tester.pumpWidget(buildTestableWidget(pl.id));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & description
    expect(find.text('Summer Chill'), findsOneWidget);
    expect(find.text('Relaxing tunes for warm summer days'), findsOneWidget);
    expect(find.text('SMART AI MIX'), findsOneWidget);
    expect(find.text('90 - 110 BPM'), findsOneWidget);

    // Verify track list
    expect(find.text('Acoustic Morning'), findsOneWidget);
    expect(find.text('Sunset Waves'), findsOneWidget);
    expect(find.text('Titres (2)'), findsOneWidget);

    // Verify Play All and Shuffle buttons exist
    expect(find.text('Tout lire'), findsOneWidget);
    expect(find.text('Aléatoire'), findsOneWidget);
  });

  testWidgets('Tapping Tout lire enqueues all tracks to PlaybackEngineService', (tester) async {
    final track1 = MediaItemModel(
      id: 'play-1',
      title: 'Track One',
      artist: 'Artist One',
      filePath: 'assets/audio/1.mp3',
      format: 'MP3',
      dateModified: DateTime.now(),
      folderName: 'Music',
    );
    final track2 = MediaItemModel(
      id: 'play-2',
      title: 'Track Two',
      artist: 'Artist Two',
      filePath: 'assets/audio/2.mp3',
      format: 'MP3',
      dateModified: DateTime.now(),
      folderName: 'Music',
    );

    final pl = playlistService.createPlaylist(
      name: 'Party Hits',
      tracks: [track1, track2],
    );

    await tester.pumpWidget(buildTestableWidget(pl.id));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 'Tout lire'
    await tester.tap(find.text('Tout lire'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(playbackService.queue.length, 2);
    expect(playbackService.queue.first.id, 'play-1');
  });
}

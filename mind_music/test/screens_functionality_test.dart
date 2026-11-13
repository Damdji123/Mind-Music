import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_music/core/database/database_service.dart';
import 'package:mind_music/core/models/media_item_model.dart';
import 'package:mind_music/core/services/ads_service.dart';
import 'package:mind_music/core/services/playback_engine_service.dart';
import 'package:mind_music/core/services/preferences_service.dart';
import 'package:mind_music/core/services/storage_scanner_service.dart';
import 'package:mind_music/core/services/subscription_service.dart';
import 'package:mind_music/core/theme/theme_provider.dart';
import 'package:mind_music/features/ai_copilot/presentation/screens/ai_voice_assistant_screen.dart';
import 'package:mind_music/features/library/presentation/screens/local_library_screen.dart';
import 'package:mind_music/features/player/presentation/screens/now_playing_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestableWidget(Widget child, {
  PlaybackEngineService? playbackService,
  StorageScannerService? scannerService,
  SubscriptionService? subService,
}) {
  final sub = subService ?? SubscriptionService();
  final ads = AdsService(sub);
  final playback = playbackService ?? PlaybackEngineService(ads);
  final scanner = scannerService ?? StorageScannerService();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider.value(value: sub),
      ChangeNotifierProvider.value(value: ads),
      ChangeNotifierProvider.value(value: playback),
      ChangeNotifierProvider.value(value: scanner),
      ChangeNotifierProvider(create: (_) => PreferencesService()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NowPlayingScreen Full Functionality Tests', () {
    testWidgets('Renders NowPlayingScreen with metadata, audio toggle, and controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads);

      final testMedia = MediaItemModel(
        id: '1',
        title: 'Better Days',
        artist: 'Omah Lay',
        album: 'Afrobeats Mix',
        duration: const Duration(minutes: 3, seconds: 56),
        filePath: 'assets/audio/better_days.mp3',
        format: 'FLAC',
        isHiRes: true,
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      playback.setQueue([testMedia], startIndex: 0);

      await tester.pumpWidget(createTestableWidget(const NowPlayingScreen(), playbackService: playback));
      await tester.pump();

      expect(find.text('Better Days'), findsWidgets);
      expect(find.text('Omah Lay'), findsWidgets);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle), findsOneWidget);
      expect(find.text('Buffer 100% Local'), findsOneWidget);
    });

    testWidgets('Tapping play/pause toggles playback state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads);
      addTearDown(() => playback.dispose());

      await tester.pumpWidget(createTestableWidget(const NowPlayingScreen(), playbackService: playback));
      await tester.pump();

      final playPauseFinder = find.byIcon(Icons.play_arrow_rounded);
      expect(playPauseFinder, findsOneWidget);

      await tester.tap(playPauseFinder);
      await tester.pump();
      expect(playback.isPlaying, isTrue);

      await playback.pause();
      await tester.pump();
      expect(playback.isPlaying, isFalse);
    });
  });

  group('LocalLibraryScreen Full Functionality Tests', () {
    testWidgets('Renders search field, segmented tabs, and AI Smart Curation card', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LocalLibraryScreen()));
      await tester.pump();

      expect(find.text('Library'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('AI Smart Curation'), findsOneWidget);
      expect(find.text('Organize Automatically'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      // Verify category tabs
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Music ('), findsOneWidget);
      expect(find.textContaining('Videos ('), findsOneWidget);
      expect(find.textContaining('Folders ('), findsOneWidget);
    });

    testWidgets('Switching tabs filters items properly', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LocalLibraryScreen()));
      await tester.pump();

      // Tap Videos tab
      final videoTabFinder = find.textContaining('Videos (');
      await tester.tap(videoTabFinder);
      await tester.pumpAndSettle();

      expect(find.text('Video Files'), findsOneWidget);
    });

    testWidgets('Search query filters media files instantly', (tester) async {
      final dbService = DatabaseService();
      await dbService.upsertMediaItems([
        MediaItemModel(
          id: 'test-1',
          title: 'Better Days',
          artist: 'Omah Lay',
          filePath: '/storage/emulated/0/Music/better_days.mp3',
          format: 'FLAC',
          dateModified: DateTime.now(),
          folderName: 'Music',
        ),
      ]);
      final scanner = StorageScannerService(dbService: dbService);
      await scanner.init();

      await tester.pumpWidget(createTestableWidget(
        const LocalLibraryScreen(),
        scannerService: scanner,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Omah');
      await tester.pumpAndSettle();

      expect(find.text('Better Days'), findsOneWidget);
    });
  });

  group('AiVoiceAssistantScreen Full Functionality Tests', () {
    testWidgets('Renders listening stage, intent card, and quick voice chips', (tester) async {
      await tester.pumpWidget(createTestableWidget(const AiVoiceAssistantScreen()));
      await tester.pump();

      expect(find.text('AI Copilot & Voice'), findsOneWidget);
      expect(find.text('Local Neural Engine • Instant'), findsOneWidget);
      expect(find.text('Listening Actively'), findsOneWidget);
      expect(find.text('Intent Confirmed'), findsOneWidget);
      expect(find.text('Start Session'), findsOneWidget);
      expect(find.text('Workout High-Energy Mix'), findsOneWidget);
      expect(find.text('Sleep in 45m'), findsOneWidget);
    });

    testWidgets('Submitting AI command updates recognized intent', (tester) async {
      await tester.pumpWidget(createTestableWidget(const AiVoiceAssistantScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Play jazz music');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('"Play jazz music"'), findsOneWidget);
    });
  });
}

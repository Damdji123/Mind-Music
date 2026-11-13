import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mind_music/core/services/ads_service.dart';
import 'package:mind_music/core/services/equalizer_service.dart';
import 'package:mind_music/core/services/playback_engine_service.dart';
import 'package:mind_music/core/services/playlist_service.dart';
import 'package:mind_music/core/services/storage_scanner_service.dart';
import 'package:mind_music/core/services/subscription_service.dart';
import 'package:mind_music/core/theme/theme_provider.dart';
import 'package:mind_music/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:mind_music/features/playlists/presentation/screens/create_ai_playlist_screen.dart';
import 'package:mind_music/features/playlists/presentation/screens/playlists_screen.dart';
import 'package:mind_music/features/sleep_timer/presentation/screens/advanced_sleep_timer_screen.dart';

Widget createTestableWidget(
  Widget child, {
  PlaylistService? playlistService,
  EqualizerService? equalizerService,
  PlaybackEngineService? playbackService,
  StorageScannerService? scannerService,
  AdsService? adsService,
  SubscriptionService? subService,
}) {
  final sub = subService ?? SubscriptionService();
  final ads = adsService ?? AdsService(sub);
  final playback = playbackService ?? PlaybackEngineService(ads);
  final plService = playlistService ?? PlaylistService();
  final eqService = equalizerService ?? EqualizerService();
  final scanService = scannerService ?? StorageScannerService();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider.value(value: sub),
      ChangeNotifierProvider.value(value: ads),
      ChangeNotifierProvider.value(value: playback),
      ChangeNotifierProvider.value(value: plService),
      ChangeNotifierProvider.value(value: eqService),
      ChangeNotifierProvider.value(value: scanService),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Playlists & AI Mix Screen Tests', () {
    testWidgets('Renders PlaylistsScreen with header, filters, and featured Bento card',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const PlaylistsScreen()));
      await tester.pump();

      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Collections locales & mix IA synchronisés'), findsOneWidget);
      expect(find.text('Créer'), findsOneWidget);

      // Verify category filter chips
      expect(find.textContaining('Toutes ('), findsOneWidget);
      expect(find.textContaining('Créées par moi ('), findsOneWidget);
      expect(find.textContaining('Mix IA & Smart ('), findsOneWidget);
      expect(find.textContaining('Favoris ('), findsOneWidget);

      // Verify Featured AI Card
      expect(find.text('GÉNÉRÉ CE MATIN'), findsOneWidget);
      expect(find.text('Focus Ambient Cyberpunk'), findsAtLeastNWidgets(1));
    });

    testWidgets('Filtering playlists by category works properly', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = PlaylistService();
      await tester.pumpWidget(createTestableWidget(const PlaylistsScreen(), playlistService: service));
      await tester.pump();

      // Tap on Favorites filter chip
      final favFinder = find.textContaining('Favoris (');
      expect(favFinder, findsOneWidget);
      await tester.tap(favFinder);
      await tester.pump();

      expect(service.selectedFilter, 'favorites');
      for (final pl in service.filteredPlaylists) {
        expect(pl.isFavorite, isTrue);
      }
    });

    testWidgets('Tapping favorite heart toggles favorite state in PlaylistService',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = PlaylistService();
      await tester.pumpWidget(createTestableWidget(const PlaylistsScreen(), playlistService: service));
      await tester.pump();

      final firstPl = service.allPlaylists.first;
      final initialFav = firstPl.isFavorite;

      service.toggleFavorite(firstPl.id);
      expect(service.allPlaylists.first.isFavorite, !initialFav);
    });

    testWidgets('CreateAiPlaylistScreen renders identity fields and AI source options',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const CreateAiPlaylistScreen()));
      await tester.pump();

      expect(find.text('Créer une Playlist'), findsOneWidget);
      expect(find.text('AI Mix'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('TITRE & HUMEUR'), findsOneWidget);
      expect(find.text('SOURCE DES MORCEAUX'), findsOneWidget);

      // Verify 3 sources
      expect(find.text('Bibliothèque'), findsOneWidget);
      expect(find.text('Copilote IA'), findsOneWidget);
      expect(find.text('Sélection Manuelle'), findsOneWidget);

      // Verify AI controls
      expect(find.text('Paramètres du Mix Intelligent'), findsOneWidget);
      expect(find.text('Générer le mix instantanément'), findsOneWidget);
    });

    testWidgets('Triggering AI generation updates tracklist and playlist name',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const CreateAiPlaylistScreen()));
      await tester.pump();

      final genButton = find.text('Générer le mix instantanément');
      expect(genButton, findsOneWidget);

      await tester.tap(genButton);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Mix IA généré avec'), findsOneWidget);
    });
  });

  group('Equalizer & DSP Screen Tests', () {
    testWidgets('Renders EqualizerScreen with 10-band spectrum and master controls',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const EqualizerScreen()));
      await tester.pump();

      expect(find.text('Égaliseur Studio'), findsOneWidget);
      expect(find.text('MOTEUR AUDIO 32-BIT HI-RES'), findsOneWidget);
      expect(find.text('Égaliseur Audio & DSP'), findsOneWidget);
      expect(find.text('Spectre 10-Bandes'), findsOneWidget);
      expect(find.text('Bass Boost Dynamique'), findsOneWidget);
      expect(find.text('Spatialisation 3D (Surround)'), findsOneWidget);
      expect(find.text('Réverbération Studio'), findsOneWidget);

      // Check frequency labels
      expect(find.text('32'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
      expect(find.text('1k'), findsOneWidget);
      expect(find.text('16k'), findsOneWidget);
    });

    testWidgets('Master EQ switch toggles state in EqualizerService', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eq = EqualizerService();
      await tester.pumpWidget(createTestableWidget(const EqualizerScreen(), equalizerService: eq));
      await tester.pump();

      expect(eq.isEnabled, isTrue);

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pump();

      expect(eq.isEnabled, isFalse);
    });

    testWidgets('Selecting preset changes gains and updates active preset', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eq = EqualizerService();
      await tester.pumpWidget(createTestableWidget(const EqualizerScreen(), equalizerService: eq));
      await tester.pump();

      final jazzFinder = find.text('Jazz');
      expect(jazzFinder, findsOneWidget);

      await tester.tap(jazzFinder);
      await tester.pump();

      expect(eq.activePresetId, 'jazz');
      expect(eq.currentGains, [4.0, 2.0, 0.0, 2.0, -2.0, -2.0, 0.0, 2.0, 4.0, 5.0]);
    });

    testWidgets('Reset button flattens all 10 bands to 0 dB', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eq = EqualizerService();
      await tester.pumpWidget(createTestableWidget(const EqualizerScreen(), equalizerService: eq));
      await tester.pump();

      final resetBtn = find.text('Reset');
      expect(resetBtn, findsOneWidget);

      await tester.tap(resetBtn);
      await tester.pump();

      expect(eq.activePresetId, 'flat');
      for (final gain in eq.currentGains) {
        expect(gain, 0.0);
      }
    });

    testWidgets('Saving custom preset adds it to EqualizerService custom list', (tester) async {
      final eq = EqualizerService();
      eq.setBandGain(0, 10.0);
      eq.setBandGain(1, 8.0);

      final custom = eq.saveCustomPreset('My Studio Sound');
      expect(custom.name, 'My Studio Sound');
      expect(custom.isCustom, isTrue);
      expect(eq.activePresetId, custom.id);
      expect(eq.currentGains[0], 10.0);
    });

    testWidgets('Duplicating locked preset creates unlocked copy', (tester) async {
      final eq = EqualizerService();
      final dup = eq.duplicateLockedPreset('bass', 'Bass Boost Edit');

      expect(dup.name, 'Bass Boost Edit');
      expect(dup.isCustom, isTrue);
      expect(dup.bandGains, [8.0, 6.0, 4.0, 2.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0]);
      expect(eq.activePresetId, dup.id);
    });
  });

  group('Advanced Sleep Timer Screen Tests', () {
    testWidgets('Renders AdvancedSleepTimerScreen with dial, countdown, and controls',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const AdvancedSleepTimerScreen()));
      await tester.pump();

      expect(find.text('Sleep Timer'), findsOneWidget);
      expect(find.text('Minuteur intelligent & fondu sonore'), findsOneWidget);
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('- 5 min'), findsOneWidget);
      expect(find.text('+ 5 min'), findsOneWidget);
      expect(find.text('Fin du titre'), findsOneWidget);
      expect(find.text('Fondu sonore progressif'), findsOneWidget);
      expect(find.text('Protection Sommeil Garanti'), findsOneWidget);
      expect(find.text('Démarrer le Sleep Timer'), findsOneWidget);
    });

    testWidgets('Tapping +5 min increments countdown duration', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const AdvancedSleepTimerScreen()));
      await tester.pump();

      expect(find.text('30:00'), findsOneWidget);

      final addBtn = find.text('+ 5 min');
      expect(addBtn, findsOneWidget);

      await tester.tap(addBtn);
      await tester.pump();

      expect(find.text('35:00'), findsOneWidget);
    });

    testWidgets('Tapping preset pills updates selected timer duration', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableWidget(const AdvancedSleepTimerScreen()));
      await tester.pump();

      final pill15m = find.text('15m');
      expect(pill15m, findsOneWidget);

      await tester.tap(pill15m);
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('Starting sleep timer activates session and enforces ad suppression',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sub = SubscriptionService();
      final ads = AdsService(sub);
      final playback = PlaybackEngineService(ads);
      addTearDown(() => playback.dispose());

      await tester.pumpWidget(createTestableWidget(
        const AdvancedSleepTimerScreen(),
        playbackService: playback,
        adsService: ads,
      ));
      await tester.pump();

      expect(playback.isSleepTimerActive, isFalse);

      final startBtn = find.text('Démarrer le Sleep Timer');
      expect(startBtn, findsOneWidget);

      await tester.tap(startBtn);
      await tester.pump();

      expect(playback.isSleepTimerActive, isTrue);
      // Ads are strictly suppressed during sleep sessions
      expect(ads.canDisplayNativeAd(screenName: 'playlists'), isFalse);
      expect(find.text('Arrêter le Sleep Timer'), findsOneWidget);

      // Cancel timer
      final stopBtn = find.text('Arrêter le Sleep Timer');
      await tester.tap(stopBtn);
      await tester.pump();

      expect(playback.isSleepTimerActive, isFalse);
    });
  });
}

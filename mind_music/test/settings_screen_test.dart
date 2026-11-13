import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mind_music/core/services/ads_service.dart';
import 'package:mind_music/core/services/preferences_service.dart';
import 'package:mind_music/core/services/storage_scanner_service.dart';
import 'package:mind_music/core/services/subscription_service.dart';
import 'package:mind_music/core/theme/theme_provider.dart';
import 'package:mind_music/features/settings/presentation/screens/settings_screen.dart';

Widget createSettingsTestableWidget({
  PreferencesService? preferencesService,
  ThemeProvider? themeProvider,
  SubscriptionService? subscriptionService,
  StorageScannerService? storageScannerService,
}) {
  final prefs = preferencesService ?? PreferencesService();
  final theme = themeProvider ?? ThemeProvider();
  final sub = subscriptionService ?? SubscriptionService();
  final scanner = storageScannerService ?? StorageScannerService();
  final ads = AdsService(sub);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: prefs),
      ChangeNotifierProvider.value(value: theme),
      ChangeNotifierProvider.value(value: sub),
      ChangeNotifierProvider.value(value: scanner),
      ChangeNotifierProvider.value(value: ads),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService Unit Tests', () {
    test('Default values are initialized properly', () {
      final prefs = PreferencesService();
      expect(prefs.themeMode, 'liquidGlass');
      expect(prefs.ambientDynamicBlur, isTrue);
      expect(prefs.pureBlackAmoled, isFalse);
      expect(prefs.startupChime, isTrue);
      expect(prefs.uiSoundVolume, 0.75);
      expect(prefs.hapticFeedback, isTrue);
      expect(prefs.hapticIntensity, HapticLevel.medium);
      expect(prefs.gaplessPlayback, isTrue);
      expect(prefs.voiceWakeWord, isFalse);
      expect(prefs.autoTagMetadata, isTrue);
    });

    test('Updating themeMode notifies listeners and sets state', () async {
      final prefs = PreferencesService();
      int notifyCount = 0;
      prefs.addListener(() => notifyCount++);

      await prefs.setThemeMode('cyberpunk');
      expect(prefs.themeMode, 'cyberpunk');
      expect(notifyCount, 1);
    });

    test('Setting Pure Black AMOLED enables oledDark mode', () async {
      final prefs = PreferencesService();
      await prefs.setPureBlackAmoled(true);
      expect(prefs.pureBlackAmoled, isTrue);
      expect(prefs.themeMode, 'oledDark');
    });

    test('UI volume clamps correctly between 0.0 and 1.0', () async {
      final prefs = PreferencesService();
      await prefs.setUiSoundVolume(1.5);
      expect(prefs.uiSoundVolume, 1.0);

      await prefs.setUiSoundVolume(-0.5);
      expect(prefs.uiSoundVolume, 0.0);
    });

    test('resetToDefaults restores initial configuration', () async {
      final prefs = PreferencesService();
      await prefs.setThemeMode('sunset');
      await prefs.setUiSoundVolume(0.2);
      await prefs.setHapticFeedback(false);

      await prefs.resetToDefaults();
      expect(prefs.themeMode, 'liquidGlass');
      expect(prefs.uiSoundVolume, 0.75);
      expect(prefs.hapticFeedback, isTrue);
    });
  });

  group('SettingsScreen Widget & Interaction Tests', () {
    testWidgets('Renders all primary sections and headers', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSettingsTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('v1.0.0 • Storage & AI Control'), findsOneWidget);
      expect(find.text('Mind-Music Player'), findsOneWidget);
      expect(find.text('Theme & Aesthetics'), findsOneWidget);
      expect(find.text('Playback & Audio Engine'), findsOneWidget);
      expect(find.text('Haptics & Sensory Effects'), findsOneWidget);
      expect(find.text('AI & Smart Assistant'), findsOneWidget);
      expect(find.text('Library & Local Storage'), findsOneWidget);
      expect(find.text('System & Privacy'), findsOneWidget);
    });

    testWidgets('Tapping theme pill updates selected theme in Preferences and ThemeProvider', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = PreferencesService();
      final theme = ThemeProvider();

      await tester.pumpWidget(createSettingsTestableWidget(
        preferencesService: prefs,
        themeProvider: theme,
      ));
      await tester.pumpAndSettle();

      final cyberpunkPill = find.text('Cyberpunk');
      expect(cyberpunkPill, findsOneWidget);
      await tester.tap(cyberpunkPill);
      await tester.pumpAndSettle();

      expect(prefs.themeMode, 'cyberpunk');
    });

    testWidgets('Clear cache button triggers SnackBar confirmation', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSettingsTestableWidget());
      await tester.pumpAndSettle();

      final clearBtn = find.text('Clear Cache');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('1.2 GB freed'), findsOneWidget);
    });

    testWidgets('Help button opens dialog with privacy and offline explanation', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSettingsTestableWidget());
      await tester.pumpAndSettle();

      final helpBtn = find.byIcon(Icons.help_outline_rounded);
      expect(helpBtn, findsOneWidget);
      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Help & Documentation'), findsOneWidget);
      expect(find.textContaining('100% offline-first media player'), findsOneWidget);

      final closeBtn = find.text('Close');
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
      expect(find.text('Help & Documentation'), findsNothing);
    });

    testWidgets('Changelog button opens changelog dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSettingsTestableWidget());
      await tester.pumpAndSettle();

      final changelogBtn = find.text('Changelog');
      expect(changelogBtn, findsOneWidget);
      await tester.tap(changelogBtn);
      await tester.pumpAndSettle();

      expect(find.text('Changelog v1.0.0'), findsOneWidget);
      expect(find.textContaining('10-Band Graphic Equalizer'), findsOneWidget);

      final doneBtn = find.text('Done');
      await tester.tap(doneBtn);
      await tester.pumpAndSettle();
      expect(find.text('Changelog v1.0.0'), findsNothing);
    });
  });
}

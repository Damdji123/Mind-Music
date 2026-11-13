import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/database/database_service.dart';
import 'core/services/ads_service.dart';
import 'core/services/equalizer_service.dart';
import 'core/services/playback_engine_service.dart';
import 'core/services/playlist_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/storage_scanner_service.dart';
import 'core/services/subscription_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark status and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final preferencesService = PreferencesService();
  await preferencesService.init();

  final databaseService = DatabaseService();
  // Ensure SQLite schema is prepared
  await databaseService.database;

  runApp(MindMusicApp(
    preferencesService: preferencesService,
    databaseService: databaseService,
  ));
}

class MindMusicApp extends StatelessWidget {
  final PreferencesService preferencesService;
  final DatabaseService databaseService;

  const MindMusicApp({
    super.key,
    required this.preferencesService,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: preferencesService),
        ChangeNotifierProvider.value(value: databaseService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionService()),
        ChangeNotifierProvider(
          create: (_) => StorageScannerService(dbService: databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaylistService(dbService: databaseService),
        ),
        ChangeNotifierProvider(create: (_) => EqualizerService()),
        ChangeNotifierProxyProvider<SubscriptionService, AdsService>(
          create: (ctx) => AdsService(ctx.read<SubscriptionService>()),
          update: (_, subService, adsService) =>
              adsService ?? AdsService(subService),
        ),
        ChangeNotifierProxyProvider<AdsService, PlaybackEngineService>(
          create: (ctx) => PlaybackEngineService(
            ctx.read<AdsService>(),
            dbService: databaseService,
          ),
          update: (_, adsService, playbackService) =>
              playbackService ??
              PlaybackEngineService(adsService, dbService: databaseService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Mind-Music',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

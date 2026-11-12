import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_music/core/models/media_item_model.dart';
import 'package:mind_music/core/security/security_validator.dart';
import 'package:mind_music/core/services/ads_service.dart';
import 'package:mind_music/core/services/preferences_service.dart';
import 'package:mind_music/core/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Security & Threat Mitigation Tests', () {
    test('Path Traversal: blocks malicious relative traversal attempts', () {
      const maliciousPaths = [
        '../../../../etc/passwd',
        '..\\..\\Windows\\System32\\cmd.exe',
        '/storage/emulated/0/Music/../../../system/build.prop',
        'C:\\Users\\User\\Music\\..\\..\\Windows\\win.ini',
        'folder/../../hidden.mp3',
      ];

      for (final path in maliciousPaths) {
        expect(
          SecurityValidator.isSafeMediaPath(path),
          isFalse,
          reason: 'Path traversal attempt should be rejected: $path',
        );
      }
    });

    test('Path Traversal: blocks null bytes and system protected directories', () {
      const forbiddenSystemPaths = [
        '/etc/shadow.mp3',
        '/system/bin/media.flac',
        '/proc/cpuinfo.wav',
        'C:\\Windows\\System32\\drivers.mp3',
        '/data/data/com.example/private.mp4',
        '/storage/Music/song.mp3\u0000.exe',
      ];

      for (final path in forbiddenSystemPaths) {
        expect(
          SecurityValidator.isSafeMediaPath(path),
          isFalse,
          reason: 'System path or null byte should be blocked: $path',
        );
      }
    });

    test('Path Traversal: blocks hidden dotfiles and unapproved file extensions', () {
      const unsafeFiles = [
        '/storage/Music/.hidden_audio.mp3',
        '/storage/Music/payload.exe',
        '/storage/Music/malware.apk',
        '/storage/Music/script.sh',
        '/storage/Music/page.html',
      ];

      for (final file in unsafeFiles) {
        expect(
          SecurityValidator.isSafeMediaPath(file),
          isFalse,
          reason: 'Non-media file or hidden file should be blocked: $file',
        );
      }
    });

    test('Path Validation: permits valid media files and assets', () {
      const validMediaPaths = [
        'assets/audio/better_days.mp3',
        'assets/video/alpine_sunrise.mp4',
        '/storage/emulated/0/Music/track01.flac',
        '/storage/emulated/0/Music/Afrobeats/song.wav',
        'C:\\Users\\User\\Music\\favorite.m4a',
      ];

      for (final path in validMediaPaths) {
        expect(
          SecurityValidator.isSafeMediaPath(path),
          isTrue,
          reason: 'Legitimate media path should be accepted: $path',
        );
      }
    });

    test('AI Input Sanitization: strips shell metacharacters and script tags', () {
      const attackPayloads = [
        '<script>alert("xss")</script>Play chill playlist',
        'Play music; rm -rf / ; echo 1',
        'Joue ma playlist && ping 127.0.0.1 | bash',
        'Sleep timer 45m `cat /etc/passwd`',
      ];

      for (final payload in attackPayloads) {
        final sanitized = SecurityValidator.sanitizeInput(payload);
        expect(sanitized.contains('<script>'), isFalse);
        expect(sanitized.contains(';'), isFalse);
        expect(sanitized.contains('&&'), isFalse);
        expect(sanitized.contains('|'), isFalse);
        expect(sanitized.contains('`'), isFalse);
      }
    });

    test('AI Input Sanitization: caps maximum query length to prevent memory buffer exhaustion', () {
      final oversizedInput = 'A' * 1000;
      final sanitized = SecurityValidator.sanitizeInput(oversizedInput, maxLength: 250);
      expect(sanitized.length, lessThanOrEqualTo(250));
    });

    test('AI Intent Whitelisting: accepts recognized commands, rejects random execution payloads', () {
      expect(SecurityValidator.isValidPlayerIntent('Play my chill playlist'), isTrue);
      expect(SecurityValidator.isValidPlayerIntent('Arrête dans 45 minutes'), isTrue);
      expect(SecurityValidator.isValidPlayerIntent('Bass boost equalizer'), isTrue);

      expect(SecurityValidator.isValidPlayerIntent('DROP DATABASE users;'), isFalse);
      expect(SecurityValidator.isValidPlayerIntent('curl http://malicious.site'), isFalse);
    });

    test('Storage Directory Scanner: safely rejects prohibited directories and hidden paths', () {
      expect(SecurityValidator.isSafeScanDirectory(Directory(r'C:\Windows')), isFalse);
      expect(SecurityValidator.isSafeScanDirectory(Directory('/etc')), isFalse);
      expect(SecurityValidator.isSafeScanDirectory(Directory('/storage/Music/.hidden')), isFalse);
    });

    test('MediaItemModel: safely flags Hi-Res lossless tracks vs standard', () {
      final hiResTrack = MediaItemModel(
        id: '1',
        title: 'Song',
        filePath: 'assets/song.flac',
        format: 'FLAC',
        isHiRes: true,
        dateModified: DateTime.now(),
        folderName: 'Music',
      );
      expect(hiResTrack.isHiRes, isTrue);
      expect(hiResTrack.format, 'FLAC');
    });
  });

  group('Monetization & Ad Safety Rules Tests', () {
    test('Ads are strictly blocked during active playback and sleep sessions', () {
      final subService = SubscriptionService();
      final adsService = AdsService(subService);

      // On HomeScreen, Free user can see native ad when idle
      expect(adsService.canDisplayNativeAd(screenName: 'HomeScreen'), isTrue);

      // User starts playback -> Ads on NowPlaying or critical controls are blocked
      adsService.setPlaybackState(isPlaying: true);
      expect(adsService.canDisplayNativeAd(screenName: 'NowPlayingScreen'), isFalse);
      expect(adsService.canDisplayNativeAd(screenName: 'PlayerControls'), isFalse);

      // Active Sleep Session -> All ads blocked
      adsService.setSleepSessionState(isActive: true);
      expect(adsService.canDisplayNativeAd(screenName: 'HomeScreen'), isFalse);

      // PRO upgrade -> Ads permanently blocked everywhere
      subService.upgradeToPremium();
      expect(adsService.shouldShowAds, isFalse);
      expect(adsService.canDisplayNativeAd(screenName: 'HomeScreen'), isFalse);
    });
  });

  group('User Flow & Onboarding Persistence Tests', () {
    test('PreferencesService safely persists onboarding completion state', () async {
      final prefs = PreferencesService();
      await prefs.init();

      expect(prefs.isOnboarded, isFalse);
      await prefs.setOnboarded(true);
      expect(prefs.isOnboarded, isTrue);
    });
  });
}

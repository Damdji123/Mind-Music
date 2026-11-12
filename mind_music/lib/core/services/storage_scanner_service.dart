import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../models/media_item_model.dart';
import '../security/security_validator.dart';

class StorageScannerService with ChangeNotifier {
  bool _isScanning = false;
  double _scanProgress = 0.0;
  List<MediaItemModel> _audioFiles = [];
  List<MediaItemModel> _videoFiles = [];
  Map<String, List<MediaItemModel>> _folders = {};
  int _untaggedCount = 0;

  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  List<MediaItemModel> get audioFiles => _audioFiles;
  List<MediaItemModel> get videoFiles => _videoFiles;
  List<MediaItemModel> get allMedia => [..._audioFiles, ..._videoFiles];
  Map<String, List<MediaItemModel>> get folders => _folders;
  int get untaggedCount => _untaggedCount;

  StorageScannerService() {
    _loadInitialMockLibrary();
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.request();
      final videoStatus = await Permission.videos.request();
      final storageStatus = await Permission.storage.request();

      return audioStatus.isGranted || videoStatus.isGranted || storageStatus.isGranted;
    }
    return true;
  }

  Future<void> scanDeviceStorage() async {
    _isScanning = true;
    _scanProgress = 0.0;
    notifyListeners();

    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission && !Platform.isWindows) {
        debugPrint('[StorageScanner] Storage permissions not granted.');
        _isScanning = false;
        notifyListeners();
        return;
      }

      final List<Directory> scanTargets = _getSystemScanDirectories();
      final List<MediaItemModel> foundAudios = [];
      final List<MediaItemModel> foundVideos = [];
      final Map<String, List<MediaItemModel>> folderMap = {};
      int untagged = 0;

      for (int i = 0; i < scanTargets.length; i++) {
        final dir = scanTargets[i];

        // Security check: Verify directory is safe to scan
        if (await dir.exists() && SecurityValidator.isSafeScanDirectory(dir)) {
          try {
            await for (final entity in dir.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                // Security check: Validate path against traversal and extension whitelist
                if (!SecurityValidator.isSafeMediaPath(entity.path)) {
                  continue;
                }

                final ext = p.extension(entity.path).toLowerCase();
                final isAudio = SecurityValidator.allowedAudioExtensions.contains(ext);
                final isVideo = SecurityValidator.allowedVideoExtensions.contains(ext);

                if (isAudio || isVideo) {
                  final stat = await entity.stat();
                  // Skip zero byte or corrupted files
                  if (stat.size <= 0) continue;

                  final item = _parseMediaFromFile(entity, stat, isVideo: isVideo, ext: ext);

                  if (item.artist == 'Unknown Artist' || item.album == 'Unknown Album') {
                    untagged++;
                  }

                  if (isVideo) {
                    foundVideos.add(item);
                  } else {
                    foundAudios.add(item);
                  }

                  folderMap.putIfAbsent(item.folderName, () => []).add(item);
                }
              }
            }
          } catch (e) {
            debugPrint('[StorageScanner] Error scanning directory ${dir.path}: $e');
          }
        }
        _scanProgress = (i + 1) / scanTargets.length;
        notifyListeners();
      }

      if (foundAudios.isNotEmpty || foundVideos.isNotEmpty) {
        _audioFiles = foundAudios;
        _videoFiles = foundVideos;
        _folders = folderMap;
        _untaggedCount = untagged;
      }
    } catch (e) {
      debugPrint('[StorageScanner] Scan exception: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  MediaItemModel _parseMediaFromFile(
    File file,
    FileStat stat, {
    required bool isVideo,
    required String ext,
  }) {
    final fileName = p.basenameWithoutExtension(file.path);
    final folderName = p.basename(p.dirname(file.path));

    String title = fileName;
    String artist = 'Unknown Artist';

    // Parse "Artist - Title" filename convention if present
    if (fileName.contains(' - ')) {
      final parts = fileName.split(' - ');
      artist = parts[0].trim();
      title = parts.sublist(1).join(' - ').trim();
    }

    final format = ext.replaceAll('.', '').toUpperCase();
    final isHiRes = format == 'FLAC' || format == 'WAV' || format == 'ALAC';

    return MediaItemModel(
      id: file.path.hashCode.toString(),
      title: title,
      artist: artist,
      album: folderName,
      filePath: file.path,
      format: format,
      isVideo: isVideo,
      isHiRes: isHiRes,
      sizeInBytes: stat.size,
      dateModified: stat.modified,
      folderName: folderName,
    );
  }

  List<Directory> _getSystemScanDirectories() {
    List<Directory> dirs = [];

    if (Platform.isAndroid) {
      dirs.addAll([
        Directory('/storage/emulated/0/Music'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Movies'),
        Directory('/storage/emulated/0/DCIM'),
        Directory('/storage/emulated/0/Audiobooks'),
      ]);
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        dirs.addAll([
          Directory('$userProfile\\Music'),
          Directory('$userProfile\\Videos'),
          Directory('$userProfile\\Downloads'),
        ]);
      }
    }
    return dirs;
  }

  void _loadInitialMockLibrary() {
    _audioFiles = [
      MediaItemModel(
        id: 'mock-1',
        title: 'Better Days',
        artist: 'Omah Lay',
        album: 'Afrobeats Mix 2026',
        duration: const Duration(minutes: 3, seconds: 56),
        filePath: 'assets/audio/better_days.mp3',
        format: 'FLAC',
        isHiRes: true,
        sizeInBytes: 34 * 1024 * 1024,
        dateModified: DateTime.now().subtract(const Duration(days: 1)),
        folderName: 'Afrobeats',
      ),
      MediaItemModel(
        id: 'mock-2',
        title: 'Midnight Reverie (Ambient Focus)',
        artist: 'Celestial Echoes',
        album: 'Chill & Sleep Sessions',
        duration: const Duration(minutes: 5, seconds: 12),
        filePath: 'assets/audio/midnight_reverie.mp3',
        format: 'FLAC',
        isHiRes: true,
        sizeInBytes: 42 * 1024 * 1024,
        dateModified: DateTime.now().subtract(const Duration(days: 2)),
        folderName: 'Relaxation',
      ),
      MediaItemModel(
        id: 'mock-3',
        title: 'Neon Horizon',
        artist: 'CyberPulse',
        album: 'Synthwave Night Drive',
        duration: const Duration(minutes: 4, seconds: 20),
        filePath: 'assets/audio/neon_horizon.mp3',
        format: 'MP3',
        isHiRes: false,
        sizeInBytes: 10 * 1024 * 1024,
        dateModified: DateTime.now().subtract(const Duration(days: 3)),
        folderName: 'Workout',
      ),
      MediaItemModel(
        id: 'mock-4',
        title: 'Golden Hour Acoustic',
        artist: 'Aura Bloom',
        album: 'Coffee & Code',
        duration: const Duration(minutes: 3, seconds: 45),
        filePath: 'assets/audio/golden_hour.mp3',
        format: 'WAV',
        isHiRes: true,
        sizeInBytes: 38 * 1024 * 1024,
        dateModified: DateTime.now().subtract(const Duration(days: 5)),
        folderName: 'Acoustic',
      ),
    ];

    _videoFiles = [
      MediaItemModel(
        id: 'mock-v1',
        title: 'Alpine Sunrise 4K',
        artist: 'Nature Vibes',
        album: 'Travel & Scenery',
        duration: const Duration(minutes: 8, seconds: 40),
        filePath: 'assets/video/alpine_sunrise.mp4',
        format: 'MP4',
        isVideo: true,
        isHiRes: true,
        sizeInBytes: 280 * 1024 * 1024,
        dateModified: DateTime.now().subtract(const Duration(days: 4)),
        folderName: 'Videos',
      ),
      MediaItemModel(
        id: 'mock-v2',
        title: 'Better Days (Official 4K Music Video)',
        artist: 'Omah Lay',
        album: 'Music Videos',
        duration: const Duration(minutes: 4, seconds: 10),
        filePath: 'assets/video/better_days_clip.mp4',
        format: 'MP4',
        isVideo: true,
        isHiRes: true,
        sizeInBytes: 160 * 1024 * 1024,
        dateModified: DateTime.now().subtract(const Duration(days: 1)),
        folderName: 'Videos',
      ),
    ];

    _folders = {
      'Afrobeats': [_audioFiles[0]],
      'Relaxation': [_audioFiles[1]],
      'Workout': [_audioFiles[2]],
      'Acoustic': [_audioFiles[3]],
      'Videos': _videoFiles,
    };

    _untaggedCount = 42;
  }
}

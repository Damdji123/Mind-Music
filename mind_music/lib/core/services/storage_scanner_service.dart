import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../database/database_service.dart';
import '../models/media_folder_model.dart';
import '../models/media_item_model.dart';
import '../security/security_validator.dart';

class StorageScannerService with ChangeNotifier {
  final DatabaseService _dbService;

  bool _isScanning = false;
  double _scanProgress = 0.0;
  List<MediaItemModel> _audioFiles = [];
  List<MediaItemModel> _videoFiles = [];
  List<MediaFolderModel> _folderModels = [];
  Map<String, List<MediaItemModel>> _folders = {};
  int _untaggedCount = 0;
  bool _hasLoadedFromDb = false;

  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  List<MediaItemModel> get audioFiles => _audioFiles;
  List<MediaItemModel> get videoFiles => _videoFiles;
  List<MediaItemModel> get allMedia => [..._audioFiles, ..._videoFiles];
  List<MediaItemModel> get favoriteFiles =>
      allMedia.where((m) => m.isFavorite).toList();
  List<MediaFolderModel> get folderModels => _folderModels;
  Map<String, List<MediaItemModel>> get folders => _folders;
  int get untaggedCount => _untaggedCount;
  bool get hasLoadedFromDb => _hasLoadedFromDb;

  StorageScannerService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService() {
    init();
  }

  /// Initialize and load cached real media from the SQLite database
  Future<void> init() async {
    try {
      final audios = await _dbService.getAudioItems();
      final videos = await _dbService.getVideoItems();
      final folders = await _dbService.getAllFolders();

      _audioFiles = audios;
      _videoFiles = videos;
      _folderModels = folders;
      _rebuildFolderMap();
      _recomputeUntagged();
      _hasLoadedFromDb = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[StorageScanner] SQLite initial load error: $e');
    }
  }

  /// Requests real device storage permissions across modern Android & legacy versions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.request();
      final videoStatus = await Permission.videos.request();
      final storageStatus = await Permission.storage.request();

      return audioStatus.isGranted ||
          videoStatus.isGranted ||
          storageStatus.isGranted;
    }
    return true;
  }

  /// Scans real device storage for real audio and video files and updates SQLite
  Future<void> scanDeviceStorage({bool force = false}) async {
    if (_isScanning) return;

    _isScanning = true;
    _scanProgress = 0.0;
    notifyListeners();

    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission && !Platform.isWindows) {
        debugPrint('[StorageScanner] Device storage permissions not granted.');
        _isScanning = false;
        notifyListeners();
        return;
      }

      final List<Directory> scanTargets = _getSystemScanDirectories();
      final List<MediaItemModel> foundAudios = [];
      final List<MediaItemModel> foundVideos = [];
      final Map<String, _FolderCollector> folderCollectors = {};
      int untagged = 0;

      for (int i = 0; i < scanTargets.length; i++) {
        final dir = scanTargets[i];

        if (await dir.exists() && SecurityValidator.isSafeScanDirectory(dir)) {
          try {
            await for (final entity in dir.list(
              recursive: true,
              followLinks: false,
            )) {
              if (entity is File) {
                if (!SecurityValidator.isSafeMediaPath(entity.path)) {
                  continue;
                }

                final ext = p.extension(entity.path).toLowerCase();
                final isAudio =
                    SecurityValidator.allowedAudioExtensions.contains(ext);
                final isVideo =
                    SecurityValidator.allowedVideoExtensions.contains(ext);

                if (isAudio || isVideo) {
                  final stat = await entity.stat();
                  if (stat.size <= 0) continue;

                  final item = _parseMediaFromFile(
                    entity,
                    stat,
                    isVideo: isVideo,
                    ext: ext,
                  );

                  if (item.artist == 'Unknown Artist' ||
                      item.album == 'Unknown Album') {
                    untagged++;
                  }

                  if (isVideo) {
                    foundVideos.add(item);
                  } else {
                    foundAudios.add(item);
                  }

                  final folderPath = p.dirname(entity.path);
                  final folderName = p.basename(folderPath);
                  final collector = folderCollectors.putIfAbsent(
                    folderPath,
                    () => _FolderCollector(
                      path: folderPath,
                      name: folderName,
                    ),
                  );

                  if (isVideo) {
                    collector.videoCount++;
                  } else {
                    collector.audioCount++;
                  }
                  collector.totalSizeBytes += stat.size;
                  if (stat.modified.isAfter(collector.lastModified)) {
                    collector.lastModified = stat.modified;
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('[StorageScanner] Directory scan skipped ${dir.path}: $e');
          }
        }
        _scanProgress = (i + 1) / scanTargets.length;
        notifyListeners();
      }

      final List<MediaFolderModel> discoveredFolders = folderCollectors.values
          .map((c) => MediaFolderModel(
                path: c.path,
                name: c.name,
                audioCount: c.audioCount,
                videoCount: c.videoCount,
                totalSizeBytes: c.totalSizeBytes,
                lastModified: c.lastModified,
              ))
          .toList();

      // Persist real items and folders into SQLite database
      if (foundAudios.isNotEmpty || foundVideos.isNotEmpty) {
        await _dbService.upsertMediaItems([...foundAudios, ...foundVideos]);
        await _dbService.upsertFolders(discoveredFolders);
      }

      // Re-read fresh state from SQLite database
      _audioFiles = await _dbService.getAudioItems();
      _videoFiles = await _dbService.getVideoItems();
      _folderModels = await _dbService.getAllFolders();
      _rebuildFolderMap();
      _untaggedCount = untagged;
    } catch (e) {
      debugPrint('[StorageScanner] Scan exception: $e');
    } finally {
      _isScanning = false;
      _scanProgress = 1.0;
      notifyListeners();
    }
  }

  /// Toggles favorite status in SQLite and updates in-memory list
  Future<void> toggleFavorite(String mediaId) async {
    await _dbService.toggleFavorite(mediaId);

    _audioFiles = _audioFiles.map((m) {
      return m.id == mediaId ? m.copyWith(isFavorite: !m.isFavorite) : m;
    }).toList();

    _videoFiles = _videoFiles.map((m) {
      return m.id == mediaId ? m.copyWith(isFavorite: !m.isFavorite) : m;
    }).toList();

    _rebuildFolderMap();
    notifyListeners();
  }

  /// Rebuilds the map of folderName -> `List<MediaItemModel>`
  void _rebuildFolderMap() {
    final Map<String, List<MediaItemModel>> map = {};
    for (final item in allMedia) {
      map.putIfAbsent(item.folderName, () => []).add(item);
    }
    _folders = map;
  }

  void _recomputeUntagged() {
    int untagged = 0;
    for (final item in allMedia) {
      if (item.artist == 'Unknown Artist' || item.album == 'Unknown Album') {
        untagged++;
      }
    }
    _untaggedCount = untagged;
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
    final isHiRes = format == 'FLAC' ||
        format == 'WAV' ||
        format == 'ALAC' ||
        format == 'DSD';

    return MediaItemModel(
      id: file.path.hashCode.abs().toString(),
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
    final List<Directory> dirs = [];

    if (Platform.isAndroid) {
      // Standard Android public media directories
      dirs.addAll([
        Directory('/storage/emulated/0/Music'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Movies'),
        Directory('/storage/emulated/0/DCIM'),
        Directory('/storage/emulated/0/Audiobooks'),
        Directory('/storage/emulated/0/Podcasts'),
        Directory('/storage/emulated/0/Recordings'),
        Directory('/storage/emulated/0/Documents'),
      ]);

      // Scan top-level folders in /storage/emulated/0 to discover custom music/video directories
      final emulatedRoot = Directory('/storage/emulated/0');
      if (emulatedRoot.existsSync()) {
        try {
          for (final entity in emulatedRoot.listSync(followLinks: false)) {
            if (entity is Directory) {
              final base = p.basename(entity.path);
              if (!base.startsWith('.') &&
                  base.toLowerCase() != 'android' &&
                  !dirs.any((d) => d.path == entity.path)) {
                dirs.add(entity);
              }
            }
          }
        } catch (_) {}
      }

      // Check for removable external SD cards mounted under /storage
      final storageRoot = Directory('/storage');
      if (storageRoot.existsSync()) {
        try {
          for (final entity in storageRoot.listSync(followLinks: false)) {
            if (entity is Directory) {
              final base = p.basename(entity.path);
              if (base != 'emulated' && base != 'self' && !base.startsWith('.')) {
                dirs.add(Directory(p.join(entity.path, 'Music')));
                dirs.add(Directory(p.join(entity.path, 'Download')));
                dirs.add(Directory(p.join(entity.path, 'Movies')));
              }
            }
          }
        } catch (_) {}
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        dirs.addAll([
          Directory('$userProfile\\Music'),
          Directory('$userProfile\\Videos'),
          Directory('$userProfile\\Downloads'),
          Directory('$userProfile\\Desktop'),
        ]);
      }
    }
    return dirs;
  }
}

class _FolderCollector {
  final String path;
  final String name;
  int audioCount = 0;
  int videoCount = 0;
  int totalSizeBytes = 0;
  DateTime lastModified = DateTime.fromMillisecondsSinceEpoch(0);

  _FolderCollector({required this.path, required this.name});
}

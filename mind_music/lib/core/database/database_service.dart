import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/media_folder_model.dart';
import '../models/media_item_model.dart';
import '../models/playlist_model.dart';

class DatabaseService with ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  bool _dbInitAttempted = false;

  // In-memory cache synchronized with SQLite for zero-latency UI & headless testing
  final Map<String, MediaItemModel> _mediaMap = {};
  final Map<String, MediaFolderModel> _folderMap = {};
  final Map<String, PlaylistModel> _playlistMap = {};

  /// Allows injecting an in-memory database or test database for headless verification
  @visibleForTesting
  Future<void> setTestDatabase(Database db) async {
    _db = db;
    await _createTables(db, 1);
  }

  Future<Database?> get database async {
    if (_db != null && _db!.isOpen) return _db;
    if (!_dbInitAttempted) {
      _dbInitAttempted = true;
      _db = await _initDatabase();
    }
    return _db;
  }

  Future<Database?> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'mind_music_library.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      // In headless test environments where native SQLite channel isn't registered,
      // fallback smoothly to in-memory store without failing or setting pending timers.
      debugPrint('[DatabaseService] Native SQLite initialization notice: $e');
      return null;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // 1. Media items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS media_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL,
        duration_ms INTEGER NOT NULL,
        file_path TEXT UNIQUE NOT NULL,
        format TEXT NOT NULL,
        is_video INTEGER NOT NULL DEFAULT 0,
        is_hi_res INTEGER NOT NULL DEFAULT 0,
        size_in_bytes INTEGER NOT NULL DEFAULT 0,
        date_modified INTEGER NOT NULL,
        folder_name TEXT NOT NULL,
        artwork_uri TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        play_count INTEGER NOT NULL DEFAULT 0,
        last_played INTEGER
      )
    ''');

    // Indexes for high performance instant library search
    await db.execute('CREATE INDEX IF NOT EXISTS idx_media_type ON media_items (is_video)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_media_folder ON media_items (folder_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_media_favorite ON media_items (is_favorite)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_media_last_played ON media_items (last_played)');

    // 2. Physical Folders Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS media_folders (
        path TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        audio_count INTEGER NOT NULL DEFAULT 0,
        video_count INTEGER NOT NULL DEFAULT 0,
        total_size_bytes INTEGER NOT NULL DEFAULT 0,
        last_modified INTEGER NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. Playlists Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        is_ai_generated INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        bpm_range TEXT,
        tags TEXT,
        created_at INTEGER NOT NULL,
        cover_gradient_index INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 4. Playlist Tracks Junction Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_tracks (
        playlist_id TEXT NOT NULL,
        media_id TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, media_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (media_id) REFERENCES media_items (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Media Items CRUD ---

  Future<void> upsertMediaItems(List<MediaItemModel> items) async {
    for (final item in items) {
      _mediaMap[item.id] = item;
    }

    final db = await database;
    if (db != null) {
      final batch = db.batch();
      for (final item in items) {
        batch.insert(
          'media_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
    notifyListeners();
  }

  Future<List<MediaItemModel>> getAllMedia() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('media_items', orderBy: 'title ASC');
      final items = maps.map((m) => MediaItemModel.fromMap(m)).toList();
      for (final i in items) {
        _mediaMap[i.id] = i;
      }
      return items;
    }
    final list = _mediaMap.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<List<MediaItemModel>> getAudioItems() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'media_items',
        where: 'is_video = ?',
        whereArgs: [0],
        orderBy: 'title ASC',
      );
      final items = maps.map((m) => MediaItemModel.fromMap(m)).toList();
      for (final i in items) {
        _mediaMap[i.id] = i;
      }
      return items;
    }
    final list = _mediaMap.values.where((m) => !m.isVideo).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<List<MediaItemModel>> getVideoItems() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'media_items',
        where: 'is_video = ?',
        whereArgs: [1],
        orderBy: 'title ASC',
      );
      final items = maps.map((m) => MediaItemModel.fromMap(m)).toList();
      for (final i in items) {
        _mediaMap[i.id] = i;
      }
      return items;
    }
    final list = _mediaMap.values.where((m) => m.isVideo).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<List<MediaItemModel>> getFavoriteItems() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'media_items',
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'title ASC',
      );
      final items = maps.map((m) => MediaItemModel.fromMap(m)).toList();
      for (final i in items) {
        _mediaMap[i.id] = i;
      }
      return items;
    }
    final list = _mediaMap.values.where((m) => m.isFavorite).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<List<MediaItemModel>> getRecentlyPlayed({int limit = 10}) async {
    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'media_items',
        where: 'last_played IS NOT NULL',
        orderBy: 'last_played DESC',
        limit: limit,
      );
      return maps.map((m) => MediaItemModel.fromMap(m)).toList();
    }
    final list = _mediaMap.values.where((m) => m.lastPlayed != null).toList()
      ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
    return list.take(limit).toList();
  }

  Future<List<MediaItemModel>> getMediaByFolder(String folderName) async {
    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'media_items',
        where: 'folder_name = ?',
        whereArgs: [folderName],
        orderBy: 'title ASC',
      );
      return maps.map((m) => MediaItemModel.fromMap(m)).toList();
    }
    final list = _mediaMap.values.where((m) => m.folderName == folderName).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<List<MediaItemModel>> searchMedia(String query) async {
    final sanitized = '%${query.trim().replaceAll("'", "''")}%';
    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'media_items',
        where: 'title LIKE ? OR artist LIKE ? OR album LIKE ? OR folder_name LIKE ?',
        whereArgs: [sanitized, sanitized, sanitized, sanitized],
        orderBy: 'title ASC',
      );
      return maps.map((m) => MediaItemModel.fromMap(m)).toList();
    }
    final q = query.toLowerCase();
    final list = _mediaMap.values.where((m) {
      return m.title.toLowerCase().contains(q) ||
          m.artist.toLowerCase().contains(q) ||
          m.album.toLowerCase().contains(q) ||
          m.folderName.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<void> toggleFavorite(String mediaId) async {
    if (_mediaMap.containsKey(mediaId)) {
      final current = _mediaMap[mediaId]!;
      _mediaMap[mediaId] = current.copyWith(isFavorite: !current.isFavorite);
    }

    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'media_items',
        columns: ['is_favorite'],
        where: 'id = ?',
        whereArgs: [mediaId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        final current = (maps.first['is_favorite'] as int?) == 1;
        await db.update(
          'media_items',
          {'is_favorite': current ? 0 : 1},
          where: 'id = ?',
          whereArgs: [mediaId],
        );
      }
    }
    notifyListeners();
  }

  Future<void> recordMediaPlay(String mediaId) async {
    if (_mediaMap.containsKey(mediaId)) {
      final current = _mediaMap[mediaId]!;
      _mediaMap[mediaId] = current.copyWith(
        playCount: current.playCount + 1,
        lastPlayed: DateTime.now(),
      );
    }

    final db = await database;
    if (db != null) {
      await db.rawUpdate('''
        UPDATE media_items 
        SET play_count = play_count + 1, last_played = ?
        WHERE id = ?
      ''', [DateTime.now().millisecondsSinceEpoch, mediaId]);
    }
    notifyListeners();
  }

  // --- Folders CRUD ---

  Future<void> upsertFolders(List<MediaFolderModel> folders) async {
    for (final folder in folders) {
      _folderMap[folder.name] = folder;
    }

    final db = await database;
    if (db != null) {
      final batch = db.batch();
      for (final folder in folders) {
        batch.insert(
          'media_folders',
          folder.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
    notifyListeners();
  }

  Future<List<MediaFolderModel>> getAllFolders() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query('media_folders', orderBy: 'name ASC');
      final list = maps.map((m) => MediaFolderModel.fromMap(m)).toList();
      for (final f in list) {
        _folderMap[f.name] = f;
      }
      return list;
    }
    final list = _folderMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  // --- Playlists CRUD ---

  Future<void> upsertPlaylist(PlaylistModel playlist) async {
    _playlistMap[playlist.id] = playlist;

    final db = await database;
    if (db != null) {
      await db.transaction((txn) async {
        await txn.insert(
          'playlists',
          {
            'id': playlist.id,
            'name': playlist.name,
            'description': playlist.description,
            'is_ai_generated': playlist.isAiGenerated ? 1 : 0,
            'is_favorite': playlist.isFavorite ? 1 : 0,
            'bpm_range': playlist.bpmRange,
            'tags': playlist.tags.join(','),
            'created_at': playlist.createdAt.millisecondsSinceEpoch,
            'cover_gradient_index': playlist.coverGradientIndex,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Re-insert track junction records
        await txn.delete(
          'playlist_tracks',
          where: 'playlist_id = ?',
          whereArgs: [playlist.id],
        );

        final batch = txn.batch();
        for (int i = 0; i < playlist.tracks.length; i++) {
          batch.insert(
            'playlist_tracks',
            {
              'playlist_id': playlist.id,
              'media_id': playlist.tracks[i].id,
              'order_index': i,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    }
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlistMap.remove(playlistId);

    final db = await database;
    if (db != null) {
      await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
    }
    notifyListeners();
  }

  Future<List<PlaylistModel>> getAllPlaylists() async {
    final db = await database;
    if (db != null) {
      final playlistMaps = await db.query('playlists', orderBy: 'created_at DESC');
      final List<PlaylistModel> results = [];

      for (final map in playlistMaps) {
        final playlistId = map['id'] as String;
        final trackMaps = await db.rawQuery('''
          SELECT m.* FROM media_items m
          INNER JOIN playlist_tracks pt ON m.id = pt.media_id
          WHERE pt.playlist_id = ?
          ORDER BY pt.order_index ASC
        ''', [playlistId]);

        final tracks = trackMaps.map((tm) => MediaItemModel.fromMap(tm)).toList();
        final tagsStr = map['tags'] as String?;
        final tags = (tagsStr != null && tagsStr.isNotEmpty) ? tagsStr.split(',') : <String>[];

        results.add(
          PlaylistModel(
            id: playlistId,
            name: map['name'] as String,
            description: (map['description'] as String?) ?? '',
            tracks: tracks,
            isAiGenerated: (map['is_ai_generated'] as int?) == 1,
            isFavorite: (map['is_favorite'] as int?) == 1,
            bpmRange: map['bpm_range'] as String?,
            tags: tags,
            createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
            coverGradientIndex: (map['cover_gradient_index'] as int?) ?? 0,
          ),
        );
      }

      for (final p in results) {
        _playlistMap[p.id] = p;
      }
      return results;
    }

    final list = _playlistMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // --- Library Statistics ---

  Future<Map<String, int>> getLibraryStats() async {
    final db = await database;
    if (db != null) {
      final musicCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM media_items WHERE is_video = 0'),
      ) ?? 0;
      final videoCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM media_items WHERE is_video = 1'),
      ) ?? 0;
      final foldersCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM media_folders'),
      ) ?? 0;
      final playlistsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM playlists'),
      ) ?? 0;

      return {
        'musicCount': musicCount,
        'videoCount': videoCount,
        'foldersCount': foldersCount,
        'playlistsCount': playlistsCount,
      };
    }

    final musicCount = _mediaMap.values.where((m) => !m.isVideo).length;
    final videoCount = _mediaMap.values.where((m) => m.isVideo).length;
    return {
      'musicCount': musicCount,
      'videoCount': videoCount,
      'foldersCount': _folderMap.length,
      'playlistsCount': _playlistMap.length,
    };
  }

  Future<void> clearAll() async {
    _mediaMap.clear();
    _folderMap.clear();
    _playlistMap.clear();

    final db = await database;
    if (db != null) {
      await db.delete('playlist_tracks');
      await db.delete('playlists');
      await db.delete('media_folders');
      await db.delete('media_items');
    }
    notifyListeners();
  }
}

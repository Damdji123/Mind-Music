class MediaItemModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String filePath;
  final String format; // FLAC, MP3, WAV, AAC, MP4, MKV
  final bool isVideo;
  final bool isHiRes;
  final int sizeInBytes;
  final DateTime dateModified;
  final String folderName;
  final String? artworkUri;
  final bool isFavorite;
  final int playCount;
  final DateTime? lastPlayed;

  const MediaItemModel({
    required this.id,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.duration = Duration.zero,
    required this.filePath,
    required this.format,
    this.isVideo = false,
    this.isHiRes = false,
    this.sizeInBytes = 0,
    required this.dateModified,
    required this.folderName,
    this.artworkUri,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayed,
  });

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  MediaItemModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? filePath,
    String? format,
    bool? isVideo,
    bool? isHiRes,
    int? sizeInBytes,
    DateTime? dateModified,
    String? folderName,
    String? artworkUri,
    bool? isFavorite,
    int? playCount,
    DateTime? lastPlayed,
  }) {
    return MediaItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      isVideo: isVideo ?? this.isVideo,
      isHiRes: isHiRes ?? this.isHiRes,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      dateModified: dateModified ?? this.dateModified,
      folderName: folderName ?? this.folderName,
      artworkUri: artworkUri ?? this.artworkUri,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration_ms': duration.inMilliseconds,
      'file_path': filePath,
      'format': format,
      'is_video': isVideo ? 1 : 0,
      'is_hi_res': isHiRes ? 1 : 0,
      'size_in_bytes': sizeInBytes,
      'date_modified': dateModified.millisecondsSinceEpoch,
      'folder_name': folderName,
      'artwork_uri': artworkUri,
      'is_favorite': isFavorite ? 1 : 0,
      'play_count': playCount,
      'last_played': lastPlayed?.millisecondsSinceEpoch,
    };
  }

  factory MediaItemModel.fromMap(Map<String, dynamic> map) {
    return MediaItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: (map['artist'] as String?) ?? 'Unknown Artist',
      album: (map['album'] as String?) ?? 'Unknown Album',
      duration: Duration(milliseconds: (map['duration_ms'] as int?) ?? 0),
      filePath: map['file_path'] as String,
      format: (map['format'] as String?) ?? 'MP3',
      isVideo: (map['is_video'] as int?) == 1,
      isHiRes: (map['is_hi_res'] as int?) == 1,
      sizeInBytes: (map['size_in_bytes'] as int?) ?? 0,
      dateModified: DateTime.fromMillisecondsSinceEpoch(
        (map['date_modified'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      folderName: (map['folder_name'] as String?) ?? 'Music',
      artworkUri: map['artwork_uri'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      playCount: (map['play_count'] as int?) ?? 0,
      lastPlayed: map['last_played'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played'] as int)
          : null,
    );
  }
}

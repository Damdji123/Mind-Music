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
    );
  }
}

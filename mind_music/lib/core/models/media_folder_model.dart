class MediaFolderModel {
  final String path;
  final String name;
  final int audioCount;
  final int videoCount;
  final int totalSizeBytes;
  final DateTime lastModified;
  final bool isFavorite;

  const MediaFolderModel({
    required this.path,
    required this.name,
    this.audioCount = 0,
    this.videoCount = 0,
    this.totalSizeBytes = 0,
    required this.lastModified,
    this.isFavorite = false,
  });

  int get totalItemCount => audioCount + videoCount;

  String get formattedSize {
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  MediaFolderModel copyWith({
    String? path,
    String? name,
    int? audioCount,
    int? videoCount,
    int? totalSizeBytes,
    DateTime? lastModified,
    bool? isFavorite,
  }) {
    return MediaFolderModel(
      path: path ?? this.path,
      name: name ?? this.name,
      audioCount: audioCount ?? this.audioCount,
      videoCount: videoCount ?? this.videoCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      lastModified: lastModified ?? this.lastModified,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'audio_count': audioCount,
      'video_count': videoCount,
      'total_size_bytes': totalSizeBytes,
      'last_modified': lastModified.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory MediaFolderModel.fromMap(Map<String, dynamic> map) {
    return MediaFolderModel(
      path: map['path'] as String,
      name: map['name'] as String,
      audioCount: (map['audio_count'] as int?) ?? 0,
      videoCount: (map['video_count'] as int?) ?? 0,
      totalSizeBytes: (map['total_size_bytes'] as int?) ?? 0,
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        (map['last_modified'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }
}

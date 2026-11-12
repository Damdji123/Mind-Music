import 'media_item_model.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final List<MediaItemModel> tracks;
  final bool isAiGenerated;
  final bool isFavorite;
  final String? bpmRange;
  final List<String> tags;
  final DateTime createdAt;
  final int coverGradientIndex;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description = '',
    this.tracks = const [],
    this.isAiGenerated = false,
    this.isFavorite = false,
    this.bpmRange,
    this.tags = const [],
    required this.createdAt,
    this.coverGradientIndex = 0,
  });

  int get trackCount => tracks.length;

  Duration get totalDuration {
    return tracks.fold(Duration.zero, (prev, element) => prev + element.duration);
  }

  String get formattedDuration {
    final dur = totalDuration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${dur.inMinutes}m';
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<MediaItemModel>? tracks,
    bool? isAiGenerated,
    bool? isFavorite,
    String? bpmRange,
    List<String>? tags,
    DateTime? createdAt,
    int? coverGradientIndex,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tracks: tracks ?? this.tracks,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isFavorite: isFavorite ?? this.isFavorite,
      bpmRange: bpmRange ?? this.bpmRange,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      coverGradientIndex: coverGradientIndex ?? this.coverGradientIndex,
    );
  }
}

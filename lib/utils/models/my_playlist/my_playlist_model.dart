import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_playlist_model.freezed.dart';
part 'my_playlist_model.g.dart';

/// Converter for handling Duration in JSON (seconds stored in DB/JSON)
class DurationSecondsConverter implements JsonConverter<Duration?, int?> {
  const DurationSecondsConverter();

  @override
  Duration? fromJson(int? json) =>
      json == null ? null : Duration(seconds: json);

  @override
  int? toJson(Duration? object) => object?.inSeconds;
}

@freezed
abstract class MyPlaylist with _$MyPlaylist {
  const factory MyPlaylist({
    required String id,
    required String name,
    required String description,
    required List<String> songIds,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    String? coverImage,
    bool? isPublic,
    String? createdBy,
    int? playCount,
    @DurationSecondsConverter()
    Duration? totalDuration, // changed from int? → Duration?
  }) = _MyPlaylist;

  factory MyPlaylist.fromJson(Map<String, dynamic> json) =>
      _$MyPlaylistFromJson(json);
}

extension PlaylistExtension on MyPlaylist {
  bool get isEmpty => songIds.isEmpty;
  bool get isNotEmpty => songIds.isNotEmpty;

  int get songCount => songIds.length; // computed dynamically

  String get formattedSongCount {
    if (songCount == 1) return '1 song';
    return '$songCount songs';
  }

  String get formattedDuration {
    if (totalDuration == null || totalDuration == Duration.zero) return '';
    final hours = totalDuration!.inHours;
    final minutes = totalDuration!.inMinutes % 60;
    final seconds = totalDuration!.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  MyPlaylist copyWithSongIds(List<String> newSongIds) {
    return copyWith(songIds: newSongIds, updatedAt: DateTime.now());
  }

  MyPlaylist addSong(String songId) {
    if (!songIds.contains(songId)) {
      return copyWith(songIds: [...songIds, songId], updatedAt: DateTime.now());
    }
    return this;
  }

  MyPlaylist removeSong(String songId) {
    if (songIds.contains(songId)) {
      return copyWith(
        songIds: songIds.where((id) => id != songId).toList(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }
}

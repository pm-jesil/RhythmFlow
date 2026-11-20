import 'package:freezed_annotation/freezed_annotation.dart';

part 'album_model.freezed.dart';
part 'album_model.g.dart';

@freezed
class Album with _$Album {
  const factory Album({
    required String id,
    required String name,
    String? description,
    required List<String> songIds, // normalized
    String? coverImage,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    String? artistId, // link to Artist
    String? genre,
    int? year,
    int? playCount,
    // Online (Jamendo) albums; null for local albums.
    String? source,
    String? remoteId,
    String? artistName,
    String? shareUrl,
  }) = _Album;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
}

extension AlbumExtension on Album {
  bool get isEmpty => songIds.isEmpty;
  bool get isNotEmpty => songIds.isNotEmpty;
  int get songCount => songIds.length;

  String get formattedSongCount =>
      songCount == 1 ? '1 song' : '$songCount songs';
}

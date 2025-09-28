import 'package:freezed_annotation/freezed_annotation.dart';

part 'artist_model.freezed.dart';
part 'artist_model.g.dart';

@freezed
class Artist with _$Artist {
  const factory Artist({
    required String id,
    required String name,
    String? bio,
    String? image,
    required List<String> songIds,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    int? playCount,
  }) = _Artist;

  factory Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);
}

extension ArtistExtension on Artist {
  bool get isEmpty => songIds.isEmpty;
  bool get isNotEmpty => songIds.isNotEmpty;
  int get songCount => songIds.length;

  String get formattedSongCount =>
      songCount == 1 ? '1 song' : '$songCount songs';
}

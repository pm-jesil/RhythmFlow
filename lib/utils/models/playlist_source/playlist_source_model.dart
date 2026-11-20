import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist_source_model.freezed.dart';
part 'playlist_source_model.g.dart';

@freezed
class PlaylistSource with _$PlaylistSource {
  const factory PlaylistSource({
    required String source,
    String? albumId,
    String? artistId,
    String? playlistId,
  }) = _PlaylistSource;

  factory PlaylistSource.fromJson(Map<String, dynamic> json) =>
      _$PlaylistSourceFromJson(json);

  // Factory constructors for common sources
  factory PlaylistSource.allSongs() => const PlaylistSource(
        source: 'allSongs',
      );

  factory PlaylistSource.album(String albumId) => PlaylistSource(
        source: 'album',
        albumId: albumId,
      );

  factory PlaylistSource.artist(String artistId) => PlaylistSource(
        source: 'artist',
        artistId: artistId,
      );

  factory PlaylistSource.myPlaylist(String playlistId) => PlaylistSource(
        source: 'my_playlist',
        playlistId: playlistId,
      );

  /// A Discover list registered in `OnlineQueues` under [queueKey].
  factory PlaylistSource.online(String queueKey) => PlaylistSource(
        source: 'online',
        playlistId: queueKey,
      );
}

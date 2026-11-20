part of 'online_library_bloc.dart';

enum DownloadPhase { queued, downloading, completed, failed }

/// State of one song download.
class OnlineDownload {
  final DownloadPhase phase;
  final double progress; // 0..1
  final String? localPath;
  final String? error;
  final Song? song;

  const OnlineDownload({
    required this.phase,
    this.progress = 0,
    this.localPath,
    this.error,
    this.song,
  });

  bool get isActive =>
      phase == DownloadPhase.queued || phase == DownloadPhase.downloading;

  Map<String, dynamic> toJson() => {
    'phase': phase.name,
    'progress': progress,
    'localPath': localPath,
    'error': error,
    'song': song?.toJson(),
  };

  factory OnlineDownload.fromJson(Map<String, dynamic> json) {
    var phase = DownloadPhase.values.firstWhere(
      (p) => p.name == json['phase'],
      orElse: () => DownloadPhase.failed,
    );
    // A download cannot survive an app restart.
    final interrupted =
        phase == DownloadPhase.queued || phase == DownloadPhase.downloading;
    if (interrupted) phase = DownloadPhase.failed;
    return OnlineDownload(
      phase: phase,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      localPath: json['localPath'] as String?,
      error: interrupted ? 'Interrupted' : json['error'] as String?,
      song: json['song'] == null
          ? null
          : Song.fromJson(Map<String, dynamic>.from(json['song'] as Map)),
    );
  }
}

@freezed
abstract class OnlineLibraryState with _$OnlineLibraryState {
  const OnlineLibraryState._();

  const factory OnlineLibraryState({
    @Default(<Song>[]) List<Song> likedSongs,
    @Default(<Song>[]) List<Song> recentlyPlayed,
    @Default(<Artist>[]) List<Artist> followedArtists,
    @Default(<Album>[]) List<Album> savedAlbums,
    @Default(<String, OnlineDownload>{}) Map<String, OnlineDownload> downloads,
  }) = _OnlineLibraryState;

  bool isLiked(String songId) => likedSongs.any((s) => s.id == songId);
  bool isFollowing(String artistId) => followedArtists.any((a) => a.id == artistId);
  bool isSaved(String albumId) => savedAlbums.any((a) => a.id == albumId);
  OnlineDownload? downloadOf(String songId) => downloads[songId];
}

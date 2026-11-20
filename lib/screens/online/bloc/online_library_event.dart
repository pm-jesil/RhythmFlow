part of 'online_library_bloc.dart';

@freezed
abstract class OnlineLibraryEvent with _$OnlineLibraryEvent {
  const factory OnlineLibraryEvent.toggleLike(Song song) = _ToggleLike;

  /// An online song started playing (most recent first, de-duplicated).
  const factory OnlineLibraryEvent.recordPlay(Song song) = _RecordPlay;

  const factory OnlineLibraryEvent.clearHistory() = _ClearHistory;

  const factory OnlineLibraryEvent.toggleFollowArtist(Artist artist) =
      _ToggleFollowArtist;

  const factory OnlineLibraryEvent.toggleSaveAlbum(Album album) =
      _ToggleSaveAlbum;

  /// Download progress reported by the download service.
  const factory OnlineLibraryEvent.downloadUpdated({
    required String songId,
    required OnlineDownload download,
  }) = _DownloadUpdated;

  const factory OnlineLibraryEvent.downloadDismissed(String songId) =
      _DownloadDismissed;
}

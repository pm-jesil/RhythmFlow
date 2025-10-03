part of 'music_bloc.dart';

@freezed
abstract class MusicEvent with _$MusicEvent {
  // Load events
  const factory MusicEvent.fetchAndUpdateSongs({bool? isForce}) = _FetchAndUpdateSongs;
  
  // Unified metadata update event (replaces separate album/artist events)
  const factory MusicEvent.fetchAndUpdateMetadata({
    bool? includeAlbums,
    bool? includeArtists,
    bool? isProgressive,
  }) = _FetchAndUpdateMetadata;

  const factory MusicEvent.loadMyPlaylists() = _LoadMyPlaylists;

  // Playlist management events
  const factory MusicEvent.addOrUpdateMyPlayList({
    required MyPlaylistOperation operation,
    String? playlistId,
    String? name,
    String? description,
    List<String>? songIds,
    String? songId,
    String? coverImage,
    bool? isPublic,
  }) = _AddOrUpdateMyPlayList;

  // Playback events
  const factory MusicEvent.playOrPauseSong({
    String? songId,
    List<String>? currentPlayList,
    bool? isForceStop,
    PlaylistSource? playlistSource,
  }) = _PlayOrPauseSong;

  const factory MusicEvent.playNext() = _PlayNext;
  const factory MusicEvent.playPrevious() = _PlayPrevious;

  const factory MusicEvent.toggleShuffle({
    required bool isShuffle,
    bool? isAutoStart,
    required List<String> currentPlayList,
    PlaylistSource? playlistSource,
  }) = _ToggleShuffle;

  const factory MusicEvent.toggleRepeat() = _ToggleRepeat;

  // Sorting event
  const factory MusicEvent.changeSortingOrder({
    required int sortingIndex,
    required List<String> sortingList,
    PlaylistSource? playlistSource,
  }) = _ChangeSortingOrder;

  // Filter event
  const factory MusicEvent.updateFilterKeyword({
    required String filterKeyword,
  }) = _UpdateFilterKeyword;

  // Navigation filter event
  const factory MusicEvent.setNavigationFilter({
    required String filterType,
    String? filterValue,
  }) = _SetNavigationFilter;

  // Seek event
  const factory MusicEvent.seekToPosition({required Duration position}) =
      _SeekToPosition;

  // Position update event
  const factory MusicEvent.updateLastPosition({required Duration position}) =
      _UpdateLastPosition;

  // State update event
  const factory MusicEvent.updateMusicBlocState({
    required MusicState newState,
  }) = _UpdateMusicBlocState;
}

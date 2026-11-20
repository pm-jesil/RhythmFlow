part of 'music_bloc.dart';

@freezed
abstract class MusicEvent with _$MusicEvent {
  // Load events
  const factory MusicEvent.fetchAndUpdateSongs({bool? isForce}) =
      _FetchAndUpdateSongs;

  // Unified metadata update event (replaces separate album/artist events)
  const factory MusicEvent.fetchAndUpdateMetadata({
    bool? includeAlbums,
    bool? includeArtists,
    bool? isProgressive,
  }) = _FetchAndUpdateMetadata;

  const factory MusicEvent.loadMyPlaylists() = _LoadMyPlaylists;

  // Remove songs from the library (e.g. after the file was deleted) and
  // clean every reference (albums, artists, playlists, queue).
  const factory MusicEvent.removeSongs({required List<String> songIds}) =
      _RemoveSongs;

  // Store the real duration of a song whose duration could not be read from
  // its tags (learned from the player when the song is first played).
  const factory MusicEvent.updateSongDuration({
    required String songId,
    required Duration duration,
  }) = _UpdateSongDuration;

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


  // Comprehensive features extraction event
  const factory MusicEvent.extractComprehensiveFeatures({bool? isForce}) = _ExtractComprehensiveFeatures;

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

  // AI Shuffle event - intelligently reorder playlist based on current song features
  const factory MusicEvent.aiShuffle({
    required String currentSongId,
    required List<String> currentPlayList,
    PlaylistSource? playlistSource,
  }) = _AiShuffle;

  // State update event
  const factory MusicEvent.updateMusicBlocState({
    required MusicState newState,
  }) = _UpdateMusicBlocState;
}

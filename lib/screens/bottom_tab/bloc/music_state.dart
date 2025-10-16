part of 'music_bloc.dart';

@freezed
abstract class MusicState with _$MusicState {
  const factory MusicState({
    // Player state with current playlist, completed songs, and playlist reference
    required MyPlayerStateModel myPlayerState,

    // Core data
    required List<Song> allSongs,
    required List<Album> albumList,
    required List<Artist> artistList,
    required List<MyPlaylist> myPlaylist,

    // Sorting state
    required int sortingIndex,

    // Navigation filter state
    @Default('') String navigationFilterType,
    @Default('') String navigationFilterValue,

    // Loading states
    required bool isSongListLoading,
    required bool isAlbumListLoading,
    required bool isArtistListLoading,
    required bool isComprehensiveFeaturesExtractingLoading,

    // Progress tracking
    @Default(0) int songLoadingProgress,

    // Error states
    required bool isSongListError,
    required bool isAlbumListError,
    required bool isArtistListError,
    required bool isComprehensiveFeaturesExtractingError,

    // General loading and error states (for backward compatibility)
    required bool isLoading,
    required bool isError,

    // Horizontal scrolling widget home index
    @Default(0) int horizondalScrollingWidgetHomeIndex,

    // App settings fetch song flag
    @Default(false) bool appSettingsFetchSong,
  }) = _Initial;

  factory MusicState.initial() => const MusicState(
    // Player state
    myPlayerState: MyPlayerStateModel(
      completedSongs: [],
      currentPlayList: [],
      currentSongId: null,
      repeatModeIndex: 0,
      playlistId: null,
      previousSongId: null,
      isPlaying: false,
      isShuffle: false,
    ),

    // Core data
    allSongs: [],
    albumList: [],
    artistList: [],
    myPlaylist: [],

    // Sorting state (0 = Newest First)
    sortingIndex: 0,

    // Loading states
    isSongListLoading: false,
    isAlbumListLoading: false,
    isArtistListLoading: false,
    isComprehensiveFeaturesExtractingLoading: false,

    // Error states
    isSongListError: false,
    isAlbumListError: false,
    isArtistListError: false,
    isComprehensiveFeaturesExtractingError: false,

    // General loading and error states (for backward compatibility)
    isLoading: false,
    isError: false,
  );
}

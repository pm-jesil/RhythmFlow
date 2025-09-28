// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MusicEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicEventCopyWith<$Res> {
  factory $MusicEventCopyWith(
    MusicEvent value,
    $Res Function(MusicEvent) then,
  ) = _$MusicEventCopyWithImpl<$Res, MusicEvent>;
}

/// @nodoc
class _$MusicEventCopyWithImpl<$Res, $Val extends MusicEvent>
    implements $MusicEventCopyWith<$Res> {
  _$MusicEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadAllSongsImplCopyWith<$Res> {
  factory _$$LoadAllSongsImplCopyWith(
    _$LoadAllSongsImpl value,
    $Res Function(_$LoadAllSongsImpl) then,
  ) = __$$LoadAllSongsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadAllSongsImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$LoadAllSongsImpl>
    implements _$$LoadAllSongsImplCopyWith<$Res> {
  __$$LoadAllSongsImplCopyWithImpl(
    _$LoadAllSongsImpl _value,
    $Res Function(_$LoadAllSongsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadAllSongsImpl implements _LoadAllSongs {
  const _$LoadAllSongsImpl();

  @override
  String toString() {
    return 'MusicEvent.loadAllSongs()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadAllSongsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return loadAllSongs();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return loadAllSongs?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAllSongs != null) {
      return loadAllSongs();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return loadAllSongs(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return loadAllSongs?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAllSongs != null) {
      return loadAllSongs(this);
    }
    return orElse();
  }
}

abstract class _LoadAllSongs implements MusicEvent {
  const factory _LoadAllSongs() = _$LoadAllSongsImpl;
}

/// @nodoc
abstract class _$$LoadAllSongsProgressiveImplCopyWith<$Res> {
  factory _$$LoadAllSongsProgressiveImplCopyWith(
    _$LoadAllSongsProgressiveImpl value,
    $Res Function(_$LoadAllSongsProgressiveImpl) then,
  ) = __$$LoadAllSongsProgressiveImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadAllSongsProgressiveImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$LoadAllSongsProgressiveImpl>
    implements _$$LoadAllSongsProgressiveImplCopyWith<$Res> {
  __$$LoadAllSongsProgressiveImplCopyWithImpl(
    _$LoadAllSongsProgressiveImpl _value,
    $Res Function(_$LoadAllSongsProgressiveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadAllSongsProgressiveImpl implements _LoadAllSongsProgressive {
  const _$LoadAllSongsProgressiveImpl();

  @override
  String toString() {
    return 'MusicEvent.loadAllSongsProgressive()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadAllSongsProgressiveImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return loadAllSongsProgressive();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return loadAllSongsProgressive?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAllSongsProgressive != null) {
      return loadAllSongsProgressive();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return loadAllSongsProgressive(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return loadAllSongsProgressive?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAllSongsProgressive != null) {
      return loadAllSongsProgressive(this);
    }
    return orElse();
  }
}

abstract class _LoadAllSongsProgressive implements MusicEvent {
  const factory _LoadAllSongsProgressive() = _$LoadAllSongsProgressiveImpl;
}

/// @nodoc
abstract class _$$LoadAlbumsImplCopyWith<$Res> {
  factory _$$LoadAlbumsImplCopyWith(
    _$LoadAlbumsImpl value,
    $Res Function(_$LoadAlbumsImpl) then,
  ) = __$$LoadAlbumsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadAlbumsImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$LoadAlbumsImpl>
    implements _$$LoadAlbumsImplCopyWith<$Res> {
  __$$LoadAlbumsImplCopyWithImpl(
    _$LoadAlbumsImpl _value,
    $Res Function(_$LoadAlbumsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadAlbumsImpl implements _LoadAlbums {
  const _$LoadAlbumsImpl();

  @override
  String toString() {
    return 'MusicEvent.loadAlbums()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadAlbumsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return loadAlbums();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return loadAlbums?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAlbums != null) {
      return loadAlbums();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return loadAlbums(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return loadAlbums?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAlbums != null) {
      return loadAlbums(this);
    }
    return orElse();
  }
}

abstract class _LoadAlbums implements MusicEvent {
  const factory _LoadAlbums() = _$LoadAlbumsImpl;
}

/// @nodoc
abstract class _$$LoadAlbumsProgressiveImplCopyWith<$Res> {
  factory _$$LoadAlbumsProgressiveImplCopyWith(
    _$LoadAlbumsProgressiveImpl value,
    $Res Function(_$LoadAlbumsProgressiveImpl) then,
  ) = __$$LoadAlbumsProgressiveImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadAlbumsProgressiveImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$LoadAlbumsProgressiveImpl>
    implements _$$LoadAlbumsProgressiveImplCopyWith<$Res> {
  __$$LoadAlbumsProgressiveImplCopyWithImpl(
    _$LoadAlbumsProgressiveImpl _value,
    $Res Function(_$LoadAlbumsProgressiveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadAlbumsProgressiveImpl implements _LoadAlbumsProgressive {
  const _$LoadAlbumsProgressiveImpl();

  @override
  String toString() {
    return 'MusicEvent.loadAlbumsProgressive()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadAlbumsProgressiveImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return loadAlbumsProgressive();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return loadAlbumsProgressive?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAlbumsProgressive != null) {
      return loadAlbumsProgressive();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return loadAlbumsProgressive(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return loadAlbumsProgressive?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadAlbumsProgressive != null) {
      return loadAlbumsProgressive(this);
    }
    return orElse();
  }
}

abstract class _LoadAlbumsProgressive implements MusicEvent {
  const factory _LoadAlbumsProgressive() = _$LoadAlbumsProgressiveImpl;
}

/// @nodoc
abstract class _$$LoadArtistsImplCopyWith<$Res> {
  factory _$$LoadArtistsImplCopyWith(
    _$LoadArtistsImpl value,
    $Res Function(_$LoadArtistsImpl) then,
  ) = __$$LoadArtistsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadArtistsImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$LoadArtistsImpl>
    implements _$$LoadArtistsImplCopyWith<$Res> {
  __$$LoadArtistsImplCopyWithImpl(
    _$LoadArtistsImpl _value,
    $Res Function(_$LoadArtistsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadArtistsImpl implements _LoadArtists {
  const _$LoadArtistsImpl();

  @override
  String toString() {
    return 'MusicEvent.loadArtists()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadArtistsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return loadArtists();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return loadArtists?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadArtists != null) {
      return loadArtists();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return loadArtists(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return loadArtists?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadArtists != null) {
      return loadArtists(this);
    }
    return orElse();
  }
}

abstract class _LoadArtists implements MusicEvent {
  const factory _LoadArtists() = _$LoadArtistsImpl;
}

/// @nodoc
abstract class _$$LoadArtistsProgressiveImplCopyWith<$Res> {
  factory _$$LoadArtistsProgressiveImplCopyWith(
    _$LoadArtistsProgressiveImpl value,
    $Res Function(_$LoadArtistsProgressiveImpl) then,
  ) = __$$LoadArtistsProgressiveImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadArtistsProgressiveImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$LoadArtistsProgressiveImpl>
    implements _$$LoadArtistsProgressiveImplCopyWith<$Res> {
  __$$LoadArtistsProgressiveImplCopyWithImpl(
    _$LoadArtistsProgressiveImpl _value,
    $Res Function(_$LoadArtistsProgressiveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadArtistsProgressiveImpl implements _LoadArtistsProgressive {
  const _$LoadArtistsProgressiveImpl();

  @override
  String toString() {
    return 'MusicEvent.loadArtistsProgressive()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadArtistsProgressiveImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return loadArtistsProgressive();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return loadArtistsProgressive?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadArtistsProgressive != null) {
      return loadArtistsProgressive();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return loadArtistsProgressive(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return loadArtistsProgressive?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadArtistsProgressive != null) {
      return loadArtistsProgressive(this);
    }
    return orElse();
  }
}

abstract class _LoadArtistsProgressive implements MusicEvent {
  const factory _LoadArtistsProgressive() = _$LoadArtistsProgressiveImpl;
}

/// @nodoc
abstract class _$$LoadMyPlaylistsImplCopyWith<$Res> {
  factory _$$LoadMyPlaylistsImplCopyWith(
    _$LoadMyPlaylistsImpl value,
    $Res Function(_$LoadMyPlaylistsImpl) then,
  ) = __$$LoadMyPlaylistsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadMyPlaylistsImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$LoadMyPlaylistsImpl>
    implements _$$LoadMyPlaylistsImplCopyWith<$Res> {
  __$$LoadMyPlaylistsImplCopyWithImpl(
    _$LoadMyPlaylistsImpl _value,
    $Res Function(_$LoadMyPlaylistsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadMyPlaylistsImpl implements _LoadMyPlaylists {
  const _$LoadMyPlaylistsImpl();

  @override
  String toString() {
    return 'MusicEvent.loadMyPlaylists()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadMyPlaylistsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return loadMyPlaylists();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return loadMyPlaylists?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadMyPlaylists != null) {
      return loadMyPlaylists();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return loadMyPlaylists(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return loadMyPlaylists?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (loadMyPlaylists != null) {
      return loadMyPlaylists(this);
    }
    return orElse();
  }
}

abstract class _LoadMyPlaylists implements MusicEvent {
  const factory _LoadMyPlaylists() = _$LoadMyPlaylistsImpl;
}

/// @nodoc
abstract class _$$AddOrUpdateMyPlayListImplCopyWith<$Res> {
  factory _$$AddOrUpdateMyPlayListImplCopyWith(
    _$AddOrUpdateMyPlayListImpl value,
    $Res Function(_$AddOrUpdateMyPlayListImpl) then,
  ) = __$$AddOrUpdateMyPlayListImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    MyPlaylistOperation operation,
    String? playlistId,
    String? name,
    String? description,
    List<String>? songIds,
    String? songId,
    String? coverImage,
    bool? isPublic,
  });
}

/// @nodoc
class __$$AddOrUpdateMyPlayListImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$AddOrUpdateMyPlayListImpl>
    implements _$$AddOrUpdateMyPlayListImplCopyWith<$Res> {
  __$$AddOrUpdateMyPlayListImplCopyWithImpl(
    _$AddOrUpdateMyPlayListImpl _value,
    $Res Function(_$AddOrUpdateMyPlayListImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? operation = null,
    Object? playlistId = freezed,
    Object? name = freezed,
    Object? description = freezed,
    Object? songIds = freezed,
    Object? songId = freezed,
    Object? coverImage = freezed,
    Object? isPublic = freezed,
  }) {
    return _then(
      _$AddOrUpdateMyPlayListImpl(
        operation: null == operation
            ? _value.operation
            : operation // ignore: cast_nullable_to_non_nullable
                  as MyPlaylistOperation,
        playlistId: freezed == playlistId
            ? _value.playlistId
            : playlistId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        songIds: freezed == songIds
            ? _value._songIds
            : songIds // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        songId: freezed == songId
            ? _value.songId
            : songId // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        isPublic: freezed == isPublic
            ? _value.isPublic
            : isPublic // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc

class _$AddOrUpdateMyPlayListImpl implements _AddOrUpdateMyPlayList {
  const _$AddOrUpdateMyPlayListImpl({
    required this.operation,
    this.playlistId,
    this.name,
    this.description,
    final List<String>? songIds,
    this.songId,
    this.coverImage,
    this.isPublic,
  }) : _songIds = songIds;

  @override
  final MyPlaylistOperation operation;
  @override
  final String? playlistId;
  @override
  final String? name;
  @override
  final String? description;
  final List<String>? _songIds;
  @override
  List<String>? get songIds {
    final value = _songIds;
    if (value == null) return null;
    if (_songIds is EqualUnmodifiableListView) return _songIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? songId;
  @override
  final String? coverImage;
  @override
  final bool? isPublic;

  @override
  String toString() {
    return 'MusicEvent.addOrUpdateMyPlayList(operation: $operation, playlistId: $playlistId, name: $name, description: $description, songIds: $songIds, songId: $songId, coverImage: $coverImage, isPublic: $isPublic)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddOrUpdateMyPlayListImpl &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.playlistId, playlistId) ||
                other.playlistId == playlistId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._songIds, _songIds) &&
            (identical(other.songId, songId) || other.songId == songId) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    operation,
    playlistId,
    name,
    description,
    const DeepCollectionEquality().hash(_songIds),
    songId,
    coverImage,
    isPublic,
  );

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddOrUpdateMyPlayListImplCopyWith<_$AddOrUpdateMyPlayListImpl>
  get copyWith =>
      __$$AddOrUpdateMyPlayListImplCopyWithImpl<_$AddOrUpdateMyPlayListImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return addOrUpdateMyPlayList(
      operation,
      playlistId,
      name,
      description,
      songIds,
      songId,
      coverImage,
      isPublic,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return addOrUpdateMyPlayList?.call(
      operation,
      playlistId,
      name,
      description,
      songIds,
      songId,
      coverImage,
      isPublic,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (addOrUpdateMyPlayList != null) {
      return addOrUpdateMyPlayList(
        operation,
        playlistId,
        name,
        description,
        songIds,
        songId,
        coverImage,
        isPublic,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return addOrUpdateMyPlayList(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return addOrUpdateMyPlayList?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (addOrUpdateMyPlayList != null) {
      return addOrUpdateMyPlayList(this);
    }
    return orElse();
  }
}

abstract class _AddOrUpdateMyPlayList implements MusicEvent {
  const factory _AddOrUpdateMyPlayList({
    required final MyPlaylistOperation operation,
    final String? playlistId,
    final String? name,
    final String? description,
    final List<String>? songIds,
    final String? songId,
    final String? coverImage,
    final bool? isPublic,
  }) = _$AddOrUpdateMyPlayListImpl;

  MyPlaylistOperation get operation;
  String? get playlistId;
  String? get name;
  String? get description;
  List<String>? get songIds;
  String? get songId;
  String? get coverImage;
  bool? get isPublic;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddOrUpdateMyPlayListImplCopyWith<_$AddOrUpdateMyPlayListImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlayOrPauseSongImplCopyWith<$Res> {
  factory _$$PlayOrPauseSongImplCopyWith(
    _$PlayOrPauseSongImpl value,
    $Res Function(_$PlayOrPauseSongImpl) then,
  ) = __$$PlayOrPauseSongImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String? songId,
    List<String>? currentPlayList,
    bool? isForceStop,
    PlaylistSource? playlistSource,
  });

  $PlaylistSourceCopyWith<$Res>? get playlistSource;
}

/// @nodoc
class __$$PlayOrPauseSongImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$PlayOrPauseSongImpl>
    implements _$$PlayOrPauseSongImplCopyWith<$Res> {
  __$$PlayOrPauseSongImplCopyWithImpl(
    _$PlayOrPauseSongImpl _value,
    $Res Function(_$PlayOrPauseSongImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? songId = freezed,
    Object? currentPlayList = freezed,
    Object? isForceStop = freezed,
    Object? playlistSource = freezed,
  }) {
    return _then(
      _$PlayOrPauseSongImpl(
        songId: freezed == songId
            ? _value.songId
            : songId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentPlayList: freezed == currentPlayList
            ? _value._currentPlayList
            : currentPlayList // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        isForceStop: freezed == isForceStop
            ? _value.isForceStop
            : isForceStop // ignore: cast_nullable_to_non_nullable
                  as bool?,
        playlistSource: freezed == playlistSource
            ? _value.playlistSource
            : playlistSource // ignore: cast_nullable_to_non_nullable
                  as PlaylistSource?,
      ),
    );
  }

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistSourceCopyWith<$Res>? get playlistSource {
    if (_value.playlistSource == null) {
      return null;
    }

    return $PlaylistSourceCopyWith<$Res>(_value.playlistSource!, (value) {
      return _then(_value.copyWith(playlistSource: value));
    });
  }
}

/// @nodoc

class _$PlayOrPauseSongImpl implements _PlayOrPauseSong {
  const _$PlayOrPauseSongImpl({
    this.songId,
    final List<String>? currentPlayList,
    this.isForceStop,
    this.playlistSource,
  }) : _currentPlayList = currentPlayList;

  @override
  final String? songId;
  final List<String>? _currentPlayList;
  @override
  List<String>? get currentPlayList {
    final value = _currentPlayList;
    if (value == null) return null;
    if (_currentPlayList is EqualUnmodifiableListView) return _currentPlayList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final bool? isForceStop;
  @override
  final PlaylistSource? playlistSource;

  @override
  String toString() {
    return 'MusicEvent.playOrPauseSong(songId: $songId, currentPlayList: $currentPlayList, isForceStop: $isForceStop, playlistSource: $playlistSource)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayOrPauseSongImpl &&
            (identical(other.songId, songId) || other.songId == songId) &&
            const DeepCollectionEquality().equals(
              other._currentPlayList,
              _currentPlayList,
            ) &&
            (identical(other.isForceStop, isForceStop) ||
                other.isForceStop == isForceStop) &&
            (identical(other.playlistSource, playlistSource) ||
                other.playlistSource == playlistSource));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    songId,
    const DeepCollectionEquality().hash(_currentPlayList),
    isForceStop,
    playlistSource,
  );

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayOrPauseSongImplCopyWith<_$PlayOrPauseSongImpl> get copyWith =>
      __$$PlayOrPauseSongImplCopyWithImpl<_$PlayOrPauseSongImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return playOrPauseSong(
      songId,
      currentPlayList,
      isForceStop,
      playlistSource,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return playOrPauseSong?.call(
      songId,
      currentPlayList,
      isForceStop,
      playlistSource,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (playOrPauseSong != null) {
      return playOrPauseSong(
        songId,
        currentPlayList,
        isForceStop,
        playlistSource,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return playOrPauseSong(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return playOrPauseSong?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (playOrPauseSong != null) {
      return playOrPauseSong(this);
    }
    return orElse();
  }
}

abstract class _PlayOrPauseSong implements MusicEvent {
  const factory _PlayOrPauseSong({
    final String? songId,
    final List<String>? currentPlayList,
    final bool? isForceStop,
    final PlaylistSource? playlistSource,
  }) = _$PlayOrPauseSongImpl;

  String? get songId;
  List<String>? get currentPlayList;
  bool? get isForceStop;
  PlaylistSource? get playlistSource;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayOrPauseSongImplCopyWith<_$PlayOrPauseSongImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlayNextImplCopyWith<$Res> {
  factory _$$PlayNextImplCopyWith(
    _$PlayNextImpl value,
    $Res Function(_$PlayNextImpl) then,
  ) = __$$PlayNextImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PlayNextImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$PlayNextImpl>
    implements _$$PlayNextImplCopyWith<$Res> {
  __$$PlayNextImplCopyWithImpl(
    _$PlayNextImpl _value,
    $Res Function(_$PlayNextImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PlayNextImpl implements _PlayNext {
  const _$PlayNextImpl();

  @override
  String toString() {
    return 'MusicEvent.playNext()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PlayNextImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return playNext();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return playNext?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (playNext != null) {
      return playNext();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return playNext(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return playNext?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (playNext != null) {
      return playNext(this);
    }
    return orElse();
  }
}

abstract class _PlayNext implements MusicEvent {
  const factory _PlayNext() = _$PlayNextImpl;
}

/// @nodoc
abstract class _$$PlayPreviousImplCopyWith<$Res> {
  factory _$$PlayPreviousImplCopyWith(
    _$PlayPreviousImpl value,
    $Res Function(_$PlayPreviousImpl) then,
  ) = __$$PlayPreviousImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PlayPreviousImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$PlayPreviousImpl>
    implements _$$PlayPreviousImplCopyWith<$Res> {
  __$$PlayPreviousImplCopyWithImpl(
    _$PlayPreviousImpl _value,
    $Res Function(_$PlayPreviousImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PlayPreviousImpl implements _PlayPrevious {
  const _$PlayPreviousImpl();

  @override
  String toString() {
    return 'MusicEvent.playPrevious()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PlayPreviousImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return playPrevious();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return playPrevious?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (playPrevious != null) {
      return playPrevious();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return playPrevious(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return playPrevious?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (playPrevious != null) {
      return playPrevious(this);
    }
    return orElse();
  }
}

abstract class _PlayPrevious implements MusicEvent {
  const factory _PlayPrevious() = _$PlayPreviousImpl;
}

/// @nodoc
abstract class _$$ToggleShuffleImplCopyWith<$Res> {
  factory _$$ToggleShuffleImplCopyWith(
    _$ToggleShuffleImpl value,
    $Res Function(_$ToggleShuffleImpl) then,
  ) = __$$ToggleShuffleImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    bool isShuffle,
    bool? isAutoStart,
    List<String> currentPlayList,
    PlaylistSource? playlistSource,
  });

  $PlaylistSourceCopyWith<$Res>? get playlistSource;
}

/// @nodoc
class __$$ToggleShuffleImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$ToggleShuffleImpl>
    implements _$$ToggleShuffleImplCopyWith<$Res> {
  __$$ToggleShuffleImplCopyWithImpl(
    _$ToggleShuffleImpl _value,
    $Res Function(_$ToggleShuffleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isShuffle = null,
    Object? isAutoStart = freezed,
    Object? currentPlayList = null,
    Object? playlistSource = freezed,
  }) {
    return _then(
      _$ToggleShuffleImpl(
        isShuffle: null == isShuffle
            ? _value.isShuffle
            : isShuffle // ignore: cast_nullable_to_non_nullable
                  as bool,
        isAutoStart: freezed == isAutoStart
            ? _value.isAutoStart
            : isAutoStart // ignore: cast_nullable_to_non_nullable
                  as bool?,
        currentPlayList: null == currentPlayList
            ? _value._currentPlayList
            : currentPlayList // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        playlistSource: freezed == playlistSource
            ? _value.playlistSource
            : playlistSource // ignore: cast_nullable_to_non_nullable
                  as PlaylistSource?,
      ),
    );
  }

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistSourceCopyWith<$Res>? get playlistSource {
    if (_value.playlistSource == null) {
      return null;
    }

    return $PlaylistSourceCopyWith<$Res>(_value.playlistSource!, (value) {
      return _then(_value.copyWith(playlistSource: value));
    });
  }
}

/// @nodoc

class _$ToggleShuffleImpl implements _ToggleShuffle {
  const _$ToggleShuffleImpl({
    required this.isShuffle,
    this.isAutoStart,
    required final List<String> currentPlayList,
    this.playlistSource,
  }) : _currentPlayList = currentPlayList;

  @override
  final bool isShuffle;
  @override
  final bool? isAutoStart;
  final List<String> _currentPlayList;
  @override
  List<String> get currentPlayList {
    if (_currentPlayList is EqualUnmodifiableListView) return _currentPlayList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_currentPlayList);
  }

  @override
  final PlaylistSource? playlistSource;

  @override
  String toString() {
    return 'MusicEvent.toggleShuffle(isShuffle: $isShuffle, isAutoStart: $isAutoStart, currentPlayList: $currentPlayList, playlistSource: $playlistSource)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToggleShuffleImpl &&
            (identical(other.isShuffle, isShuffle) ||
                other.isShuffle == isShuffle) &&
            (identical(other.isAutoStart, isAutoStart) ||
                other.isAutoStart == isAutoStart) &&
            const DeepCollectionEquality().equals(
              other._currentPlayList,
              _currentPlayList,
            ) &&
            (identical(other.playlistSource, playlistSource) ||
                other.playlistSource == playlistSource));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isShuffle,
    isAutoStart,
    const DeepCollectionEquality().hash(_currentPlayList),
    playlistSource,
  );

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToggleShuffleImplCopyWith<_$ToggleShuffleImpl> get copyWith =>
      __$$ToggleShuffleImplCopyWithImpl<_$ToggleShuffleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return toggleShuffle(
      isShuffle,
      isAutoStart,
      currentPlayList,
      playlistSource,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return toggleShuffle?.call(
      isShuffle,
      isAutoStart,
      currentPlayList,
      playlistSource,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (toggleShuffle != null) {
      return toggleShuffle(
        isShuffle,
        isAutoStart,
        currentPlayList,
        playlistSource,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return toggleShuffle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return toggleShuffle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (toggleShuffle != null) {
      return toggleShuffle(this);
    }
    return orElse();
  }
}

abstract class _ToggleShuffle implements MusicEvent {
  const factory _ToggleShuffle({
    required final bool isShuffle,
    final bool? isAutoStart,
    required final List<String> currentPlayList,
    final PlaylistSource? playlistSource,
  }) = _$ToggleShuffleImpl;

  bool get isShuffle;
  bool? get isAutoStart;
  List<String> get currentPlayList;
  PlaylistSource? get playlistSource;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToggleShuffleImplCopyWith<_$ToggleShuffleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ToggleRepeatImplCopyWith<$Res> {
  factory _$$ToggleRepeatImplCopyWith(
    _$ToggleRepeatImpl value,
    $Res Function(_$ToggleRepeatImpl) then,
  ) = __$$ToggleRepeatImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ToggleRepeatImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$ToggleRepeatImpl>
    implements _$$ToggleRepeatImplCopyWith<$Res> {
  __$$ToggleRepeatImplCopyWithImpl(
    _$ToggleRepeatImpl _value,
    $Res Function(_$ToggleRepeatImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ToggleRepeatImpl implements _ToggleRepeat {
  const _$ToggleRepeatImpl();

  @override
  String toString() {
    return 'MusicEvent.toggleRepeat()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ToggleRepeatImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return toggleRepeat();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return toggleRepeat?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (toggleRepeat != null) {
      return toggleRepeat();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return toggleRepeat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return toggleRepeat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (toggleRepeat != null) {
      return toggleRepeat(this);
    }
    return orElse();
  }
}

abstract class _ToggleRepeat implements MusicEvent {
  const factory _ToggleRepeat() = _$ToggleRepeatImpl;
}

/// @nodoc
abstract class _$$ChangeSortingOrderImplCopyWith<$Res> {
  factory _$$ChangeSortingOrderImplCopyWith(
    _$ChangeSortingOrderImpl value,
    $Res Function(_$ChangeSortingOrderImpl) then,
  ) = __$$ChangeSortingOrderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    int sortingIndex,
    List<String> sortingList,
    PlaylistSource? playlistSource,
  });

  $PlaylistSourceCopyWith<$Res>? get playlistSource;
}

/// @nodoc
class __$$ChangeSortingOrderImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$ChangeSortingOrderImpl>
    implements _$$ChangeSortingOrderImplCopyWith<$Res> {
  __$$ChangeSortingOrderImplCopyWithImpl(
    _$ChangeSortingOrderImpl _value,
    $Res Function(_$ChangeSortingOrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sortingIndex = null,
    Object? sortingList = null,
    Object? playlistSource = freezed,
  }) {
    return _then(
      _$ChangeSortingOrderImpl(
        sortingIndex: null == sortingIndex
            ? _value.sortingIndex
            : sortingIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        sortingList: null == sortingList
            ? _value._sortingList
            : sortingList // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        playlistSource: freezed == playlistSource
            ? _value.playlistSource
            : playlistSource // ignore: cast_nullable_to_non_nullable
                  as PlaylistSource?,
      ),
    );
  }

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistSourceCopyWith<$Res>? get playlistSource {
    if (_value.playlistSource == null) {
      return null;
    }

    return $PlaylistSourceCopyWith<$Res>(_value.playlistSource!, (value) {
      return _then(_value.copyWith(playlistSource: value));
    });
  }
}

/// @nodoc

class _$ChangeSortingOrderImpl implements _ChangeSortingOrder {
  const _$ChangeSortingOrderImpl({
    required this.sortingIndex,
    required final List<String> sortingList,
    this.playlistSource,
  }) : _sortingList = sortingList;

  @override
  final int sortingIndex;
  final List<String> _sortingList;
  @override
  List<String> get sortingList {
    if (_sortingList is EqualUnmodifiableListView) return _sortingList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sortingList);
  }

  @override
  final PlaylistSource? playlistSource;

  @override
  String toString() {
    return 'MusicEvent.changeSortingOrder(sortingIndex: $sortingIndex, sortingList: $sortingList, playlistSource: $playlistSource)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChangeSortingOrderImpl &&
            (identical(other.sortingIndex, sortingIndex) ||
                other.sortingIndex == sortingIndex) &&
            const DeepCollectionEquality().equals(
              other._sortingList,
              _sortingList,
            ) &&
            (identical(other.playlistSource, playlistSource) ||
                other.playlistSource == playlistSource));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    sortingIndex,
    const DeepCollectionEquality().hash(_sortingList),
    playlistSource,
  );

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChangeSortingOrderImplCopyWith<_$ChangeSortingOrderImpl> get copyWith =>
      __$$ChangeSortingOrderImplCopyWithImpl<_$ChangeSortingOrderImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return changeSortingOrder(sortingIndex, sortingList, playlistSource);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return changeSortingOrder?.call(sortingIndex, sortingList, playlistSource);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (changeSortingOrder != null) {
      return changeSortingOrder(sortingIndex, sortingList, playlistSource);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return changeSortingOrder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return changeSortingOrder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (changeSortingOrder != null) {
      return changeSortingOrder(this);
    }
    return orElse();
  }
}

abstract class _ChangeSortingOrder implements MusicEvent {
  const factory _ChangeSortingOrder({
    required final int sortingIndex,
    required final List<String> sortingList,
    final PlaylistSource? playlistSource,
  }) = _$ChangeSortingOrderImpl;

  int get sortingIndex;
  List<String> get sortingList;
  PlaylistSource? get playlistSource;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChangeSortingOrderImplCopyWith<_$ChangeSortingOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateFilterKeywordImplCopyWith<$Res> {
  factory _$$UpdateFilterKeywordImplCopyWith(
    _$UpdateFilterKeywordImpl value,
    $Res Function(_$UpdateFilterKeywordImpl) then,
  ) = __$$UpdateFilterKeywordImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filterKeyword});
}

/// @nodoc
class __$$UpdateFilterKeywordImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$UpdateFilterKeywordImpl>
    implements _$$UpdateFilterKeywordImplCopyWith<$Res> {
  __$$UpdateFilterKeywordImplCopyWithImpl(
    _$UpdateFilterKeywordImpl _value,
    $Res Function(_$UpdateFilterKeywordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filterKeyword = null}) {
    return _then(
      _$UpdateFilterKeywordImpl(
        filterKeyword: null == filterKeyword
            ? _value.filterKeyword
            : filterKeyword // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UpdateFilterKeywordImpl implements _UpdateFilterKeyword {
  const _$UpdateFilterKeywordImpl({required this.filterKeyword});

  @override
  final String filterKeyword;

  @override
  String toString() {
    return 'MusicEvent.updateFilterKeyword(filterKeyword: $filterKeyword)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateFilterKeywordImpl &&
            (identical(other.filterKeyword, filterKeyword) ||
                other.filterKeyword == filterKeyword));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filterKeyword);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateFilterKeywordImplCopyWith<_$UpdateFilterKeywordImpl> get copyWith =>
      __$$UpdateFilterKeywordImplCopyWithImpl<_$UpdateFilterKeywordImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return updateFilterKeyword(filterKeyword);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return updateFilterKeyword?.call(filterKeyword);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (updateFilterKeyword != null) {
      return updateFilterKeyword(filterKeyword);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return updateFilterKeyword(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return updateFilterKeyword?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (updateFilterKeyword != null) {
      return updateFilterKeyword(this);
    }
    return orElse();
  }
}

abstract class _UpdateFilterKeyword implements MusicEvent {
  const factory _UpdateFilterKeyword({required final String filterKeyword}) =
      _$UpdateFilterKeywordImpl;

  String get filterKeyword;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateFilterKeywordImplCopyWith<_$UpdateFilterKeywordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SetNavigationFilterImplCopyWith<$Res> {
  factory _$$SetNavigationFilterImplCopyWith(
    _$SetNavigationFilterImpl value,
    $Res Function(_$SetNavigationFilterImpl) then,
  ) = __$$SetNavigationFilterImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filterType, String? filterValue});
}

/// @nodoc
class __$$SetNavigationFilterImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$SetNavigationFilterImpl>
    implements _$$SetNavigationFilterImplCopyWith<$Res> {
  __$$SetNavigationFilterImplCopyWithImpl(
    _$SetNavigationFilterImpl _value,
    $Res Function(_$SetNavigationFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filterType = null, Object? filterValue = freezed}) {
    return _then(
      _$SetNavigationFilterImpl(
        filterType: null == filterType
            ? _value.filterType
            : filterType // ignore: cast_nullable_to_non_nullable
                  as String,
        filterValue: freezed == filterValue
            ? _value.filterValue
            : filterValue // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SetNavigationFilterImpl implements _SetNavigationFilter {
  const _$SetNavigationFilterImpl({required this.filterType, this.filterValue});

  @override
  final String filterType;
  @override
  final String? filterValue;

  @override
  String toString() {
    return 'MusicEvent.setNavigationFilter(filterType: $filterType, filterValue: $filterValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetNavigationFilterImpl &&
            (identical(other.filterType, filterType) ||
                other.filterType == filterType) &&
            (identical(other.filterValue, filterValue) ||
                other.filterValue == filterValue));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filterType, filterValue);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetNavigationFilterImplCopyWith<_$SetNavigationFilterImpl> get copyWith =>
      __$$SetNavigationFilterImplCopyWithImpl<_$SetNavigationFilterImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return setNavigationFilter(filterType, filterValue);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return setNavigationFilter?.call(filterType, filterValue);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (setNavigationFilter != null) {
      return setNavigationFilter(filterType, filterValue);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return setNavigationFilter(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return setNavigationFilter?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (setNavigationFilter != null) {
      return setNavigationFilter(this);
    }
    return orElse();
  }
}

abstract class _SetNavigationFilter implements MusicEvent {
  const factory _SetNavigationFilter({
    required final String filterType,
    final String? filterValue,
  }) = _$SetNavigationFilterImpl;

  String get filterType;
  String? get filterValue;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetNavigationFilterImplCopyWith<_$SetNavigationFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SeekToPositionImplCopyWith<$Res> {
  factory _$$SeekToPositionImplCopyWith(
    _$SeekToPositionImpl value,
    $Res Function(_$SeekToPositionImpl) then,
  ) = __$$SeekToPositionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Duration position});
}

/// @nodoc
class __$$SeekToPositionImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$SeekToPositionImpl>
    implements _$$SeekToPositionImplCopyWith<$Res> {
  __$$SeekToPositionImplCopyWithImpl(
    _$SeekToPositionImpl _value,
    $Res Function(_$SeekToPositionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? position = null}) {
    return _then(
      _$SeekToPositionImpl(
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc

class _$SeekToPositionImpl implements _SeekToPosition {
  const _$SeekToPositionImpl({required this.position});

  @override
  final Duration position;

  @override
  String toString() {
    return 'MusicEvent.seekToPosition(position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeekToPositionImpl &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @override
  int get hashCode => Object.hash(runtimeType, position);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeekToPositionImplCopyWith<_$SeekToPositionImpl> get copyWith =>
      __$$SeekToPositionImplCopyWithImpl<_$SeekToPositionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return seekToPosition(position);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return seekToPosition?.call(position);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (seekToPosition != null) {
      return seekToPosition(position);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return seekToPosition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return seekToPosition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (seekToPosition != null) {
      return seekToPosition(this);
    }
    return orElse();
  }
}

abstract class _SeekToPosition implements MusicEvent {
  const factory _SeekToPosition({required final Duration position}) =
      _$SeekToPositionImpl;

  Duration get position;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeekToPositionImplCopyWith<_$SeekToPositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateLastPositionImplCopyWith<$Res> {
  factory _$$UpdateLastPositionImplCopyWith(
    _$UpdateLastPositionImpl value,
    $Res Function(_$UpdateLastPositionImpl) then,
  ) = __$$UpdateLastPositionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Duration position});
}

/// @nodoc
class __$$UpdateLastPositionImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$UpdateLastPositionImpl>
    implements _$$UpdateLastPositionImplCopyWith<$Res> {
  __$$UpdateLastPositionImplCopyWithImpl(
    _$UpdateLastPositionImpl _value,
    $Res Function(_$UpdateLastPositionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? position = null}) {
    return _then(
      _$UpdateLastPositionImpl(
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc

class _$UpdateLastPositionImpl implements _UpdateLastPosition {
  const _$UpdateLastPositionImpl({required this.position});

  @override
  final Duration position;

  @override
  String toString() {
    return 'MusicEvent.updateLastPosition(position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateLastPositionImpl &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @override
  int get hashCode => Object.hash(runtimeType, position);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateLastPositionImplCopyWith<_$UpdateLastPositionImpl> get copyWith =>
      __$$UpdateLastPositionImplCopyWithImpl<_$UpdateLastPositionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return updateLastPosition(position);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return updateLastPosition?.call(position);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (updateLastPosition != null) {
      return updateLastPosition(position);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return updateLastPosition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return updateLastPosition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (updateLastPosition != null) {
      return updateLastPosition(this);
    }
    return orElse();
  }
}

abstract class _UpdateLastPosition implements MusicEvent {
  const factory _UpdateLastPosition({required final Duration position}) =
      _$UpdateLastPositionImpl;

  Duration get position;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateLastPositionImplCopyWith<_$UpdateLastPositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateMusicBlocStateImplCopyWith<$Res> {
  factory _$$UpdateMusicBlocStateImplCopyWith(
    _$UpdateMusicBlocStateImpl value,
    $Res Function(_$UpdateMusicBlocStateImpl) then,
  ) = __$$UpdateMusicBlocStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MusicState newState});

  $MusicStateCopyWith<$Res> get newState;
}

/// @nodoc
class __$$UpdateMusicBlocStateImplCopyWithImpl<$Res>
    extends _$MusicEventCopyWithImpl<$Res, _$UpdateMusicBlocStateImpl>
    implements _$$UpdateMusicBlocStateImplCopyWith<$Res> {
  __$$UpdateMusicBlocStateImplCopyWithImpl(
    _$UpdateMusicBlocStateImpl _value,
    $Res Function(_$UpdateMusicBlocStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? newState = null}) {
    return _then(
      _$UpdateMusicBlocStateImpl(
        newState: null == newState
            ? _value.newState
            : newState // ignore: cast_nullable_to_non_nullable
                  as MusicState,
      ),
    );
  }

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MusicStateCopyWith<$Res> get newState {
    return $MusicStateCopyWith<$Res>(_value.newState, (value) {
      return _then(_value.copyWith(newState: value));
    });
  }
}

/// @nodoc

class _$UpdateMusicBlocStateImpl implements _UpdateMusicBlocState {
  const _$UpdateMusicBlocStateImpl({required this.newState});

  @override
  final MusicState newState;

  @override
  String toString() {
    return 'MusicEvent.updateMusicBlocState(newState: $newState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateMusicBlocStateImpl &&
            (identical(other.newState, newState) ||
                other.newState == newState));
  }

  @override
  int get hashCode => Object.hash(runtimeType, newState);

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateMusicBlocStateImplCopyWith<_$UpdateMusicBlocStateImpl>
  get copyWith =>
      __$$UpdateMusicBlocStateImplCopyWithImpl<_$UpdateMusicBlocStateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadAllSongs,
    required TResult Function() loadAllSongsProgressive,
    required TResult Function() loadAlbums,
    required TResult Function() loadAlbumsProgressive,
    required TResult Function() loadArtists,
    required TResult Function() loadArtistsProgressive,
    required TResult Function() loadMyPlaylists,
    required TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )
    addOrUpdateMyPlayList,
    required TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )
    playOrPauseSong,
    required TResult Function() playNext,
    required TResult Function() playPrevious,
    required TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )
    toggleShuffle,
    required TResult Function() toggleRepeat,
    required TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )
    changeSortingOrder,
    required TResult Function(String filterKeyword) updateFilterKeyword,
    required TResult Function(String filterType, String? filterValue)
    setNavigationFilter,
    required TResult Function(Duration position) seekToPosition,
    required TResult Function(Duration position) updateLastPosition,
    required TResult Function(MusicState newState) updateMusicBlocState,
  }) {
    return updateMusicBlocState(newState);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadAllSongs,
    TResult? Function()? loadAllSongsProgressive,
    TResult? Function()? loadAlbums,
    TResult? Function()? loadAlbumsProgressive,
    TResult? Function()? loadArtists,
    TResult? Function()? loadArtistsProgressive,
    TResult? Function()? loadMyPlaylists,
    TResult? Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult? Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult? Function()? playNext,
    TResult? Function()? playPrevious,
    TResult? Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult? Function()? toggleRepeat,
    TResult? Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult? Function(String filterKeyword)? updateFilterKeyword,
    TResult? Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult? Function(Duration position)? seekToPosition,
    TResult? Function(Duration position)? updateLastPosition,
    TResult? Function(MusicState newState)? updateMusicBlocState,
  }) {
    return updateMusicBlocState?.call(newState);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadAllSongs,
    TResult Function()? loadAllSongsProgressive,
    TResult Function()? loadAlbums,
    TResult Function()? loadAlbumsProgressive,
    TResult Function()? loadArtists,
    TResult Function()? loadArtistsProgressive,
    TResult Function()? loadMyPlaylists,
    TResult Function(
      MyPlaylistOperation operation,
      String? playlistId,
      String? name,
      String? description,
      List<String>? songIds,
      String? songId,
      String? coverImage,
      bool? isPublic,
    )?
    addOrUpdateMyPlayList,
    TResult Function(
      String? songId,
      List<String>? currentPlayList,
      bool? isForceStop,
      PlaylistSource? playlistSource,
    )?
    playOrPauseSong,
    TResult Function()? playNext,
    TResult Function()? playPrevious,
    TResult Function(
      bool isShuffle,
      bool? isAutoStart,
      List<String> currentPlayList,
      PlaylistSource? playlistSource,
    )?
    toggleShuffle,
    TResult Function()? toggleRepeat,
    TResult Function(
      int sortingIndex,
      List<String> sortingList,
      PlaylistSource? playlistSource,
    )?
    changeSortingOrder,
    TResult Function(String filterKeyword)? updateFilterKeyword,
    TResult Function(String filterType, String? filterValue)?
    setNavigationFilter,
    TResult Function(Duration position)? seekToPosition,
    TResult Function(Duration position)? updateLastPosition,
    TResult Function(MusicState newState)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (updateMusicBlocState != null) {
      return updateMusicBlocState(newState);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadAllSongs value) loadAllSongs,
    required TResult Function(_LoadAllSongsProgressive value)
    loadAllSongsProgressive,
    required TResult Function(_LoadAlbums value) loadAlbums,
    required TResult Function(_LoadAlbumsProgressive value)
    loadAlbumsProgressive,
    required TResult Function(_LoadArtists value) loadArtists,
    required TResult Function(_LoadArtistsProgressive value)
    loadArtistsProgressive,
    required TResult Function(_LoadMyPlaylists value) loadMyPlaylists,
    required TResult Function(_AddOrUpdateMyPlayList value)
    addOrUpdateMyPlayList,
    required TResult Function(_PlayOrPauseSong value) playOrPauseSong,
    required TResult Function(_PlayNext value) playNext,
    required TResult Function(_PlayPrevious value) playPrevious,
    required TResult Function(_ToggleShuffle value) toggleShuffle,
    required TResult Function(_ToggleRepeat value) toggleRepeat,
    required TResult Function(_ChangeSortingOrder value) changeSortingOrder,
    required TResult Function(_UpdateFilterKeyword value) updateFilterKeyword,
    required TResult Function(_SetNavigationFilter value) setNavigationFilter,
    required TResult Function(_SeekToPosition value) seekToPosition,
    required TResult Function(_UpdateLastPosition value) updateLastPosition,
    required TResult Function(_UpdateMusicBlocState value) updateMusicBlocState,
  }) {
    return updateMusicBlocState(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadAllSongs value)? loadAllSongs,
    TResult? Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult? Function(_LoadAlbums value)? loadAlbums,
    TResult? Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult? Function(_LoadArtists value)? loadArtists,
    TResult? Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult? Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult? Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult? Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult? Function(_PlayNext value)? playNext,
    TResult? Function(_PlayPrevious value)? playPrevious,
    TResult? Function(_ToggleShuffle value)? toggleShuffle,
    TResult? Function(_ToggleRepeat value)? toggleRepeat,
    TResult? Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult? Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult? Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult? Function(_SeekToPosition value)? seekToPosition,
    TResult? Function(_UpdateLastPosition value)? updateLastPosition,
    TResult? Function(_UpdateMusicBlocState value)? updateMusicBlocState,
  }) {
    return updateMusicBlocState?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadAllSongs value)? loadAllSongs,
    TResult Function(_LoadAllSongsProgressive value)? loadAllSongsProgressive,
    TResult Function(_LoadAlbums value)? loadAlbums,
    TResult Function(_LoadAlbumsProgressive value)? loadAlbumsProgressive,
    TResult Function(_LoadArtists value)? loadArtists,
    TResult Function(_LoadArtistsProgressive value)? loadArtistsProgressive,
    TResult Function(_LoadMyPlaylists value)? loadMyPlaylists,
    TResult Function(_AddOrUpdateMyPlayList value)? addOrUpdateMyPlayList,
    TResult Function(_PlayOrPauseSong value)? playOrPauseSong,
    TResult Function(_PlayNext value)? playNext,
    TResult Function(_PlayPrevious value)? playPrevious,
    TResult Function(_ToggleShuffle value)? toggleShuffle,
    TResult Function(_ToggleRepeat value)? toggleRepeat,
    TResult Function(_ChangeSortingOrder value)? changeSortingOrder,
    TResult Function(_UpdateFilterKeyword value)? updateFilterKeyword,
    TResult Function(_SetNavigationFilter value)? setNavigationFilter,
    TResult Function(_SeekToPosition value)? seekToPosition,
    TResult Function(_UpdateLastPosition value)? updateLastPosition,
    TResult Function(_UpdateMusicBlocState value)? updateMusicBlocState,
    required TResult orElse(),
  }) {
    if (updateMusicBlocState != null) {
      return updateMusicBlocState(this);
    }
    return orElse();
  }
}

abstract class _UpdateMusicBlocState implements MusicEvent {
  const factory _UpdateMusicBlocState({required final MusicState newState}) =
      _$UpdateMusicBlocStateImpl;

  MusicState get newState;

  /// Create a copy of MusicEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateMusicBlocStateImplCopyWith<_$UpdateMusicBlocStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MusicState {
  // Player state with current playlist, completed songs, and playlist reference
  MyPlayerStateModel get myPlayerState =>
      throw _privateConstructorUsedError; // Core data
  List<Song> get allSongs => throw _privateConstructorUsedError;
  List<Album> get albumList => throw _privateConstructorUsedError;
  List<Artist> get artistList => throw _privateConstructorUsedError;
  List<MyPlaylist> get myPlaylist =>
      throw _privateConstructorUsedError; // Sorting state
  int get sortingIndex =>
      throw _privateConstructorUsedError; // Navigation filter state
  String get navigationFilterType => throw _privateConstructorUsedError;
  String get navigationFilterValue =>
      throw _privateConstructorUsedError; // Loading states
  bool get isSongListLoading => throw _privateConstructorUsedError;
  bool get isAlbumListLoading => throw _privateConstructorUsedError;
  bool get isArtistListLoading =>
      throw _privateConstructorUsedError; // Progress tracking
  int get songLoadingProgress =>
      throw _privateConstructorUsedError; // Error states
  bool get isSongListError => throw _privateConstructorUsedError;
  bool get isAlbumListError => throw _privateConstructorUsedError;
  bool get isArtistListError =>
      throw _privateConstructorUsedError; // General loading and error states (for backward compatibility)
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isError => throw _privateConstructorUsedError;

  /// Create a copy of MusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MusicStateCopyWith<MusicState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicStateCopyWith<$Res> {
  factory $MusicStateCopyWith(
    MusicState value,
    $Res Function(MusicState) then,
  ) = _$MusicStateCopyWithImpl<$Res, MusicState>;
  @useResult
  $Res call({
    MyPlayerStateModel myPlayerState,
    List<Song> allSongs,
    List<Album> albumList,
    List<Artist> artistList,
    List<MyPlaylist> myPlaylist,
    int sortingIndex,
    String navigationFilterType,
    String navigationFilterValue,
    bool isSongListLoading,
    bool isAlbumListLoading,
    bool isArtistListLoading,
    int songLoadingProgress,
    bool isSongListError,
    bool isAlbumListError,
    bool isArtistListError,
    bool isLoading,
    bool isError,
  });
}

/// @nodoc
class _$MusicStateCopyWithImpl<$Res, $Val extends MusicState>
    implements $MusicStateCopyWith<$Res> {
  _$MusicStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MusicState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? myPlayerState = null,
    Object? allSongs = null,
    Object? albumList = null,
    Object? artistList = null,
    Object? myPlaylist = null,
    Object? sortingIndex = null,
    Object? navigationFilterType = null,
    Object? navigationFilterValue = null,
    Object? isSongListLoading = null,
    Object? isAlbumListLoading = null,
    Object? isArtistListLoading = null,
    Object? songLoadingProgress = null,
    Object? isSongListError = null,
    Object? isAlbumListError = null,
    Object? isArtistListError = null,
    Object? isLoading = null,
    Object? isError = null,
  }) {
    return _then(
      _value.copyWith(
            myPlayerState: null == myPlayerState
                ? _value.myPlayerState
                : myPlayerState // ignore: cast_nullable_to_non_nullable
                      as MyPlayerStateModel,
            allSongs: null == allSongs
                ? _value.allSongs
                : allSongs // ignore: cast_nullable_to_non_nullable
                      as List<Song>,
            albumList: null == albumList
                ? _value.albumList
                : albumList // ignore: cast_nullable_to_non_nullable
                      as List<Album>,
            artistList: null == artistList
                ? _value.artistList
                : artistList // ignore: cast_nullable_to_non_nullable
                      as List<Artist>,
            myPlaylist: null == myPlaylist
                ? _value.myPlaylist
                : myPlaylist // ignore: cast_nullable_to_non_nullable
                      as List<MyPlaylist>,
            sortingIndex: null == sortingIndex
                ? _value.sortingIndex
                : sortingIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            navigationFilterType: null == navigationFilterType
                ? _value.navigationFilterType
                : navigationFilterType // ignore: cast_nullable_to_non_nullable
                      as String,
            navigationFilterValue: null == navigationFilterValue
                ? _value.navigationFilterValue
                : navigationFilterValue // ignore: cast_nullable_to_non_nullable
                      as String,
            isSongListLoading: null == isSongListLoading
                ? _value.isSongListLoading
                : isSongListLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isAlbumListLoading: null == isAlbumListLoading
                ? _value.isAlbumListLoading
                : isAlbumListLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isArtistListLoading: null == isArtistListLoading
                ? _value.isArtistListLoading
                : isArtistListLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            songLoadingProgress: null == songLoadingProgress
                ? _value.songLoadingProgress
                : songLoadingProgress // ignore: cast_nullable_to_non_nullable
                      as int,
            isSongListError: null == isSongListError
                ? _value.isSongListError
                : isSongListError // ignore: cast_nullable_to_non_nullable
                      as bool,
            isAlbumListError: null == isAlbumListError
                ? _value.isAlbumListError
                : isAlbumListError // ignore: cast_nullable_to_non_nullable
                      as bool,
            isArtistListError: null == isArtistListError
                ? _value.isArtistListError
                : isArtistListError // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isError: null == isError
                ? _value.isError
                : isError // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res>
    implements $MusicStateCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    MyPlayerStateModel myPlayerState,
    List<Song> allSongs,
    List<Album> albumList,
    List<Artist> artistList,
    List<MyPlaylist> myPlaylist,
    int sortingIndex,
    String navigationFilterType,
    String navigationFilterValue,
    bool isSongListLoading,
    bool isAlbumListLoading,
    bool isArtistListLoading,
    int songLoadingProgress,
    bool isSongListError,
    bool isAlbumListError,
    bool isArtistListError,
    bool isLoading,
    bool isError,
  });
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$MusicStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? myPlayerState = null,
    Object? allSongs = null,
    Object? albumList = null,
    Object? artistList = null,
    Object? myPlaylist = null,
    Object? sortingIndex = null,
    Object? navigationFilterType = null,
    Object? navigationFilterValue = null,
    Object? isSongListLoading = null,
    Object? isAlbumListLoading = null,
    Object? isArtistListLoading = null,
    Object? songLoadingProgress = null,
    Object? isSongListError = null,
    Object? isAlbumListError = null,
    Object? isArtistListError = null,
    Object? isLoading = null,
    Object? isError = null,
  }) {
    return _then(
      _$InitialImpl(
        myPlayerState: null == myPlayerState
            ? _value.myPlayerState
            : myPlayerState // ignore: cast_nullable_to_non_nullable
                  as MyPlayerStateModel,
        allSongs: null == allSongs
            ? _value._allSongs
            : allSongs // ignore: cast_nullable_to_non_nullable
                  as List<Song>,
        albumList: null == albumList
            ? _value._albumList
            : albumList // ignore: cast_nullable_to_non_nullable
                  as List<Album>,
        artistList: null == artistList
            ? _value._artistList
            : artistList // ignore: cast_nullable_to_non_nullable
                  as List<Artist>,
        myPlaylist: null == myPlaylist
            ? _value._myPlaylist
            : myPlaylist // ignore: cast_nullable_to_non_nullable
                  as List<MyPlaylist>,
        sortingIndex: null == sortingIndex
            ? _value.sortingIndex
            : sortingIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        navigationFilterType: null == navigationFilterType
            ? _value.navigationFilterType
            : navigationFilterType // ignore: cast_nullable_to_non_nullable
                  as String,
        navigationFilterValue: null == navigationFilterValue
            ? _value.navigationFilterValue
            : navigationFilterValue // ignore: cast_nullable_to_non_nullable
                  as String,
        isSongListLoading: null == isSongListLoading
            ? _value.isSongListLoading
            : isSongListLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isAlbumListLoading: null == isAlbumListLoading
            ? _value.isAlbumListLoading
            : isAlbumListLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isArtistListLoading: null == isArtistListLoading
            ? _value.isArtistListLoading
            : isArtistListLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        songLoadingProgress: null == songLoadingProgress
            ? _value.songLoadingProgress
            : songLoadingProgress // ignore: cast_nullable_to_non_nullable
                  as int,
        isSongListError: null == isSongListError
            ? _value.isSongListError
            : isSongListError // ignore: cast_nullable_to_non_nullable
                  as bool,
        isAlbumListError: null == isAlbumListError
            ? _value.isAlbumListError
            : isAlbumListError // ignore: cast_nullable_to_non_nullable
                  as bool,
        isArtistListError: null == isArtistListError
            ? _value.isArtistListError
            : isArtistListError // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isError: null == isError
            ? _value.isError
            : isError // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl({
    required this.myPlayerState,
    required final List<Song> allSongs,
    required final List<Album> albumList,
    required final List<Artist> artistList,
    required final List<MyPlaylist> myPlaylist,
    required this.sortingIndex,
    this.navigationFilterType = '',
    this.navigationFilterValue = '',
    required this.isSongListLoading,
    required this.isAlbumListLoading,
    required this.isArtistListLoading,
    this.songLoadingProgress = 0,
    required this.isSongListError,
    required this.isAlbumListError,
    required this.isArtistListError,
    required this.isLoading,
    required this.isError,
  }) : _allSongs = allSongs,
       _albumList = albumList,
       _artistList = artistList,
       _myPlaylist = myPlaylist;

  // Player state with current playlist, completed songs, and playlist reference
  @override
  final MyPlayerStateModel myPlayerState;
  // Core data
  final List<Song> _allSongs;
  // Core data
  @override
  List<Song> get allSongs {
    if (_allSongs is EqualUnmodifiableListView) return _allSongs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allSongs);
  }

  final List<Album> _albumList;
  @override
  List<Album> get albumList {
    if (_albumList is EqualUnmodifiableListView) return _albumList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_albumList);
  }

  final List<Artist> _artistList;
  @override
  List<Artist> get artistList {
    if (_artistList is EqualUnmodifiableListView) return _artistList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artistList);
  }

  final List<MyPlaylist> _myPlaylist;
  @override
  List<MyPlaylist> get myPlaylist {
    if (_myPlaylist is EqualUnmodifiableListView) return _myPlaylist;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_myPlaylist);
  }

  // Sorting state
  @override
  final int sortingIndex;
  // Navigation filter state
  @override
  @JsonKey()
  final String navigationFilterType;
  @override
  @JsonKey()
  final String navigationFilterValue;
  // Loading states
  @override
  final bool isSongListLoading;
  @override
  final bool isAlbumListLoading;
  @override
  final bool isArtistListLoading;
  // Progress tracking
  @override
  @JsonKey()
  final int songLoadingProgress;
  // Error states
  @override
  final bool isSongListError;
  @override
  final bool isAlbumListError;
  @override
  final bool isArtistListError;
  // General loading and error states (for backward compatibility)
  @override
  final bool isLoading;
  @override
  final bool isError;

  @override
  String toString() {
    return 'MusicState(myPlayerState: $myPlayerState, allSongs: $allSongs, albumList: $albumList, artistList: $artistList, myPlaylist: $myPlaylist, sortingIndex: $sortingIndex, navigationFilterType: $navigationFilterType, navigationFilterValue: $navigationFilterValue, isSongListLoading: $isSongListLoading, isAlbumListLoading: $isAlbumListLoading, isArtistListLoading: $isArtistListLoading, songLoadingProgress: $songLoadingProgress, isSongListError: $isSongListError, isAlbumListError: $isAlbumListError, isArtistListError: $isArtistListError, isLoading: $isLoading, isError: $isError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InitialImpl &&
            (identical(other.myPlayerState, myPlayerState) ||
                other.myPlayerState == myPlayerState) &&
            const DeepCollectionEquality().equals(other._allSongs, _allSongs) &&
            const DeepCollectionEquality().equals(
              other._albumList,
              _albumList,
            ) &&
            const DeepCollectionEquality().equals(
              other._artistList,
              _artistList,
            ) &&
            const DeepCollectionEquality().equals(
              other._myPlaylist,
              _myPlaylist,
            ) &&
            (identical(other.sortingIndex, sortingIndex) ||
                other.sortingIndex == sortingIndex) &&
            (identical(other.navigationFilterType, navigationFilterType) ||
                other.navigationFilterType == navigationFilterType) &&
            (identical(other.navigationFilterValue, navigationFilterValue) ||
                other.navigationFilterValue == navigationFilterValue) &&
            (identical(other.isSongListLoading, isSongListLoading) ||
                other.isSongListLoading == isSongListLoading) &&
            (identical(other.isAlbumListLoading, isAlbumListLoading) ||
                other.isAlbumListLoading == isAlbumListLoading) &&
            (identical(other.isArtistListLoading, isArtistListLoading) ||
                other.isArtistListLoading == isArtistListLoading) &&
            (identical(other.songLoadingProgress, songLoadingProgress) ||
                other.songLoadingProgress == songLoadingProgress) &&
            (identical(other.isSongListError, isSongListError) ||
                other.isSongListError == isSongListError) &&
            (identical(other.isAlbumListError, isAlbumListError) ||
                other.isAlbumListError == isAlbumListError) &&
            (identical(other.isArtistListError, isArtistListError) ||
                other.isArtistListError == isArtistListError) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isError, isError) || other.isError == isError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    myPlayerState,
    const DeepCollectionEquality().hash(_allSongs),
    const DeepCollectionEquality().hash(_albumList),
    const DeepCollectionEquality().hash(_artistList),
    const DeepCollectionEquality().hash(_myPlaylist),
    sortingIndex,
    navigationFilterType,
    navigationFilterValue,
    isSongListLoading,
    isAlbumListLoading,
    isArtistListLoading,
    songLoadingProgress,
    isSongListError,
    isAlbumListError,
    isArtistListError,
    isLoading,
    isError,
  );

  /// Create a copy of MusicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InitialImplCopyWith<_$InitialImpl> get copyWith =>
      __$$InitialImplCopyWithImpl<_$InitialImpl>(this, _$identity);
}

abstract class _Initial implements MusicState {
  const factory _Initial({
    required final MyPlayerStateModel myPlayerState,
    required final List<Song> allSongs,
    required final List<Album> albumList,
    required final List<Artist> artistList,
    required final List<MyPlaylist> myPlaylist,
    required final int sortingIndex,
    final String navigationFilterType,
    final String navigationFilterValue,
    required final bool isSongListLoading,
    required final bool isAlbumListLoading,
    required final bool isArtistListLoading,
    final int songLoadingProgress,
    required final bool isSongListError,
    required final bool isAlbumListError,
    required final bool isArtistListError,
    required final bool isLoading,
    required final bool isError,
  }) = _$InitialImpl;

  // Player state with current playlist, completed songs, and playlist reference
  @override
  MyPlayerStateModel get myPlayerState; // Core data
  @override
  List<Song> get allSongs;
  @override
  List<Album> get albumList;
  @override
  List<Artist> get artistList;
  @override
  List<MyPlaylist> get myPlaylist; // Sorting state
  @override
  int get sortingIndex; // Navigation filter state
  @override
  String get navigationFilterType;
  @override
  String get navigationFilterValue; // Loading states
  @override
  bool get isSongListLoading;
  @override
  bool get isAlbumListLoading;
  @override
  bool get isArtistListLoading; // Progress tracking
  @override
  int get songLoadingProgress; // Error states
  @override
  bool get isSongListError;
  @override
  bool get isAlbumListError;
  @override
  bool get isArtistListError; // General loading and error states (for backward compatibility)
  @override
  bool get isLoading;
  @override
  bool get isError;

  /// Create a copy of MusicState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InitialImplCopyWith<_$InitialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

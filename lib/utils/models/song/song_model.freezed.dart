// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Song _$SongFromJson(Map<String, dynamic> json) {
  return _Song.fromJson(json);
}

/// @nodoc
mixin _$Song {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<String> get artists => throw _privateConstructorUsedError;
  List<String> get albums => throw _privateConstructorUsedError;
  List<String>? get myPlaylistIds => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  @DurationConverter()
  Duration get duration => throw _privateConstructorUsedError;
  String? get albumArt => throw _privateConstructorUsedError;
  String? get genre => throw _privateConstructorUsedError;
  int? get year => throw _privateConstructorUsedError;
  int? get trackNumber => throw _privateConstructorUsedError;
  int? get discNumber => throw _privateConstructorUsedError;
  String? get composer => throw _privateConstructorUsedError;
  String? get lyrics => throw _privateConstructorUsedError;
  int? get bitrate => throw _privateConstructorUsedError;
  int? get fileSize =>
      throw _privateConstructorUsedError; // changed from String? → int? (bytes)
  DateTime? get dateAdded => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get lastPlayed => throw _privateConstructorUsedError;
  int? get playCount => throw _privateConstructorUsedError;
  bool? get isFavorite => throw _privateConstructorUsedError;
  String? get albumArtist => throw _privateConstructorUsedError;

  /// Serializes this Song to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongCopyWith<Song> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongCopyWith<$Res> {
  factory $SongCopyWith(Song value, $Res Function(Song) then) =
      _$SongCopyWithImpl<$Res, Song>;
  @useResult
  $Res call({
    String id,
    String title,
    List<String> artists,
    List<String> albums,
    List<String>? myPlaylistIds,
    String path,
    @DurationConverter() Duration duration,
    String? albumArt,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    String? composer,
    String? lyrics,
    int? bitrate,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    int? playCount,
    bool? isFavorite,
    String? albumArtist,
  });
}

/// @nodoc
class _$SongCopyWithImpl<$Res, $Val extends Song>
    implements $SongCopyWith<$Res> {
  _$SongCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artists = null,
    Object? albums = null,
    Object? myPlaylistIds = freezed,
    Object? path = null,
    Object? duration = null,
    Object? albumArt = freezed,
    Object? genre = freezed,
    Object? year = freezed,
    Object? trackNumber = freezed,
    Object? discNumber = freezed,
    Object? composer = freezed,
    Object? lyrics = freezed,
    Object? bitrate = freezed,
    Object? fileSize = freezed,
    Object? dateAdded = freezed,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
    Object? playCount = freezed,
    Object? isFavorite = freezed,
    Object? albumArtist = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            artists: null == artists
                ? _value.artists
                : artists // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            albums: null == albums
                ? _value.albums
                : albums // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            myPlaylistIds: freezed == myPlaylistIds
                ? _value.myPlaylistIds
                : myPlaylistIds // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as Duration,
            albumArt: freezed == albumArt
                ? _value.albumArt
                : albumArt // ignore: cast_nullable_to_non_nullable
                      as String?,
            genre: freezed == genre
                ? _value.genre
                : genre // ignore: cast_nullable_to_non_nullable
                      as String?,
            year: freezed == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int?,
            trackNumber: freezed == trackNumber
                ? _value.trackNumber
                : trackNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            discNumber: freezed == discNumber
                ? _value.discNumber
                : discNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            composer: freezed == composer
                ? _value.composer
                : composer // ignore: cast_nullable_to_non_nullable
                      as String?,
            lyrics: freezed == lyrics
                ? _value.lyrics
                : lyrics // ignore: cast_nullable_to_non_nullable
                      as String?,
            bitrate: freezed == bitrate
                ? _value.bitrate
                : bitrate // ignore: cast_nullable_to_non_nullable
                      as int?,
            fileSize: freezed == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int?,
            dateAdded: freezed == dateAdded
                ? _value.dateAdded
                : dateAdded // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastPlayed: freezed == lastPlayed
                ? _value.lastPlayed
                : lastPlayed // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            playCount: freezed == playCount
                ? _value.playCount
                : playCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            isFavorite: freezed == isFavorite
                ? _value.isFavorite
                : isFavorite // ignore: cast_nullable_to_non_nullable
                      as bool?,
            albumArtist: freezed == albumArtist
                ? _value.albumArtist
                : albumArtist // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SongImplCopyWith<$Res> implements $SongCopyWith<$Res> {
  factory _$$SongImplCopyWith(
    _$SongImpl value,
    $Res Function(_$SongImpl) then,
  ) = __$$SongImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    List<String> artists,
    List<String> albums,
    List<String>? myPlaylistIds,
    String path,
    @DurationConverter() Duration duration,
    String? albumArt,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    String? composer,
    String? lyrics,
    int? bitrate,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    int? playCount,
    bool? isFavorite,
    String? albumArtist,
  });
}

/// @nodoc
class __$$SongImplCopyWithImpl<$Res>
    extends _$SongCopyWithImpl<$Res, _$SongImpl>
    implements _$$SongImplCopyWith<$Res> {
  __$$SongImplCopyWithImpl(_$SongImpl _value, $Res Function(_$SongImpl) _then)
    : super(_value, _then);

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artists = null,
    Object? albums = null,
    Object? myPlaylistIds = freezed,
    Object? path = null,
    Object? duration = null,
    Object? albumArt = freezed,
    Object? genre = freezed,
    Object? year = freezed,
    Object? trackNumber = freezed,
    Object? discNumber = freezed,
    Object? composer = freezed,
    Object? lyrics = freezed,
    Object? bitrate = freezed,
    Object? fileSize = freezed,
    Object? dateAdded = freezed,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
    Object? playCount = freezed,
    Object? isFavorite = freezed,
    Object? albumArtist = freezed,
  }) {
    return _then(
      _$SongImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        artists: null == artists
            ? _value._artists
            : artists // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        albums: null == albums
            ? _value._albums
            : albums // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        myPlaylistIds: freezed == myPlaylistIds
            ? _value._myPlaylistIds
            : myPlaylistIds // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration,
        albumArt: freezed == albumArt
            ? _value.albumArt
            : albumArt // ignore: cast_nullable_to_non_nullable
                  as String?,
        genre: freezed == genre
            ? _value.genre
            : genre // ignore: cast_nullable_to_non_nullable
                  as String?,
        year: freezed == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int?,
        trackNumber: freezed == trackNumber
            ? _value.trackNumber
            : trackNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        discNumber: freezed == discNumber
            ? _value.discNumber
            : discNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        composer: freezed == composer
            ? _value.composer
            : composer // ignore: cast_nullable_to_non_nullable
                  as String?,
        lyrics: freezed == lyrics
            ? _value.lyrics
            : lyrics // ignore: cast_nullable_to_non_nullable
                  as String?,
        bitrate: freezed == bitrate
            ? _value.bitrate
            : bitrate // ignore: cast_nullable_to_non_nullable
                  as int?,
        fileSize: freezed == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int?,
        dateAdded: freezed == dateAdded
            ? _value.dateAdded
            : dateAdded // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastPlayed: freezed == lastPlayed
            ? _value.lastPlayed
            : lastPlayed // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        playCount: freezed == playCount
            ? _value.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        isFavorite: freezed == isFavorite
            ? _value.isFavorite
            : isFavorite // ignore: cast_nullable_to_non_nullable
                  as bool?,
        albumArtist: freezed == albumArtist
            ? _value.albumArtist
            : albumArtist // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SongImpl implements _Song {
  const _$SongImpl({
    required this.id,
    required this.title,
    required final List<String> artists,
    required final List<String> albums,
    final List<String>? myPlaylistIds,
    required this.path,
    @DurationConverter() required this.duration,
    this.albumArt,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.composer,
    this.lyrics,
    this.bitrate,
    this.fileSize,
    this.dateAdded,
    this.updatedAt,
    this.lastPlayed,
    this.playCount,
    this.isFavorite,
    this.albumArtist,
  }) : _artists = artists,
       _albums = albums,
       _myPlaylistIds = myPlaylistIds;

  factory _$SongImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  final List<String> _artists;
  @override
  List<String> get artists {
    if (_artists is EqualUnmodifiableListView) return _artists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artists);
  }

  final List<String> _albums;
  @override
  List<String> get albums {
    if (_albums is EqualUnmodifiableListView) return _albums;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_albums);
  }

  final List<String>? _myPlaylistIds;
  @override
  List<String>? get myPlaylistIds {
    final value = _myPlaylistIds;
    if (value == null) return null;
    if (_myPlaylistIds is EqualUnmodifiableListView) return _myPlaylistIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String path;
  @override
  @DurationConverter()
  final Duration duration;
  @override
  final String? albumArt;
  @override
  final String? genre;
  @override
  final int? year;
  @override
  final int? trackNumber;
  @override
  final int? discNumber;
  @override
  final String? composer;
  @override
  final String? lyrics;
  @override
  final int? bitrate;
  @override
  final int? fileSize;
  // changed from String? → int? (bytes)
  @override
  final DateTime? dateAdded;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? lastPlayed;
  @override
  final int? playCount;
  @override
  final bool? isFavorite;
  @override
  final String? albumArtist;

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artists: $artists, albums: $albums, myPlaylistIds: $myPlaylistIds, path: $path, duration: $duration, albumArt: $albumArt, genre: $genre, year: $year, trackNumber: $trackNumber, discNumber: $discNumber, composer: $composer, lyrics: $lyrics, bitrate: $bitrate, fileSize: $fileSize, dateAdded: $dateAdded, updatedAt: $updatedAt, lastPlayed: $lastPlayed, playCount: $playCount, isFavorite: $isFavorite, albumArtist: $albumArtist)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._artists, _artists) &&
            const DeepCollectionEquality().equals(other._albums, _albums) &&
            const DeepCollectionEquality().equals(
              other._myPlaylistIds,
              _myPlaylistIds,
            ) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.albumArt, albumArt) ||
                other.albumArt == albumArt) &&
            (identical(other.genre, genre) || other.genre == genre) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.trackNumber, trackNumber) ||
                other.trackNumber == trackNumber) &&
            (identical(other.discNumber, discNumber) ||
                other.discNumber == discNumber) &&
            (identical(other.composer, composer) ||
                other.composer == composer) &&
            (identical(other.lyrics, lyrics) || other.lyrics == lyrics) &&
            (identical(other.bitrate, bitrate) || other.bitrate == bitrate) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastPlayed, lastPlayed) ||
                other.lastPlayed == lastPlayed) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.albumArtist, albumArtist) ||
                other.albumArtist == albumArtist));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    const DeepCollectionEquality().hash(_artists),
    const DeepCollectionEquality().hash(_albums),
    const DeepCollectionEquality().hash(_myPlaylistIds),
    path,
    duration,
    albumArt,
    genre,
    year,
    trackNumber,
    discNumber,
    composer,
    lyrics,
    bitrate,
    fileSize,
    dateAdded,
    updatedAt,
    lastPlayed,
    playCount,
    isFavorite,
    albumArtist,
  ]);

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongImplCopyWith<_$SongImpl> get copyWith =>
      __$$SongImplCopyWithImpl<_$SongImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongImplToJson(this);
  }
}

abstract class _Song implements Song {
  const factory _Song({
    required final String id,
    required final String title,
    required final List<String> artists,
    required final List<String> albums,
    final List<String>? myPlaylistIds,
    required final String path,
    @DurationConverter() required final Duration duration,
    final String? albumArt,
    final String? genre,
    final int? year,
    final int? trackNumber,
    final int? discNumber,
    final String? composer,
    final String? lyrics,
    final int? bitrate,
    final int? fileSize,
    final DateTime? dateAdded,
    final DateTime? updatedAt,
    final DateTime? lastPlayed,
    final int? playCount,
    final bool? isFavorite,
    final String? albumArtist,
  }) = _$SongImpl;

  factory _Song.fromJson(Map<String, dynamic> json) = _$SongImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  List<String> get artists;
  @override
  List<String> get albums;
  @override
  List<String>? get myPlaylistIds;
  @override
  String get path;
  @override
  @DurationConverter()
  Duration get duration;
  @override
  String? get albumArt;
  @override
  String? get genre;
  @override
  int? get year;
  @override
  int? get trackNumber;
  @override
  int? get discNumber;
  @override
  String? get composer;
  @override
  String? get lyrics;
  @override
  int? get bitrate;
  @override
  int? get fileSize; // changed from String? → int? (bytes)
  @override
  DateTime? get dateAdded;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get lastPlayed;
  @override
  int? get playCount;
  @override
  bool? get isFavorite;
  @override
  String? get albumArtist;

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongImplCopyWith<_$SongImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Album _$AlbumFromJson(Map<String, dynamic> json) {
  return _Album.fromJson(json);
}

/// @nodoc
mixin _$Album {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String> get songIds => throw _privateConstructorUsedError; // normalized
  String? get coverImage => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get lastPlayed => throw _privateConstructorUsedError;
  String? get artistId => throw _privateConstructorUsedError; // link to Artist
  String? get genre => throw _privateConstructorUsedError;
  int? get year => throw _privateConstructorUsedError;
  int? get playCount => throw _privateConstructorUsedError;

  /// Serializes this Album to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Album
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlbumCopyWith<Album> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumCopyWith<$Res> {
  factory $AlbumCopyWith(Album value, $Res Function(Album) then) =
      _$AlbumCopyWithImpl<$Res, Album>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    List<String> songIds,
    String? coverImage,
    DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    String? artistId,
    String? genre,
    int? year,
    int? playCount,
  });
}

/// @nodoc
class _$AlbumCopyWithImpl<$Res, $Val extends Album>
    implements $AlbumCopyWith<$Res> {
  _$AlbumCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Album
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? songIds = null,
    Object? coverImage = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
    Object? artistId = freezed,
    Object? genre = freezed,
    Object? year = freezed,
    Object? playCount = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            songIds: null == songIds
                ? _value.songIds
                : songIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastPlayed: freezed == lastPlayed
                ? _value.lastPlayed
                : lastPlayed // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            artistId: freezed == artistId
                ? _value.artistId
                : artistId // ignore: cast_nullable_to_non_nullable
                      as String?,
            genre: freezed == genre
                ? _value.genre
                : genre // ignore: cast_nullable_to_non_nullable
                      as String?,
            year: freezed == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int?,
            playCount: freezed == playCount
                ? _value.playCount
                : playCount // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlbumImplCopyWith<$Res> implements $AlbumCopyWith<$Res> {
  factory _$$AlbumImplCopyWith(
    _$AlbumImpl value,
    $Res Function(_$AlbumImpl) then,
  ) = __$$AlbumImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    List<String> songIds,
    String? coverImage,
    DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    String? artistId,
    String? genre,
    int? year,
    int? playCount,
  });
}

/// @nodoc
class __$$AlbumImplCopyWithImpl<$Res>
    extends _$AlbumCopyWithImpl<$Res, _$AlbumImpl>
    implements _$$AlbumImplCopyWith<$Res> {
  __$$AlbumImplCopyWithImpl(
    _$AlbumImpl _value,
    $Res Function(_$AlbumImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Album
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? songIds = null,
    Object? coverImage = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
    Object? artistId = freezed,
    Object? genre = freezed,
    Object? year = freezed,
    Object? playCount = freezed,
  }) {
    return _then(
      _$AlbumImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        songIds: null == songIds
            ? _value._songIds
            : songIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastPlayed: freezed == lastPlayed
            ? _value.lastPlayed
            : lastPlayed // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        artistId: freezed == artistId
            ? _value.artistId
            : artistId // ignore: cast_nullable_to_non_nullable
                  as String?,
        genre: freezed == genre
            ? _value.genre
            : genre // ignore: cast_nullable_to_non_nullable
                  as String?,
        year: freezed == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int?,
        playCount: freezed == playCount
            ? _value.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AlbumImpl implements _Album {
  const _$AlbumImpl({
    required this.id,
    required this.name,
    this.description,
    required final List<String> songIds,
    this.coverImage,
    required this.createdAt,
    this.updatedAt,
    this.lastPlayed,
    this.artistId,
    this.genre,
    this.year,
    this.playCount,
  }) : _songIds = songIds;

  factory _$AlbumImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  final List<String> _songIds;
  @override
  List<String> get songIds {
    if (_songIds is EqualUnmodifiableListView) return _songIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_songIds);
  }

  // normalized
  @override
  final String? coverImage;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? lastPlayed;
  @override
  final String? artistId;
  // link to Artist
  @override
  final String? genre;
  @override
  final int? year;
  @override
  final int? playCount;

  @override
  String toString() {
    return 'Album(id: $id, name: $name, description: $description, songIds: $songIds, coverImage: $coverImage, createdAt: $createdAt, updatedAt: $updatedAt, lastPlayed: $lastPlayed, artistId: $artistId, genre: $genre, year: $year, playCount: $playCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._songIds, _songIds) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastPlayed, lastPlayed) ||
                other.lastPlayed == lastPlayed) &&
            (identical(other.artistId, artistId) ||
                other.artistId == artistId) &&
            (identical(other.genre, genre) || other.genre == genre) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    const DeepCollectionEquality().hash(_songIds),
    coverImage,
    createdAt,
    updatedAt,
    lastPlayed,
    artistId,
    genre,
    year,
    playCount,
  );

  /// Create a copy of Album
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumImplCopyWith<_$AlbumImpl> get copyWith =>
      __$$AlbumImplCopyWithImpl<_$AlbumImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumImplToJson(this);
  }
}

abstract class _Album implements Album {
  const factory _Album({
    required final String id,
    required final String name,
    final String? description,
    required final List<String> songIds,
    final String? coverImage,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final DateTime? lastPlayed,
    final String? artistId,
    final String? genre,
    final int? year,
    final int? playCount,
  }) = _$AlbumImpl;

  factory _Album.fromJson(Map<String, dynamic> json) = _$AlbumImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  List<String> get songIds; // normalized
  @override
  String? get coverImage;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get lastPlayed;
  @override
  String? get artistId; // link to Artist
  @override
  String? get genre;
  @override
  int? get year;
  @override
  int? get playCount;

  /// Create a copy of Album
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlbumImplCopyWith<_$AlbumImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

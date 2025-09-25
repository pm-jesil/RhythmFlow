// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Artist _$ArtistFromJson(Map<String, dynamic> json) {
  return _Artist.fromJson(json);
}

/// @nodoc
mixin _$Artist {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;
  List<String> get songIds => throw _privateConstructorUsedError; // normalized
  List<String>? get albumIds =>
      throw _privateConstructorUsedError; // link to Album
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get lastPlayed => throw _privateConstructorUsedError;
  int? get playCount => throw _privateConstructorUsedError;

  /// Serializes this Artist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Artist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtistCopyWith<Artist> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistCopyWith<$Res> {
  factory $ArtistCopyWith(Artist value, $Res Function(Artist) then) =
      _$ArtistCopyWithImpl<$Res, Artist>;
  @useResult
  $Res call({
    String id,
    String name,
    String? bio,
    String? image,
    List<String> songIds,
    List<String>? albumIds,
    DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    int? playCount,
  });
}

/// @nodoc
class _$ArtistCopyWithImpl<$Res, $Val extends Artist>
    implements $ArtistCopyWith<$Res> {
  _$ArtistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Artist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? bio = freezed,
    Object? image = freezed,
    Object? songIds = null,
    Object? albumIds = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
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
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            image: freezed == image
                ? _value.image
                : image // ignore: cast_nullable_to_non_nullable
                      as String?,
            songIds: null == songIds
                ? _value.songIds
                : songIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            albumIds: freezed == albumIds
                ? _value.albumIds
                : albumIds // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
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
abstract class _$$ArtistImplCopyWith<$Res> implements $ArtistCopyWith<$Res> {
  factory _$$ArtistImplCopyWith(
    _$ArtistImpl value,
    $Res Function(_$ArtistImpl) then,
  ) = __$$ArtistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? bio,
    String? image,
    List<String> songIds,
    List<String>? albumIds,
    DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    int? playCount,
  });
}

/// @nodoc
class __$$ArtistImplCopyWithImpl<$Res>
    extends _$ArtistCopyWithImpl<$Res, _$ArtistImpl>
    implements _$$ArtistImplCopyWith<$Res> {
  __$$ArtistImplCopyWithImpl(
    _$ArtistImpl _value,
    $Res Function(_$ArtistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Artist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? bio = freezed,
    Object? image = freezed,
    Object? songIds = null,
    Object? albumIds = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
    Object? playCount = freezed,
  }) {
    return _then(
      _$ArtistImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        image: freezed == image
            ? _value.image
            : image // ignore: cast_nullable_to_non_nullable
                  as String?,
        songIds: null == songIds
            ? _value._songIds
            : songIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        albumIds: freezed == albumIds
            ? _value._albumIds
            : albumIds // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
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
class _$ArtistImpl implements _Artist {
  const _$ArtistImpl({
    required this.id,
    required this.name,
    this.bio,
    this.image,
    required final List<String> songIds,
    final List<String>? albumIds,
    required this.createdAt,
    this.updatedAt,
    this.lastPlayed,
    this.playCount,
  }) : _songIds = songIds,
       _albumIds = albumIds;

  factory _$ArtistImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? bio;
  @override
  final String? image;
  final List<String> _songIds;
  @override
  List<String> get songIds {
    if (_songIds is EqualUnmodifiableListView) return _songIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_songIds);
  }

  // normalized
  final List<String>? _albumIds;
  // normalized
  @override
  List<String>? get albumIds {
    final value = _albumIds;
    if (value == null) return null;
    if (_albumIds is EqualUnmodifiableListView) return _albumIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  // link to Album
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? lastPlayed;
  @override
  final int? playCount;

  @override
  String toString() {
    return 'Artist(id: $id, name: $name, bio: $bio, image: $image, songIds: $songIds, albumIds: $albumIds, createdAt: $createdAt, updatedAt: $updatedAt, lastPlayed: $lastPlayed, playCount: $playCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.image, image) || other.image == image) &&
            const DeepCollectionEquality().equals(other._songIds, _songIds) &&
            const DeepCollectionEquality().equals(other._albumIds, _albumIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastPlayed, lastPlayed) ||
                other.lastPlayed == lastPlayed) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    bio,
    image,
    const DeepCollectionEquality().hash(_songIds),
    const DeepCollectionEquality().hash(_albumIds),
    createdAt,
    updatedAt,
    lastPlayed,
    playCount,
  );

  /// Create a copy of Artist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistImplCopyWith<_$ArtistImpl> get copyWith =>
      __$$ArtistImplCopyWithImpl<_$ArtistImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistImplToJson(this);
  }
}

abstract class _Artist implements Artist {
  const factory _Artist({
    required final String id,
    required final String name,
    final String? bio,
    final String? image,
    required final List<String> songIds,
    final List<String>? albumIds,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final DateTime? lastPlayed,
    final int? playCount,
  }) = _$ArtistImpl;

  factory _Artist.fromJson(Map<String, dynamic> json) = _$ArtistImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get bio;
  @override
  String? get image;
  @override
  List<String> get songIds; // normalized
  @override
  List<String>? get albumIds; // link to Album
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get lastPlayed;
  @override
  int? get playCount;

  /// Create a copy of Artist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistImplCopyWith<_$ArtistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

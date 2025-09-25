// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_playlist_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MyPlaylist _$MyPlaylistFromJson(Map<String, dynamic> json) {
  return _MyPlaylist.fromJson(json);
}

/// @nodoc
mixin _$MyPlaylist {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get songIds => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get lastPlayed => throw _privateConstructorUsedError;
  String? get coverImage => throw _privateConstructorUsedError;
  bool? get isPublic => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  int? get playCount => throw _privateConstructorUsedError;
  @DurationSecondsConverter()
  Duration? get totalDuration => throw _privateConstructorUsedError;

  /// Serializes this MyPlaylist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPlaylistCopyWith<MyPlaylist> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPlaylistCopyWith<$Res> {
  factory $MyPlaylistCopyWith(
    MyPlaylist value,
    $Res Function(MyPlaylist) then,
  ) = _$MyPlaylistCopyWithImpl<$Res, MyPlaylist>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    List<String> songIds,
    DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    String? coverImage,
    bool? isPublic,
    String? createdBy,
    int? playCount,
    @DurationSecondsConverter() Duration? totalDuration,
  });
}

/// @nodoc
class _$MyPlaylistCopyWithImpl<$Res, $Val extends MyPlaylist>
    implements $MyPlaylistCopyWith<$Res> {
  _$MyPlaylistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? songIds = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
    Object? coverImage = freezed,
    Object? isPublic = freezed,
    Object? createdBy = freezed,
    Object? playCount = freezed,
    Object? totalDuration = freezed,
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
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            songIds: null == songIds
                ? _value.songIds
                : songIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            isPublic: freezed == isPublic
                ? _value.isPublic
                : isPublic // ignore: cast_nullable_to_non_nullable
                      as bool?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            playCount: freezed == playCount
                ? _value.playCount
                : playCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalDuration: freezed == totalDuration
                ? _value.totalDuration
                : totalDuration // ignore: cast_nullable_to_non_nullable
                      as Duration?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MyPlaylistImplCopyWith<$Res>
    implements $MyPlaylistCopyWith<$Res> {
  factory _$$MyPlaylistImplCopyWith(
    _$MyPlaylistImpl value,
    $Res Function(_$MyPlaylistImpl) then,
  ) = __$$MyPlaylistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    List<String> songIds,
    DateTime createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    String? coverImage,
    bool? isPublic,
    String? createdBy,
    int? playCount,
    @DurationSecondsConverter() Duration? totalDuration,
  });
}

/// @nodoc
class __$$MyPlaylistImplCopyWithImpl<$Res>
    extends _$MyPlaylistCopyWithImpl<$Res, _$MyPlaylistImpl>
    implements _$$MyPlaylistImplCopyWith<$Res> {
  __$$MyPlaylistImplCopyWithImpl(
    _$MyPlaylistImpl _value,
    $Res Function(_$MyPlaylistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? songIds = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? lastPlayed = freezed,
    Object? coverImage = freezed,
    Object? isPublic = freezed,
    Object? createdBy = freezed,
    Object? playCount = freezed,
    Object? totalDuration = freezed,
  }) {
    return _then(
      _$MyPlaylistImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        songIds: null == songIds
            ? _value._songIds
            : songIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
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
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        isPublic: freezed == isPublic
            ? _value.isPublic
            : isPublic // ignore: cast_nullable_to_non_nullable
                  as bool?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        playCount: freezed == playCount
            ? _value.playCount
            : playCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalDuration: freezed == totalDuration
            ? _value.totalDuration
            : totalDuration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MyPlaylistImpl implements _MyPlaylist {
  const _$MyPlaylistImpl({
    required this.id,
    required this.name,
    required this.description,
    required final List<String> songIds,
    required this.createdAt,
    this.updatedAt,
    this.lastPlayed,
    this.coverImage,
    this.isPublic,
    this.createdBy,
    this.playCount,
    @DurationSecondsConverter() this.totalDuration,
  }) : _songIds = songIds;

  factory _$MyPlaylistImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyPlaylistImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  final List<String> _songIds;
  @override
  List<String> get songIds {
    if (_songIds is EqualUnmodifiableListView) return _songIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_songIds);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? lastPlayed;
  @override
  final String? coverImage;
  @override
  final bool? isPublic;
  @override
  final String? createdBy;
  @override
  final int? playCount;
  @override
  @DurationSecondsConverter()
  final Duration? totalDuration;

  @override
  String toString() {
    return 'MyPlaylist(id: $id, name: $name, description: $description, songIds: $songIds, createdAt: $createdAt, updatedAt: $updatedAt, lastPlayed: $lastPlayed, coverImage: $coverImage, isPublic: $isPublic, createdBy: $createdBy, playCount: $playCount, totalDuration: $totalDuration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPlaylistImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._songIds, _songIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastPlayed, lastPlayed) ||
                other.lastPlayed == lastPlayed) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    const DeepCollectionEquality().hash(_songIds),
    createdAt,
    updatedAt,
    lastPlayed,
    coverImage,
    isPublic,
    createdBy,
    playCount,
    totalDuration,
  );

  /// Create a copy of MyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPlaylistImplCopyWith<_$MyPlaylistImpl> get copyWith =>
      __$$MyPlaylistImplCopyWithImpl<_$MyPlaylistImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MyPlaylistImplToJson(this);
  }
}

abstract class _MyPlaylist implements MyPlaylist {
  const factory _MyPlaylist({
    required final String id,
    required final String name,
    required final String description,
    required final List<String> songIds,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final DateTime? lastPlayed,
    final String? coverImage,
    final bool? isPublic,
    final String? createdBy,
    final int? playCount,
    @DurationSecondsConverter() final Duration? totalDuration,
  }) = _$MyPlaylistImpl;

  factory _MyPlaylist.fromJson(Map<String, dynamic> json) =
      _$MyPlaylistImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<String> get songIds;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get lastPlayed;
  @override
  String? get coverImage;
  @override
  bool? get isPublic;
  @override
  String? get createdBy;
  @override
  int? get playCount;
  @override
  @DurationSecondsConverter()
  Duration? get totalDuration;

  /// Create a copy of MyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPlaylistImplCopyWith<_$MyPlaylistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

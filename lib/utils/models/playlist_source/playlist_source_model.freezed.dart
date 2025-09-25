// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_source_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlaylistSource _$PlaylistSourceFromJson(Map<String, dynamic> json) {
  return _PlaylistSource.fromJson(json);
}

/// @nodoc
mixin _$PlaylistSource {
  String get source => throw _privateConstructorUsedError;
  String? get albumId => throw _privateConstructorUsedError;
  String? get artistId => throw _privateConstructorUsedError;
  String? get playlistId => throw _privateConstructorUsedError;

  /// Serializes this PlaylistSource to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistSourceCopyWith<PlaylistSource> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistSourceCopyWith<$Res> {
  factory $PlaylistSourceCopyWith(
    PlaylistSource value,
    $Res Function(PlaylistSource) then,
  ) = _$PlaylistSourceCopyWithImpl<$Res, PlaylistSource>;
  @useResult
  $Res call({
    String source,
    String? albumId,
    String? artistId,
    String? playlistId,
  });
}

/// @nodoc
class _$PlaylistSourceCopyWithImpl<$Res, $Val extends PlaylistSource>
    implements $PlaylistSourceCopyWith<$Res> {
  _$PlaylistSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? albumId = freezed,
    Object? artistId = freezed,
    Object? playlistId = freezed,
  }) {
    return _then(
      _value.copyWith(
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            albumId: freezed == albumId
                ? _value.albumId
                : albumId // ignore: cast_nullable_to_non_nullable
                      as String?,
            artistId: freezed == artistId
                ? _value.artistId
                : artistId // ignore: cast_nullable_to_non_nullable
                      as String?,
            playlistId: freezed == playlistId
                ? _value.playlistId
                : playlistId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaylistSourceImplCopyWith<$Res>
    implements $PlaylistSourceCopyWith<$Res> {
  factory _$$PlaylistSourceImplCopyWith(
    _$PlaylistSourceImpl value,
    $Res Function(_$PlaylistSourceImpl) then,
  ) = __$$PlaylistSourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String source,
    String? albumId,
    String? artistId,
    String? playlistId,
  });
}

/// @nodoc
class __$$PlaylistSourceImplCopyWithImpl<$Res>
    extends _$PlaylistSourceCopyWithImpl<$Res, _$PlaylistSourceImpl>
    implements _$$PlaylistSourceImplCopyWith<$Res> {
  __$$PlaylistSourceImplCopyWithImpl(
    _$PlaylistSourceImpl _value,
    $Res Function(_$PlaylistSourceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? albumId = freezed,
    Object? artistId = freezed,
    Object? playlistId = freezed,
  }) {
    return _then(
      _$PlaylistSourceImpl(
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        albumId: freezed == albumId
            ? _value.albumId
            : albumId // ignore: cast_nullable_to_non_nullable
                  as String?,
        artistId: freezed == artistId
            ? _value.artistId
            : artistId // ignore: cast_nullable_to_non_nullable
                  as String?,
        playlistId: freezed == playlistId
            ? _value.playlistId
            : playlistId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistSourceImpl implements _PlaylistSource {
  const _$PlaylistSourceImpl({
    required this.source,
    this.albumId,
    this.artistId,
    this.playlistId,
  });

  factory _$PlaylistSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistSourceImplFromJson(json);

  @override
  final String source;
  @override
  final String? albumId;
  @override
  final String? artistId;
  @override
  final String? playlistId;

  @override
  String toString() {
    return 'PlaylistSource(source: $source, albumId: $albumId, artistId: $artistId, playlistId: $playlistId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistSourceImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.albumId, albumId) || other.albumId == albumId) &&
            (identical(other.artistId, artistId) ||
                other.artistId == artistId) &&
            (identical(other.playlistId, playlistId) ||
                other.playlistId == playlistId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, source, albumId, artistId, playlistId);

  /// Create a copy of PlaylistSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistSourceImplCopyWith<_$PlaylistSourceImpl> get copyWith =>
      __$$PlaylistSourceImplCopyWithImpl<_$PlaylistSourceImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistSourceImplToJson(this);
  }
}

abstract class _PlaylistSource implements PlaylistSource {
  const factory _PlaylistSource({
    required final String source,
    final String? albumId,
    final String? artistId,
    final String? playlistId,
  }) = _$PlaylistSourceImpl;

  factory _PlaylistSource.fromJson(Map<String, dynamic> json) =
      _$PlaylistSourceImpl.fromJson;

  @override
  String get source;
  @override
  String? get albumId;
  @override
  String? get artistId;
  @override
  String? get playlistId;

  /// Create a copy of PlaylistSource
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistSourceImplCopyWith<_$PlaylistSourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

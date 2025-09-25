// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_source_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaylistSourceImpl _$$PlaylistSourceImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistSourceImpl(
      source: json['source'] as String,
      albumId: json['albumId'] as String?,
      artistId: json['artistId'] as String?,
      playlistId: json['playlistId'] as String?,
    );

Map<String, dynamic> _$$PlaylistSourceImplToJson(
  _$PlaylistSourceImpl instance,
) => <String, dynamic>{
  'source': instance.source,
  'albumId': instance.albumId,
  'artistId': instance.artistId,
  'playlistId': instance.playlistId,
};

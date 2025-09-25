// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistImpl _$$ArtistImplFromJson(Map<String, dynamic> json) => _$ArtistImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  bio: json['bio'] as String?,
  image: json['image'] as String?,
  songIds: (json['songIds'] as List<dynamic>).map((e) => e as String).toList(),
  albumIds: (json['albumIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  lastPlayed: json['lastPlayed'] == null
      ? null
      : DateTime.parse(json['lastPlayed'] as String),
  playCount: (json['playCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$$ArtistImplToJson(_$ArtistImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'bio': instance.bio,
      'image': instance.image,
      'songIds': instance.songIds,
      'albumIds': instance.albumIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastPlayed': instance.lastPlayed?.toIso8601String(),
      'playCount': instance.playCount,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlbumImpl _$$AlbumImplFromJson(Map<String, dynamic> json) => _$AlbumImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  songIds: (json['songIds'] as List<dynamic>).map((e) => e as String).toList(),
  coverImage: json['coverImage'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  lastPlayed: json['lastPlayed'] == null
      ? null
      : DateTime.parse(json['lastPlayed'] as String),
  artistId: json['artistId'] as String?,
  genre: json['genre'] as String?,
  year: (json['year'] as num?)?.toInt(),
  playCount: (json['playCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$$AlbumImplToJson(_$AlbumImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'songIds': instance.songIds,
      'coverImage': instance.coverImage,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastPlayed': instance.lastPlayed?.toIso8601String(),
      'artistId': instance.artistId,
      'genre': instance.genre,
      'year': instance.year,
      'playCount': instance.playCount,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_playlist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MyPlaylistImpl _$$MyPlaylistImplFromJson(Map<String, dynamic> json) =>
    _$MyPlaylistImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      songIds: (json['songIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      lastPlayed: json['lastPlayed'] == null
          ? null
          : DateTime.parse(json['lastPlayed'] as String),
      coverImage: json['coverImage'] as String?,
      isPublic: json['isPublic'] as bool?,
      createdBy: json['createdBy'] as String?,
      playCount: (json['playCount'] as num?)?.toInt(),
      totalDuration: const DurationSecondsConverter().fromJson(
        (json['totalDuration'] as num?)?.toInt(),
      ),
    );

Map<String, dynamic> _$$MyPlaylistImplToJson(_$MyPlaylistImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'songIds': instance.songIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastPlayed': instance.lastPlayed?.toIso8601String(),
      'coverImage': instance.coverImage,
      'isPublic': instance.isPublic,
      'createdBy': instance.createdBy,
      'playCount': instance.playCount,
      'totalDuration': const DurationSecondsConverter().toJson(
        instance.totalDuration,
      ),
    };

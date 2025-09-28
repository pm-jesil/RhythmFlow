// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongImpl _$$SongImplFromJson(Map<String, dynamic> json) => _$SongImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  artists: (json['artists'] as List<dynamic>).map((e) => e as String).toList(),
  albums: (json['albums'] as List<dynamic>).map((e) => e as String).toList(),
  myPlaylistIds: (json['myPlaylistIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  path: json['path'] as String,
  duration: const DurationConverter().fromJson(
    (json['duration'] as num).toInt(),
  ),
  albumArt: json['albumArt'] as String?,
  genre: json['genre'] as String?,
  year: (json['year'] as num?)?.toInt(),
  trackNumber: (json['trackNumber'] as num?)?.toInt(),
  discNumber: (json['discNumber'] as num?)?.toInt(),
  composer: json['composer'] as String?,
  lyrics: json['lyrics'] as String?,
  bitrate: (json['bitrate'] as num?)?.toInt(),
  fileSize: (json['fileSize'] as num?)?.toInt(),
  dateAdded: json['dateAdded'] == null
      ? null
      : DateTime.parse(json['dateAdded'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  lastPlayed: json['lastPlayed'] == null
      ? null
      : DateTime.parse(json['lastPlayed'] as String),
  playCount: (json['playCount'] as num?)?.toInt(),
  isFavorite: json['isFavorite'] as bool?,
  albumArtist: json['albumArtist'] as String?,
);

Map<String, dynamic> _$$SongImplToJson(_$SongImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artists': instance.artists,
      'albums': instance.albums,
      'myPlaylistIds': instance.myPlaylistIds,
      'path': instance.path,
      'duration': const DurationConverter().toJson(instance.duration),
      'albumArt': instance.albumArt,
      'genre': instance.genre,
      'year': instance.year,
      'trackNumber': instance.trackNumber,
      'discNumber': instance.discNumber,
      'composer': instance.composer,
      'lyrics': instance.lyrics,
      'bitrate': instance.bitrate,
      'fileSize': instance.fileSize,
      'dateAdded': instance.dateAdded?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastPlayed': instance.lastPlayed?.toIso8601String(),
      'playCount': instance.playCount,
      'isFavorite': instance.isFavorite,
      'albumArtist': instance.albumArtist,
    };

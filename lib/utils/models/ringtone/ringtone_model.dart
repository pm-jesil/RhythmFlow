/// Which system sound a ringtone can be set as.
enum RingtoneUse { ringtone, notification, alarm }

extension RingtoneUseLabel on RingtoneUse {
  String get label => switch (this) {
    RingtoneUse.ringtone => 'Ringtone',
    RingtoneUse.notification => 'Notification',
    RingtoneUse.alarm => 'Alarm',
  };
}

/// A ringtone the user cut from a song.
class RingtoneItem {
  final String id;
  final String name;

  /// File on disk (may be empty on Android 10+ when only [uri] is known).
  final String path;

  /// `content://` uri on Android (used to set the default ringtone).
  final String? uri;

  final String sourceSongId;
  final String songTitle;
  final String artist;
  final String? albumArt;
  final int startMs;
  final int endMs;
  final int createdAtMs;
  final bool fromOnline;

  const RingtoneItem({
    required this.id,
    required this.name,
    required this.path,
    this.uri,
    required this.sourceSongId,
    required this.songTitle,
    required this.artist,
    this.albumArt,
    required this.startMs,
    required this.endMs,
    required this.createdAtMs,
    this.fromOnline = false,
  });

  Duration get duration => Duration(milliseconds: endMs - startMs);
  Duration get start => Duration(milliseconds: startMs);
  Duration get end => Duration(milliseconds: endMs);
  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  String get extension {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  }

  RingtoneItem copyWith({String? name, String? path, String? uri}) => RingtoneItem(
    id: id,
    name: name ?? this.name,
    path: path ?? this.path,
    uri: uri ?? this.uri,
    sourceSongId: sourceSongId,
    songTitle: songTitle,
    artist: artist,
    albumArt: albumArt,
    startMs: startMs,
    endMs: endMs,
    createdAtMs: createdAtMs,
    fromOnline: fromOnline,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'uri': uri,
    'sourceSongId': sourceSongId,
    'songTitle': songTitle,
    'artist': artist,
    'albumArt': albumArt,
    'startMs': startMs,
    'endMs': endMs,
    'createdAtMs': createdAtMs,
    'fromOnline': fromOnline,
  };

  factory RingtoneItem.fromJson(Map<String, dynamic> json) => RingtoneItem(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Ringtone',
    path: json['path'] as String? ?? '',
    uri: json['uri'] as String?,
    sourceSongId: json['sourceSongId'] as String? ?? '',
    songTitle: json['songTitle'] as String? ?? '',
    artist: json['artist'] as String? ?? '',
    albumArt: json['albumArt'] as String?,
    startMs: (json['startMs'] as num?)?.toInt() ?? 0,
    endMs: (json['endMs'] as num?)?.toInt() ?? 0,
    createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    fromOnline: json['fromOnline'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is RingtoneItem &&
      other.id == id &&
      other.name == name &&
      other.path == path &&
      other.uri == uri;

  @override
  int get hashCode => Object.hash(id, name, path, uri);
}

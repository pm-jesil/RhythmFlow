import '../../models/album/album_model.dart';
import '../../models/artist/artist_model.dart';
import '../../models/song/song_model.dart';

/// One page of results.
class JamendoPage<T> {
  final List<T> items;
  final int offset;
  final bool hasMore;

  const JamendoPage({
    required this.items,
    required this.offset,
    required this.hasMore,
  });

  int get nextOffset => offset + items.length;

  static JamendoPage<T> empty<T>() =>
      JamendoPage<T>(items: const [], offset: 0, hasMore: false);
}

/// A Jamendo radio station (live stream).
class JamendoRadio {
  final String id;
  final String name;
  final String displayName;
  final String image;

  const JamendoRadio({
    required this.id,
    required this.name,
    required this.displayName,
    required this.image,
  });

  factory JamendoRadio.fromJson(Map<String, dynamic> json) => JamendoRadio(
    id: JamendoMapper.str(json['id']),
    name: JamendoMapper.str(json['name']),
    displayName: JamendoMapper.str(json['dispname'] ?? json['name']),
    image: JamendoMapper.str(json['image']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dispname': displayName,
    'image': image,
  };

  /// A playable song for this station (stream URL resolved separately).
  Song toSong({String? streamUrl}) => Song(
    id: JamendoMapper.radioSongId(id),
    title: displayName,
    artists: const ['Jamendo Radio'],
    albums: const ['Live radio'],
    path: 'jamendo://radio/$id',
    duration: Duration.zero,
    albumArt: image.isEmpty ? null : image,
    source: SongSources.jamendoRadio,
    remoteId: id,
    streamUrl: streamUrl,
    shareUrl: 'https://www.jamendo.com/radios',
    playCount: 0,
    isFavorite: false,
  );
}

/// A curated "mix": Jamendo's featured chart of a genre or a mood.
class JamendoMix {
  final String id;
  final String title;
  final String subtitle;
  final String tag;
  final bool featured;

  const JamendoMix({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.featured = true,
  });

  static String titleFor(String tag) {
    const special = {
      'hiphop': 'Hip Hop',
      'songwriter': 'Singer-Songwriter',
      'world': 'World Music',
      'relaxation': 'Relax',
    };
    final base = special[tag] ?? '${tag[0].toUpperCase()}${tag.substring(1)}';
    return '$base Mix';
  }
}

/// Converts raw Jamendo JSON into the app's models.
///
/// Jamendo is inconsistent: top-level tracks use numbers (`"duration": 216`)
/// while tracks nested in albums/artists use strings (`"duration": "218"`).
/// Every reader here accepts both.
class JamendoMapper {
  JamendoMapper._();

  static const String songIdPrefix = 'jm_';
  static const String radioIdPrefix = 'jmr_';
  static const String albumIdPrefix = 'jm_album_';
  static const String artistIdPrefix = 'jm_artist_';

  static String songId(String remoteId) => '$songIdPrefix$remoteId';
  static String radioSongId(String remoteId) => '$radioIdPrefix$remoteId';
  static String albumId(String remoteId) => '$albumIdPrefix$remoteId';
  static String artistId(String remoteId) => '$artistIdPrefix$remoteId';

  static bool isOnlineSongId(String id) =>
      id.startsWith(songIdPrefix) || id.startsWith(radioIdPrefix);

  /// Remote id of an online song id (`jm_123` -> `123`).
  static String? remoteIdOf(String songId) {
    if (songId.startsWith(radioIdPrefix)) {
      return songId.substring(radioIdPrefix.length);
    }
    if (songId.startsWith(songIdPrefix)) {
      return songId.substring(songIdPrefix.length);
    }
    return null;
  }

  static String str(Object? v) => v == null ? '' : v.toString();

  static int toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(str(v)) ?? 0;
  }

  static bool toBool(Object? v) {
    if (v is bool) return v;
    final s = str(v).toLowerCase();
    return s == 'true' || s == '1';
  }

  static DateTime? toDate(Object? v) {
    final s = str(v);
    if (s.isEmpty || s.startsWith('0000')) return null;
    return DateTime.tryParse(s);
  }

  static String? nonEmpty(Object? v) {
    final s = str(v);
    return s.isEmpty ? null : s;
  }

  /// Decodes HTML entities that Jamendo leaves in names (`&amp;`, `&#039;`).
  static String clean(Object? v) {
    var s = str(v);
    if (!s.contains('&')) return s.trim();
    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return s.trim();
  }

  /// A Jamendo track (top level or nested). [album] / [artist] fill fields
  /// that nested tracks do not repeat.
  static Song track(
    Map<String, dynamic> json, {
    Map<String, dynamic>? album,
    Map<String, dynamic>? artist,
  }) {
    final id = str(json['id']);
    final artistName = clean(
      json['artist_name'] ?? album?['artist_name'] ?? artist?['name'],
    );
    final albumName = clean(json['album_name'] ?? album?['name']);
    final image =
        nonEmpty(json['image']) ??
        nonEmpty(json['album_image']) ??
        nonEmpty(album?['image']) ??
        nonEmpty(artist?['image']);
    final release = toDate(json['releasedate'] ?? album?['releasedate']);
    final musicInfo = json['musicinfo'];
    String? genre;
    if (musicInfo is Map) {
      final tags = musicInfo['tags'];
      if (tags is Map && tags['genres'] is List && (tags['genres'] as List).isNotEmpty) {
        genre = str((tags['genres'] as List).first);
      }
    }
    final title = clean(json['name']);
    return Song(
      id: songId(id),
      title: title.isEmpty ? 'Untitled' : title,
      artists: [artistName.isEmpty ? 'Unknown Artist' : artistName],
      albums: [albumName.isEmpty ? 'Single' : albumName],
      path: 'jamendo://track/$id',
      duration: Duration(seconds: toInt(json['duration'])),
      albumArt: image,
      genre: genre,
      year: release?.year,
      trackNumber: toInt(json['position']) == 0 ? null : toInt(json['position']),
      dateAdded: release,
      playCount: 0,
      isFavorite: false,
      albumArtist: artistName.isEmpty ? null : artistName,
      source: SongSources.jamendo,
      remoteId: id,
      remoteArtistId: nonEmpty(json['artist_id'] ?? album?['artist_id'] ?? artist?['id']),
      streamUrl: nonEmpty(json['audio']),
      downloadUrl: nonEmpty(json['audiodownload']),
      downloadAllowed: toBool(json['audiodownload_allowed']),
      licenseUrl: nonEmpty(json['license_ccurl']),
      shareUrl: nonEmpty(json['shareurl']),
    );
  }

  static Album album(Map<String, dynamic> json, {List<String> songIds = const []}) {
    final id = str(json['id']);
    final release = toDate(json['releasedate']);
    final artistName = clean(json['artist_name']);
    return Album(
      id: albumId(id),
      name: clean(json['name']),
      description: artistName,
      songIds: songIds,
      coverImage: nonEmpty(json['image']),
      createdAt: release ?? DateTime.fromMillisecondsSinceEpoch(0),
      artistId: nonEmpty(json['artist_id']) == null
          ? null
          : artistId(str(json['artist_id'])),
      year: release?.year,
      source: SongSources.jamendo,
      remoteId: id,
      artistName: artistName.isEmpty ? null : artistName,
      shareUrl: nonEmpty(json['shareurl']),
    );
  }

  static Artist artist(Map<String, dynamic> json, {List<String> songIds = const []}) {
    final id = str(json['id']);
    return Artist(
      id: artistId(id),
      name: clean(json['name']),
      image: nonEmpty(json['image']),
      songIds: songIds,
      createdAt: toDate(json['joindate']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      source: SongSources.jamendo,
      remoteId: id,
      shareUrl: nonEmpty(json['shareurl']),
      website: nonEmpty(json['website']),
    );
  }

  /// Tracks nested in `/albums/tracks` results.
  static List<Song> albumTracks(Map<String, dynamic> albumJson) {
    final tracks = albumJson['tracks'];
    if (tracks is! List) return const [];
    return tracks
        .whereType<Map>()
        .map((t) => track(Map<String, dynamic>.from(t), album: albumJson))
        .toList();
  }

  /// Tracks nested in `/artists/tracks` results.
  static List<Song> artistTracks(Map<String, dynamic> artistJson) {
    final tracks = artistJson['tracks'];
    if (tracks is! List) return const [];
    return tracks
        .whereType<Map>()
        .map((t) => track(Map<String, dynamic>.from(t), artist: artistJson))
        .toList();
  }

  /// Removes duplicate songs (same id) keeping the first.
  static List<Song> dedupe(Iterable<Song> songs) {
    final seen = <String>{};
    return [
      for (final s in songs)
        if (seen.add(s.id)) s,
    ];
  }
}

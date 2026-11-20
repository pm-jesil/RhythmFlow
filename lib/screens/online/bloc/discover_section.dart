import '../../../utils/models/album/album_model.dart';
import '../../../utils/models/artist/artist_model.dart';
import '../../../utils/models/song/song_model.dart';
import '../../../utils/services/jamendo/jamendo_api_client.dart';
import '../../../utils/services/jamendo/jamendo_models.dart';

/// Kinds of content a Discover home section shows.
enum DiscoverSectionKind { tracks, albums, artists, mixes, radios }

enum SectionStatus { idle, loading, success, error }

/// Ids of the Discover home sections (also their display order).
class DiscoverSectionIds {
  DiscoverSectionIds._();
  static const String country = 'country';
  static const String language = 'language';
  static const String trending = 'trending';
  static const String newReleases = 'new_releases';
  static const String mixes = 'mixes';
  static const String artists = 'artists';
  static const String radio = 'radio';

  static const List<String> order = [
    country,
    language,
    trending,
    newReleases,
    mixes,
    artists,
    radio,
  ];
}

/// One horizontal row on Discover home.
class DiscoverSection {
  final String id;
  final String title;
  final String subtitle;
  final DiscoverSectionKind kind;
  final SectionStatus status;
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<JamendoMix> mixes;
  final List<JamendoRadio> radios;
  final JamendoErrorKind? error;
  final DateTime? fetchedAt;

  const DiscoverSection({
    required this.id,
    required this.title,
    required this.kind,
    this.subtitle = '',
    this.status = SectionStatus.idle,
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.mixes = const [],
    this.radios = const [],
    this.error,
    this.fetchedAt,
  });

  bool get isLoading => status == SectionStatus.loading;
  bool get hasError => status == SectionStatus.error;

  int get itemCount => switch (kind) {
    DiscoverSectionKind.tracks => songs.length,
    DiscoverSectionKind.albums => albums.length,
    DiscoverSectionKind.artists => artists.length,
    DiscoverSectionKind.mixes => mixes.length,
    DiscoverSectionKind.radios => radios.length,
  };

  bool get isEmpty => itemCount == 0;

  DiscoverSection copyWith({
    String? title,
    String? subtitle,
    SectionStatus? status,
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    List<JamendoMix>? mixes,
    List<JamendoRadio>? radios,
    JamendoErrorKind? error,
    bool clearError = false,
    DateTime? fetchedAt,
  }) {
    return DiscoverSection(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      kind: kind,
      status: status ?? this.status,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      mixes: mixes ?? this.mixes,
      radios: radios ?? this.radios,
      error: clearError ? null : (error ?? this.error),
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'kind': kind.name,
    'songs': songs.map((s) => s.toJson()).toList(),
    'albums': albums.map((a) => a.toJson()).toList(),
    'artists': artists.map((a) => a.toJson()).toList(),
    'radios': radios.map((r) => r.toJson()).toList(),
    'fetchedAt': fetchedAt?.toIso8601String(),
  };

  /// Restored sections are shown as successful content (refreshed in the
  /// background on the next load).
  static DiscoverSection fromJson(
    Map<String, dynamic> json, {
    List<JamendoMix> mixes = const [],
  }) {
    List<Map<String, dynamic>> maps(Object? v) => v is List
        ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];
    final kind = DiscoverSectionKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => DiscoverSectionKind.tracks,
    );
    return DiscoverSection(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      kind: kind,
      status: SectionStatus.success,
      songs: maps(json['songs']).map(Song.fromJson).toList(),
      albums: maps(json['albums']).map(Album.fromJson).toList(),
      artists: maps(json['artists']).map(Artist.fromJson).toList(),
      radios: maps(json['radios']).map(JamendoRadio.fromJson).toList(),
      mixes: kind == DiscoverSectionKind.mixes ? mixes : const [],
      fetchedAt: json['fetchedAt'] == null
          ? null
          : DateTime.tryParse(json['fetchedAt'] as String),
    );
  }
}

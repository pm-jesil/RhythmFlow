import '../../logger/logger.dart';
import '../../models/album/album_model.dart';
import '../../models/artist/artist_model.dart';
import '../../models/song/song_model.dart';
import 'jamendo_api_client.dart';
import 'jamendo_cache.dart';
import 'jamendo_config.dart';
import 'jamendo_models.dart';
import 'region_models.dart';

/// Ordering used by the online tabs.
enum OnlineSort { popular, newest }

/// High-level access to Jamendo for Discover.
///
/// Every request goes through the cache: fresh entries are served without a
/// network call; when the network fails an expired entry is returned instead
/// (offline mode); otherwise the [JamendoException] is rethrown.
class JamendoRepository {
  static final AppLogger _logger = AppLogger('JamendoRepository');

  final JamendoApiClient client;
  final JamendoCache cache;
  final DateTime Function() _now;

  /// Signed stream URLs by remote track id, with the time they were fetched.
  final Map<String, (String, DateTime)> _streamUrls = {};

  /// Set when the last response came from the stale cache (offline).
  bool lastResponseWasStale = false;

  JamendoRepository({
    JamendoApiClient? client,
    JamendoCache? cache,
    DateTime Function()? now,
  }) : client = client ?? JamendoApiClient(),
       cache = cache ?? JamendoCache(),
       _now = now ?? DateTime.now;

  // Note: `include=musicinfo` makes Jamendo return empty results much more
  // often, so it is not requested.
  static const Map<String, Object?> _trackDefaults = {
    'audioformat': JamendoConfig.audioFormat,
    'imagesize': JamendoConfig.imageSize,
  };

  // ==================== CORE ====================

  Future<JamendoResponse> _get(
    String endpoint,
    Map<String, Object?> params, {
    required Duration ttl,
    bool forceRefresh = false,
  }) async {
    final key = cacheKey(endpoint, params);
    if (!forceRefresh) {
      final fresh = cache.read(key, maxAge: ttl);
      if (fresh != null) {
        lastResponseWasStale = false;
        return fresh;
      }
    }
    try {
      final response = await client.get(endpoint, params);
      if (response.results.isEmpty) {
        // Jamendo sometimes returns empty pages for valid queries: keep the
        // last good data instead of replacing it with nothing.
        final stale = cache.read(key);
        if (stale != null && stale.results.isNotEmpty) {
          lastResponseWasStale = false;
          return stale;
        }
        lastResponseWasStale = false;
        return response;
      }
      await cache.write(key, response);
      lastResponseWasStale = false;
      return response;
    } on JamendoException catch (e) {
      if (e.kind == JamendoErrorKind.notConfigured) rethrow;
      final stale = cache.read(key);
      if (stale != null) {
        _logger.i('📦 Serving stale cache for $endpoint (${e.kind})');
        lastResponseWasStale = true;
        return JamendoResponse(
          stale.results,
          next: stale.next,
          fromStaleCache: true,
        );
      }
      rethrow;
    }
  }

  /// Stable cache key (parameter order independent).
  static String cacheKey(String endpoint, Map<String, Object?> params) {
    final keys = params.keys.toList()..sort();
    final parts = keys.map((k) {
      final v = params[k];
      final text = v is Iterable ? v.join(' ') : '${v ?? ''}';
      return '$k=$text';
    });
    return '$endpoint?${parts.join('&')}';
  }

  JamendoPage<T> _page<T>(
    List<T> items,
    JamendoResponse response,
    int offset,
    int limit,
  ) {
    final hasMore = response.next != null || response.results.length >= limit;
    return JamendoPage(items: items, offset: offset, hasMore: hasMore && items.isNotEmpty);
  }

  // ==================== TRACKS ====================

  Future<JamendoPage<Song>> tracks({
    OnlineSort sort = OnlineSort.popular,
    String? tag,
    String? search,
    int offset = 0,
    int limit = JamendoConfig.pageSize,
    bool forceRefresh = false,
  }) async {
    final hasSearch = search != null && search.trim().isNotEmpty;
    final params = <String, Object?>{
      ..._trackDefaults,
      'limit': limit,
      'offset': offset,
      ...trackSortParams(
        sort: sort,
        hasSearch: hasSearch,
        hasTag: tag != null && tag.isNotEmpty,
      ),
      if (hasSearch) 'search': search.trim(),
      if (tag != null && tag.isNotEmpty) 'fuzzytags': tag,
    };
    final response = await _get(
      'tracks',
      params,
      ttl: hasSearch ? JamendoConfig.searchTtl : JamendoConfig.listTtl,
      forceRefresh: forceRefresh,
    );
    final songs = JamendoMapper.dedupe(response.results.map(JamendoMapper.track));
    _rememberStreams(songs);
    return _page(songs, response, offset, limit);
  }

  /// Ranking parameters that Jamendo actually honours (measured on the live
  /// API): `search` must not be combined with `order`/`boost`; filters such
  /// as `fuzzytags` only work with `boost`, not with `order=popularity_*`;
  /// "newest" needs `order=releasedate_desc` plus a `boost`.
  static Map<String, Object?> trackSortParams({
    required OnlineSort sort,
    required bool hasSearch,
    required bool hasTag,
  }) {
    if (hasSearch) return const {};
    if (sort == OnlineSort.newest) {
      return const {'order': 'releasedate_desc', 'boost': 'popularity_month'};
    }
    return hasTag
        ? const {'boost': 'popularity_week'}
        : const {'order': 'popularity_week'};
  }

  /// Jamendo's featured chart for a genre (or a fuzzy mood tag).
  Future<List<Song>> mixTracks(
    String tag, {
    int limit = JamendoConfig.sectionSize,
    bool forceRefresh = false,
  }) async {
    final featured = JamendoConfig.featuredGenres.contains(tag);
    final response = await _get(
      'tracks',
      {
        ..._trackDefaults,
        'limit': limit,
        if (featured) ...{'tags': tag, 'featured': 1} else 'fuzzytags': tag,
        'groupby': 'artist_id',
        'boost': 'popularity_month',
      },
      ttl: JamendoConfig.homeTtl,
      forceRefresh: forceRefresh,
    );
    var songs = response.results.map(JamendoMapper.track).toList();
    if (songs.isEmpty && featured) {
      // A featured chart can be empty; fall back to the plain tag.
      final fallback = await _get(
        'tracks',
        {
          ..._trackDefaults,
          'limit': limit,
          'tags': tag,
          'groupby': 'artist_id',
          'boost': 'popularity_month',
        },
        ttl: JamendoConfig.homeTtl,
        forceRefresh: forceRefresh,
      );
      songs = fallback.results.map(JamendoMapper.track).toList();
    }
    songs = JamendoMapper.dedupe(songs);
    _rememberStreams(songs);
    return songs;
  }

  Future<List<Song>> tracksByIds(List<String> remoteIds) async {
    if (remoteIds.isEmpty) return const [];
    final response = await _get(
      'tracks',
      {..._trackDefaults, 'id': remoteIds, 'limit': remoteIds.length},
      ttl: JamendoConfig.listTtl,
    );
    final songs = response.results.map(JamendoMapper.track).toList();
    _rememberStreams(songs);
    return songs;
  }

  /// Popular tracks by artists located in [alpha3Countries].
  Future<List<Song>> tracksFromCountries(
    List<String> alpha3Countries, {
    int limit = JamendoConfig.sectionSize,
    bool forceRefresh = false,
  }) async {
    final artistIds = <String>[];
    for (final country in alpha3Countries) {
      final artists = await _get(
        'artists/locations',
        // `order` on this endpoint cuts results to a handful; keep default.
        {'location_country': country, 'limit': 40},
        ttl: JamendoConfig.homeTtl,
        forceRefresh: forceRefresh,
      );
      for (final a in artists.results) {
        final id = JamendoMapper.str(a['id']);
        if (id.isNotEmpty && !artistIds.contains(id)) artistIds.add(id);
      }
    }
    if (artistIds.isEmpty) return const [];
    final response = await _get(
      'tracks',
      {
        ..._trackDefaults,
        'artist_id': artistIds.take(40).toList(),
        'boost': 'popularity_total',
        'limit': 100,
      },
      ttl: JamendoConfig.homeTtl,
      forceRefresh: forceRefresh,
    );
    // `groupby=artist_id` returns almost nothing here, so variety is
    // enforced client side: at most 2 tracks per artist.
    final songs = limitPerArtist(
      JamendoMapper.dedupe(response.results.map(JamendoMapper.track)),
      perArtist: 2,
    ).take(limit).toList();
    _rememberStreams(songs);
    return songs;
  }

  /// Keeps at most [perArtist] songs of each artist, preserving order.
  static List<Song> limitPerArtist(Iterable<Song> songs, {int perArtist = 2}) {
    final counts = <String, int>{};
    return [
      for (final s in songs)
        if ((counts[s.artists.first] = (counts[s.artists.first] ?? 0) + 1) <=
            perArtist)
          s,
    ];
  }

  /// "Picks in your language".
  ///
  /// Jamendo's `lang` filter returns nothing, so this combines tracks tagged
  /// with the language and tracks by artists from countries that speak it.
  /// English (mostly untagged on Jamendo) maps to popular vocal tracks.
  Future<List<Song>> languagePicks(
    MusicLanguage language, {
    int limit = JamendoConfig.sectionSize,
    bool forceRefresh = false,
  }) async {
    if (language.isGlobal) {
      final response = await _get(
        'tracks',
        {
          ..._trackDefaults,
          'vocalinstrumental': 'vocal',
          'order': 'popularity_month',
          'groupby': 'artist_id',
          'limit': limit,
        },
        ttl: JamendoConfig.homeTtl,
        forceRefresh: forceRefresh,
      );
      final songs = response.results.map(JamendoMapper.track).toList();
      _rememberStreams(songs);
      return songs;
    }
    final results = <Song>[];
    if (language.tag.isNotEmpty) {
      final tagged = await _get(
        'tracks',
        {
          ..._trackDefaults,
          'fuzzytags': language.tag,
          'boost': 'popularity_total',
          'limit': limit,
        },
        ttl: JamendoConfig.homeTtl,
        forceRefresh: forceRefresh,
      );
      results.addAll(tagged.results.map(JamendoMapper.track));
    }
    if (results.length < limit && language.countries.isNotEmpty) {
      results.addAll(
        await tracksFromCountries(
          language.countries,
          limit: limit,
          forceRefresh: forceRefresh,
        ),
      );
    }
    final songs = JamendoMapper.dedupe(results).take(limit).toList();
    _rememberStreams(songs);
    return songs;
  }

  // ==================== ALBUMS ====================

  Future<JamendoPage<Album>> albums({
    OnlineSort sort = OnlineSort.popular,
    String? search,
    int offset = 0,
    int limit = JamendoConfig.pageSize,
    bool forceRefresh = false,
  }) async {
    final hasSearch = search != null && search.trim().isNotEmpty;
    final response = await _get(
      'albums',
      {
        'limit': limit,
        'offset': offset,
        'imagesize': JamendoConfig.imageSize,
        if (hasSearch) 'namesearch': search.trim(),
        if (!hasSearch)
          'order': sort == OnlineSort.newest ? 'releasedate_desc' : 'popularity_month',
      },
      ttl: hasSearch ? JamendoConfig.searchTtl : JamendoConfig.listTtl,
      forceRefresh: forceRefresh,
    );
    final albums = response.results.map((a) => JamendoMapper.album(a)).toList();
    return _page(albums, response, offset, limit);
  }

  /// Album with its tracks (song ids filled in).
  Future<(Album, List<Song>)?> albumWithTracks(String remoteId) async {
    final response = await _get(
      'albums/tracks',
      {
        'id': remoteId,
        'imagesize': JamendoConfig.imageSize,
        'audioformat': JamendoConfig.audioFormat,
      },
      ttl: JamendoConfig.listTtl,
    );
    if (response.results.isEmpty) return null;
    final json = response.results.first;
    final songs = JamendoMapper.albumTracks(json)
      ..sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
    _rememberStreams(songs);
    return (JamendoMapper.album(json, songIds: songs.map((s) => s.id).toList()), songs);
  }

  // ==================== ARTISTS ====================

  Future<JamendoPage<Artist>> artists({
    OnlineSort sort = OnlineSort.popular,
    String? search,
    String? countryAlpha3,
    int offset = 0,
    int limit = JamendoConfig.pageSize,
    bool forceRefresh = false,
  }) async {
    final hasSearch = search != null && search.trim().isNotEmpty;
    final byCountry = !hasSearch && countryAlpha3 != null;
    final response = await _get(
      byCountry ? 'artists/locations' : 'artists',
      {
        'limit': limit,
        'offset': offset,
        'imagesize': JamendoConfig.imageSize,
        if (hasSearch) 'namesearch': search.trim(),
        if (byCountry) 'location_country': countryAlpha3,
        // `order` on artists/locations cuts results to a handful.
        if (!hasSearch && !byCountry)
          'order': sort == OnlineSort.newest ? 'joindate_desc' : 'popularity_month',
        if (!hasSearch && !byCountry) 'hasimage': 'true',
      },
      ttl: hasSearch ? JamendoConfig.searchTtl : JamendoConfig.listTtl,
      forceRefresh: forceRefresh,
    );
    final artists = response.results.map((a) => JamendoMapper.artist(a)).toList();
    return _page(artists, response, offset, limit);
  }

  /// Artist with up to [limit] of their tracks.
  Future<(Artist, List<Song>)?> artistWithTracks(
    String remoteId, {
    int limit = 50,
  }) async {
    final response = await _get(
      'artists/tracks',
      {
        'id': remoteId,
        'imagesize': JamendoConfig.imageSize,
        'audioformat': JamendoConfig.audioFormat,
      },
      ttl: JamendoConfig.listTtl,
    );
    if (response.results.isEmpty) return null;
    final json = response.results.first;
    final songs = JamendoMapper.artistTracks(json).take(limit).toList();
    _rememberStreams(songs);
    return (JamendoMapper.artist(json, songIds: songs.map((s) => s.id).toList()), songs);
  }

  // ==================== RADIOS & MIXES ====================

  Future<List<JamendoRadio>> radios({bool forceRefresh = false}) async {
    final response = await _get(
      'radios',
      {'limit': 50, 'imagesize': 150},
      ttl: JamendoConfig.homeTtl,
      forceRefresh: forceRefresh,
    );
    return response.results.map(JamendoRadio.fromJson).toList();
  }

  Future<String?> radioStreamUrl(String radioId) async {
    final response = await _get(
      'radios/stream',
      {'id': radioId},
      ttl: const Duration(minutes: 30),
    );
    if (response.results.isEmpty) return null;
    return JamendoMapper.nonEmpty(response.results.first['stream']);
  }

  /// Curated mixes (static list: featured genres).
  List<JamendoMix> mixes() => [
    for (final genre in JamendoConfig.featuredGenres)
      JamendoMix(
        id: 'mix_$genre',
        title: JamendoMix.titleFor(genre),
        subtitle: 'Featured on Jamendo',
        tag: genre,
      ),
  ];

  // ==================== STREAM URLS ====================

  void _rememberStreams(Iterable<Song> songs) {
    final now = _now();
    for (final s in songs) {
      final url = s.streamUrl;
      final id = s.remoteId;
      if (url != null && id != null && s.source == SongSources.jamendo) {
        _streamUrls[id] = (url, now);
      }
    }
  }

  /// A playable URL for [song]. Jamendo stream URLs are signed, so songs
  /// restored from storage (likes, history) get a fresh URL when theirs may
  /// have expired.
  Future<String?> resolveStreamUrl(Song song) async {
    final id = song.remoteId;
    if (id == null) return song.streamUrl;
    if (song.isRadio) {
      return song.streamUrl ?? await radioStreamUrl(id);
    }
    final known = _streamUrls[id];
    if (known != null && _now().difference(known.$2) < JamendoConfig.streamUrlTtl) {
      return known.$1;
    }
    try {
      final response = await client.get('tracks', {
        'id': id,
        'audioformat': JamendoConfig.audioFormat,
      });
      if (response.results.isNotEmpty) {
        final url = JamendoMapper.nonEmpty(response.results.first['audio']);
        if (url != null) {
          _streamUrls[id] = (url, _now());
          return url;
        }
      }
    } on JamendoException catch (e) {
      _logger.w('⚠️ Could not refresh stream URL for $id: ${e.kind}');
    }
    return song.streamUrl;
  }
}

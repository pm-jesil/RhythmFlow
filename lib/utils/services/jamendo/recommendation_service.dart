import '../../logger/logger.dart';
import '../../models/song/song_model.dart';
import 'jamendo_api_client.dart';
import 'jamendo_config.dart';
import 'jamendo_repository.dart';
import 'taste_models.dart';

/// What the user likes, as weights per taste tag plus favourite artists.
class TasteProfile {
  /// Taste id -> weight (higher = more relevant), only known tastes.
  final Map<String, double> tagWeights;

  /// Jamendo artist ids ordered by affinity.
  final List<String> topArtistIds;

  const TasteProfile({required this.tagWeights, required this.topArtistIds});

  bool get isEmpty => tagWeights.isEmpty && topArtistIds.isEmpty;

  /// Taste ids by weight (ties keep the user's pick order).
  List<String> get topTags {
    final entries = tagWeights.entries.toList();
    final order = {for (var i = 0; i < entries.length; i++) entries[i].key: i};
    entries.sort((a, b) {
      final byWeight = b.value.compareTo(a.value);
      return byWeight != 0 ? byWeight : order[a.key]!.compareTo(order[b.key]!);
    });
    return entries.map((e) => e.key).toList();
  }
}

/// Builds "Made for you" suggestions on the device.
///
/// Jamendo has no working "similar tracks" endpoint (measured:
/// `/tracks/similar` always returns 0), so suggestions combine:
///  * the tastes the user picked (strongest signal),
///  * genres/moods of artists the user liked or played
///    (`/artists/musicinfo`),
///  * more songs by those artists.
class RecommendationService {
  static final AppLogger _logger = AppLogger('RecommendationService');

  static const double pickedWeight = 3;
  static const double likedArtistTagWeight = 1;
  static const double recentArtistTagWeight = 0.5;

  final JamendoRepository repository;

  RecommendationService(this.repository);

  /// Pure: combines picked tastes and artist tags into a profile.
  static TasteProfile buildProfile({
    required List<String> pickedTastes,
    List<Song> liked = const [],
    List<Song> recent = const [],
    Map<String, List<String>> artistTags = const {},
  }) {
    final weights = <String, double>{};
    void add(String rawTag, double w) {
      final taste = MusicTastes.byId(rawTag);
      if (taste == null) return;
      weights[taste.id] = (weights[taste.id] ?? 0) + w;
    }

    for (final t in pickedTastes) {
      add(t, pickedWeight);
    }

    final artistScore = <String, double>{};
    void scoreArtist(Song s, double w) {
      final id = s.remoteArtistId;
      if (id == null || id.isEmpty) return;
      artistScore[id] = (artistScore[id] ?? 0) + w;
    }

    for (final s in liked) {
      scoreArtist(s, 2);
      for (final tag in artistTags[s.remoteArtistId] ?? const <String>[]) {
        add(tag, likedArtistTagWeight);
      }
    }
    for (final s in recent) {
      scoreArtist(s, 1);
      for (final tag in artistTags[s.remoteArtistId] ?? const <String>[]) {
        add(tag, recentArtistTagWeight);
      }
    }

    final artists = artistScore.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return TasteProfile(
      tagWeights: weights,
      topArtistIds: artists.map((e) => e.key).toList(),
    );
  }

  /// Pure: round-robin merge of several ranked lists, skipping [exclude]
  /// and keeping at most [perArtist] songs per artist.
  static List<Song> blend(
    List<List<Song>> sources, {
    Set<String> exclude = const {},
    int limit = JamendoConfig.sectionSize,
    int perArtist = 2,
  }) {
    final result = <Song>[];
    final seen = <String>{...exclude};
    final perArtistCount = <String, int>{};
    var index = 0;
    var progressed = true;
    while (result.length < limit && progressed) {
      progressed = false;
      for (final source in sources) {
        if (index >= source.length) continue;
        progressed = true;
        final song = source[index];
        final artist = song.remoteArtistId ?? song.artists.first;
        if (!seen.add(song.id)) continue;
        final count = perArtistCount[artist] ?? 0;
        if (count >= perArtist) continue;
        perArtistCount[artist] = count + 1;
        result.add(song);
        if (result.length >= limit) break;
      }
      index++;
    }
    return result;
  }

  /// Fetches artist tags for the most relevant liked / played artists.
  Future<Map<String, List<String>>> fetchArtistTags(
    List<Song> liked,
    List<Song> recent, {
    int maxArtists = 6,
  }) async {
    final ids = <String>[];
    for (final s in [...liked, ...recent]) {
      final id = s.remoteArtistId;
      if (id != null && id.isNotEmpty && !ids.contains(id)) ids.add(id);
      if (ids.length >= maxArtists) break;
    }
    final result = <String, List<String>>{};
    for (final id in ids) {
      try {
        result[id] = await repository.artistTags(id);
      } on JamendoException catch (e) {
        _logger.w('⚠️ artist tags $id: ${e.kind}');
      }
    }
    return result;
  }

  /// "Made for you": songs for the strongest tastes plus songs by favourite
  /// artists, excluding what the user already liked / played.
  Future<List<Song>> madeForYou({
    required List<String> pickedTastes,
    List<Song> liked = const [],
    List<Song> recent = const [],
    int limit = JamendoConfig.sectionSize,
    bool forceRefresh = false,
  }) async {
    final artistTags = await fetchArtistTags(liked, recent);
    final profile = buildProfile(
      pickedTastes: pickedTastes,
      liked: liked,
      recent: recent,
      artistTags: artistTags,
    );
    final sources = <List<Song>>[];
    for (final tag in profile.topTags.take(3)) {
      final taste = MusicTastes.byId(tag);
      if (taste == null) continue;
      sources.add(await repository.tasteTracks(taste, limit: 15, forceRefresh: forceRefresh));
    }
    for (final artistId in profile.topArtistIds.take(2)) {
      try {
        final artist = await repository.artistWithTracks(artistId, limit: 8);
        if (artist != null) sources.add(artist.$2);
      } on JamendoException catch (e) {
        _logger.w('⚠️ artist tracks $artistId: ${e.kind}');
      }
    }
    return blend(
      sources,
      exclude: {...liked.map((s) => s.id), ...recent.map((s) => s.id)},
      limit: limit,
    );
  }
}

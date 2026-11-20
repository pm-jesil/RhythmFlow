import 'taste_data.dart';

enum TasteKind { genre, mood }

/// A genre or mood the user can pick ("taste"), backed by a Jamendo tag.
class MusicTaste {
  final String id;
  final String label;
  final String emoji;
  final TasteKind kind;

  /// Query with `fuzzytags` (true) or `tags` (false); measured per tag.
  final bool useFuzzy;
  final int trackCount;

  const MusicTaste({
    required this.id,
    required this.label,
    required this.emoji,
    required this.kind,
    required this.useFuzzy,
    required this.trackCount,
  });
}

class MusicTastes {
  MusicTastes._();

  static List<MusicTaste> get all => jamendoTastes;
  static List<MusicTaste> get genres =>
      jamendoTastes.where((t) => t.kind == TasteKind.genre).toList();
  static List<MusicTaste> get moods =>
      jamendoTastes.where((t) => t.kind == TasteKind.mood).toList();

  /// Synonyms users may expect, mapped to the Jamendo tag.
  static const Map<String, String> aliases = {
    'rap': 'hiphop',
    'hip-hop': 'hiphop',
    'hip hop': 'hiphop',
    'chill': 'chillout',
    'relax': 'relaxation',
    'soul': 'rnb',
    'lo-fi': 'lofi',
  };

  static MusicTaste? byId(String? id) {
    if (id == null) return null;
    final key = aliases[id.toLowerCase()] ?? id.toLowerCase();
    for (final t in jamendoTastes) {
      if (t.id == key) return t;
    }
    return null;
  }

  /// Minimum number of tastes the setup form asks for.
  static const int minPicks = 1;

  /// Recommended number of picks (shown as a hint).
  static const int recommendedPicks = 3;
}

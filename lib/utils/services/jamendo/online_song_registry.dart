import '../../models/song/song_model.dart';

/// In-memory lookup of online (Discover) songs by id.
///
/// Online songs never go into `MusicState.allSongs` (that list is the device
/// library: scans, counts and AI features depend on it). The player still
/// needs to resolve queue ids to songs, so every online song that is shown,
/// queued, liked or restored is registered here.
class OnlineSongRegistry {
  OnlineSongRegistry._();

  static final Map<String, Song> _songs = {};

  /// Upper bound to keep memory in check; oldest entries are evicted first
  /// (insertion order), except ids passed as `keep` to [register].
  static const int maxEntries = 3000;

  static void register(Iterable<Song> songs) {
    for (final song in songs) {
      if (!song.isOnline) continue;
      _songs.remove(song.id); // refresh insertion order
      _songs[song.id] = song;
    }
    while (_songs.length > maxEntries) {
      _songs.remove(_songs.keys.first);
    }
  }

  static Song? get(String id) => _songs[id];

  static bool contains(String id) => _songs.containsKey(id);

  static List<Song> resolveAll(Iterable<String> ids) => [
    for (final id in ids)
      if (_songs[id] != null) _songs[id]!,
  ];

  static int get length => _songs.length;

  static void clear() => _songs.clear();
}

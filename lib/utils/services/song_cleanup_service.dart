import '../logger/logger.dart';
import '../models/song/song_model.dart';
import '../models/album/album_model.dart';
import '../models/artist/artist_model.dart';
import '../models/my_playlist/my_playlist_model.dart';
import '../models/my_player_state_model.dart';

/// Centralized service for song cleanup and duplicate management
class SongCleanupService {
  static final _logger = AppLogger('SongCleanupService');

  // ==================== SONG CLEANUP METHODS ====================
  
  /// Find removed songs by comparing new songs with existing songs
  static List<String> findRemovedSongIds(List<Song> existingSongs, List<Song> newSongs) {
    _logger.i('🔍 Finding removed songs...');
    
    final newSongIds = newSongs.map((song) => song.id).toSet();
    final removedSongIds = <String>[];
    
    // Find songs that were removed
    for (final existingSong in existingSongs) {
      if (!newSongIds.contains(existingSong.id)) {
        removedSongIds.add(existingSong.id);
      }
    }
    
    if (removedSongIds.isEmpty) {
      _logger.i('✅ No songs were removed');
    } else {
      _logger.i('🗑️ Found ${removedSongIds.length} removed songs: $removedSongIds');
    }
    
    return removedSongIds;
  }

  /// Comprehensive cleanup after song fetching - removes empty albums/artists
  static Map<String, dynamic> performPostFetchCleanup({
    required List<Album> albums,
    required List<Artist> artists,
    required List<MyPlaylist> playlists,
  }) {
    _logger.i('🧹 Performing post-fetch cleanup...');
    
    // Clean up empty albums
    final cleanedAlbums = _removeEmptyAlbums(albums);
    
    // Clean up empty artists  
    final cleanedArtists = _removeEmptyArtists(artists);
    
    // Playlists are preserved (even if empty)
    final cleanedPlaylists = playlists;
    
    final albumsRemoved = albums.length - cleanedAlbums.length;
    final artistsRemoved = artists.length - cleanedArtists.length;
    
    if (albumsRemoved > 0 || artistsRemoved > 0) {
      _logger.i('✅ Post-fetch cleanup completed: $albumsRemoved empty albums, $artistsRemoved empty artists removed');
    } else {
      _logger.i('✅ Post-fetch cleanup completed: no empty items found');
    }
    
    return {
      'albums': cleanedAlbums,
      'artists': cleanedArtists,
      'playlists': cleanedPlaylists,
      'albumsRemoved': albumsRemoved,
      'artistsRemoved': artistsRemoved,
    };
  }

  /// Remove empty albums (0 song IDs)
  static List<Album> _removeEmptyAlbums(List<Album> albums) {
    final cleanedAlbums = albums.where((album) => album.songIds.isNotEmpty).toList();
    final removedCount = albums.length - cleanedAlbums.length;
    
    if (removedCount > 0) {
      _logger.i('🗑️ Removed $removedCount empty albums');
    }
    
    return cleanedAlbums;
  }

  /// Remove empty artists (0 song IDs)
  static List<Artist> _removeEmptyArtists(List<Artist> artists) {
    final cleanedArtists = artists.where((artist) => artist.songIds.isNotEmpty).toList();
    final removedCount = artists.length - cleanedArtists.length;
    
    if (removedCount > 0) {
      _logger.i('🗑️ Removed $removedCount empty artists');
    }
    
    return cleanedArtists;
  }
  
  /// Clean up removed songs from player state
  static MyPlayerStateModel cleanupPlayerState(MyPlayerStateModel playerState, List<String> removedSongIds) {
    bool needsUpdate = false;
    
    // Check if current song was removed
    if (playerState.currentSongId != null && removedSongIds.contains(playerState.currentSongId)) {
      _logger.i('🎵 Current song was removed: ${playerState.currentSongId}');
      needsUpdate = true;
    }
    
    // Check if previous song was removed
    if (playerState.previousSongId != null && removedSongIds.contains(playerState.previousSongId)) {
      _logger.i('🎵 Previous song was removed: ${playerState.previousSongId}');
      needsUpdate = true;
    }
    
    // Clean up current playlist
    final cleanedCurrentPlaylist = playerState.currentPlayList
        .where((songId) => !removedSongIds.contains(songId))
        .toList();
    
    // Clean up completed songs
    final cleanedCompletedSongs = playerState.completedSongs
        .where((songId) => !removedSongIds.contains(songId))
        .toList();
    
    if (needsUpdate || cleanedCurrentPlaylist.length != playerState.currentPlayList.length || 
        cleanedCompletedSongs.length != playerState.completedSongs.length) {
      
      _logger.i('🔄 Player state cleanup: ${playerState.currentPlayList.length} → ${cleanedCurrentPlaylist.length} current, ${playerState.completedSongs.length} → ${cleanedCompletedSongs.length} completed');
      
      // Build the model explicitly: MyPlayerStateModel.copyWith uses `??`,
      // so it can never reset currentSongId / previousSongId to null and a
      // deleted current song would otherwise stay "current".
      final currentRemoved = removedSongIds.contains(playerState.currentSongId);
      return MyPlayerStateModel(
        playlistId: playerState.playlistId,
        currentPlayList: cleanedCurrentPlaylist,
        currentSongId: currentRemoved ? null : playerState.currentSongId,
        previousSongId: removedSongIds.contains(playerState.previousSongId)
            ? null
            : playerState.previousSongId,
        completedSongs: cleanedCompletedSongs,
        repeatModeIndex: playerState.repeatModeIndex,
        filterKeyword: playerState.filterKeyword,
        isShuffle: playerState.isShuffle,
        isPlaying: currentRemoved ? false : playerState.isPlaying,
        lastPosition: currentRemoved ? null : playerState.lastPosition,
      );
    }
    
    return playerState;
  }
  
  /// Clean up removed songs from albums and remove empty albums
  static List<Album> cleanupAlbums(List<Album> albums, List<String> removedSongIds) {
    final cleanedAlbums = <Album>[];
    bool needsUpdate = false;
    int emptyAlbumsRemoved = 0;
    
    for (final album in albums) {
      final cleanedSongIds = album.songIds
          .where((songId) => !removedSongIds.contains(songId))
          .toList();
      
      // Remove empty albums (0 song IDs)
      if (cleanedSongIds.isEmpty) {
        _logger.i('🗑️ Removing empty album: "${album.name}" (0 songs)');
        emptyAlbumsRemoved++;
        needsUpdate = true;
        continue; // Skip adding this album to the cleaned list
      }
      
      if (cleanedSongIds.length != album.songIds.length) {
        _logger.i('💿 Album "${album.name}" cleanup: ${album.songIds.length} → ${cleanedSongIds.length} songs');
        cleanedAlbums.add(album.copyWith(songIds: cleanedSongIds));
        needsUpdate = true;
      } else {
        cleanedAlbums.add(album);
      }
    }
    
    if (needsUpdate) {
      _logger.i('✅ Album cleanup completed - removed $emptyAlbumsRemoved empty albums');
    }
    
    return cleanedAlbums;
  }
  
  /// Clean up removed songs from artists and remove empty artists
  static List<Artist> cleanupArtists(List<Artist> artists, List<String> removedSongIds) {
    final cleanedArtists = <Artist>[];
    bool needsUpdate = false;
    int emptyArtistsRemoved = 0;
    
    for (final artist in artists) {
      final cleanedSongIds = artist.songIds
          .where((songId) => !removedSongIds.contains(songId))
          .toList();
      
      // Remove empty artists (0 song IDs)
      if (cleanedSongIds.isEmpty) {
        _logger.i('🗑️ Removing empty artist: "${artist.name}" (0 songs)');
        emptyArtistsRemoved++;
        needsUpdate = true;
        continue; // Skip adding this artist to the cleaned list
      }
      
      if (cleanedSongIds.length != artist.songIds.length) {
        _logger.i('👤 Artist "${artist.name}" cleanup: ${artist.songIds.length} → ${cleanedSongIds.length} songs');
        cleanedArtists.add(artist.copyWith(songIds: cleanedSongIds));
        needsUpdate = true;
      } else {
        cleanedArtists.add(artist);
      }
    }
    
    if (needsUpdate) {
      _logger.i('✅ Artist cleanup completed - removed $emptyArtistsRemoved empty artists');
    }
    
    return cleanedArtists;
  }
  
  /// Clean up removed songs from my playlists (NOTE: Empty playlists are preserved)
  static List<MyPlaylist> cleanupMyPlaylists(List<MyPlaylist> playlists, List<String> removedSongIds) {
    final cleanedPlaylists = <MyPlaylist>[];
    bool needsUpdate = false;
    
    for (final playlist in playlists) {
      final cleanedSongIds = playlist.songIds
          .where((songId) => !removedSongIds.contains(songId))
          .toList();
      
      // NOTE: We keep empty playlists (0 songs) - user may want to add songs later
      if (cleanedSongIds.length != playlist.songIds.length) {
        _logger.i('📋 Playlist "${playlist.name}" cleanup: ${playlist.songIds.length} → ${cleanedSongIds.length} songs');
        cleanedPlaylists.add(playlist.copyWith(songIds: cleanedSongIds));
        needsUpdate = true;
      } else {
        cleanedPlaylists.add(playlist);
      }
    }
    
    if (needsUpdate) {
      _logger.i('✅ Playlist cleanup completed (empty playlists preserved)');
    }
    
    return cleanedPlaylists;
  }

  // ==================== DUPLICATE SONG METHODS ====================
  //
  // Two files are only treated as duplicates when they are the *same
  // recording*: same normalized title, same normalized primary artist and
  // durations within [duplicateDurationTolerance]. Songs that merely share a
  // title ("Hello" by two different artists), versions such as "(Live)" or
  // "(Remix)", and songs whose duration is unknown are never merged.
  //
  // Normalization is Unicode aware, so Malayalam, Tamil, Hindi, Arabic,
  // Japanese ... titles are compared correctly instead of collapsing to an
  // empty string.

  /// Maximum duration difference for two files to count as the same song.
  static const Duration duplicateDurationTolerance = Duration(seconds: 2);

  static final RegExp _nonWordChars = RegExp(
    r'[^\p{L}\p{M}\p{N}\s]',
    unicode: true,
  );
  static final RegExp _whitespace = RegExp(r'\s+', unicode: true);

  /// Lower-cases, removes punctuation/symbols and collapses whitespace.
  /// Letters, combining marks (Indic vowel signs etc.) and digits of every
  /// script are preserved. No words are removed.
  static String normalizeTitle(String title) {
    if (title.isEmpty) return '';
    return title
        .toLowerCase()
        .replaceAll(_nonWordChars, ' ')
        .replaceAll(_whitespace, ' ')
        .trim();
  }

  /// Key used to group potential duplicates, or `null` when the song must
  /// never be merged with another one (e.g. an empty normalized title).
  static String? duplicateKey(Song song) {
    final title = normalizeTitle(song.title);
    if (title.isEmpty) return null;
    final artist = normalizeTitle(
      song.artists.isNotEmpty ? song.artists.first : '',
    );
    return '$title|$artist';
  }

  /// True when [a] and [b] are the same recording stored in two files.
  static bool isSameRecording(Song a, Song b) {
    if (a.path == b.path) return true;
    final keyA = duplicateKey(a);
    if (keyA == null || keyA != duplicateKey(b)) return false;
    // Unknown durations are never considered equal.
    if (a.duration <= Duration.zero || b.duration <= Duration.zero) {
      return false;
    }
    final diff = (a.duration - b.duration).abs();
    return diff <= duplicateDurationTolerance;
  }

  /// Splits [candidates] into songs to accept and duplicates to drop.
  ///
  /// [existing] songs always win (they may already be in playlists, have play
  /// counts, etc.). Among candidates, the first one (in list order) wins.
  /// The same rule is used by the first full scan and by incremental scans,
  /// so the resulting song count does not depend on which path ran.
  static DuplicateFilterResult filterDuplicatesAgainst(
    List<Song> existing,
    List<Song> candidates,
  ) {
    final Map<String, List<Song>> keptByKey = {};
    final Set<String> keptIds = {};
    final Set<String> keptPaths = {};

    void remember(Song song) {
      keptIds.add(song.id);
      keptPaths.add(song.path);
      final key = duplicateKey(song);
      if (key != null) keptByKey.putIfAbsent(key, () => []).add(song);
    }

    for (final song in existing) {
      remember(song);
    }

    final accepted = <Song>[];
    final dropped = <Song>[];
    for (final song in candidates) {
      if (keptIds.contains(song.id) || keptPaths.contains(song.path)) {
        dropped.add(song);
        continue;
      }
      final key = duplicateKey(song);
      final sameKey = key == null ? const <Song>[] : keptByKey[key] ?? const [];
      if (sameKey.any((kept) => isSameRecording(kept, song))) {
        dropped.add(song);
        continue;
      }
      accepted.add(song);
      remember(song);
    }

    if (dropped.isNotEmpty) {
      _logger.i(
        'Duplicate filter: kept ${accepted.length}, dropped ${dropped.length}',
      );
    }
    return DuplicateFilterResult(accepted: accepted, dropped: dropped);
  }

  /// Removes duplicate recordings from [songs] (first occurrence wins).
  ///
  /// Kept under its historical name for backward compatibility; it no longer
  /// matches on title alone (see the section comment above).
  static List<Song> removeDuplicateSongsByTitle(List<Song> songs) {
    return filterDuplicatesAgainst(const [], songs).accepted;
  }

  /// Select the better song between two duplicates
  static Song selectBetterSong(Song song1, Song song2) {
    // Priority 1: Has album art
    if (song1.albumArt != null && song2.albumArt == null) return song1;
    if (song2.albumArt != null && song1.albumArt == null) return song2;

    // Priority 2: Longer duration (more complete)
    if (song1.duration != song2.duration) {
      return song1.duration > song2.duration ? song1 : song2;
    }

    // Priority 3: Has more metadata
    int song1Metadata = _countMetadata(song1);
    int song2Metadata = _countMetadata(song2);
    if (song1Metadata != song2Metadata) {
      return song1Metadata > song2Metadata ? song1 : song2;
    }

    // Priority 4: Higher quality (if available)
    if (song1.bitrate != null && song2.bitrate != null && song1.bitrate != song2.bitrate) {
      return song1.bitrate! > song2.bitrate! ? song1 : song2;
    }

    // Default: return first song
    return song1;
  }

  /// Count non-empty metadata fields
  static int _countMetadata(Song song) {
    int count = 0;
    if (song.title.isNotEmpty) count++;
    if (song.artists.isNotEmpty) count++;
    if (song.albums.isNotEmpty) count++;
    if (song.genre != null && song.genre!.isNotEmpty) count++;
    if (song.year != null) count++;
    if (song.albumArt != null) count++;
    return count;
  }

  /// Fuzzy duplicate detection (optional, not used by the scanner).
  /// Uses the same safety rules as [isSameRecording] but tolerates small
  /// spelling differences in the title.
  static List<Song> removeDuplicatesSongsFuzzy(List<Song> songs) {
    final List<Song> uniqueSongs = [];
    for (final song in songs) {
      if (!uniqueSongs.any((kept) => areSongsSimilar(kept, song))) {
        uniqueSongs.add(song);
      }
    }
    return uniqueSongs;
  }

  /// Check if two songs are similar enough to be considered duplicates:
  /// near-identical title, same artist and same duration.
  static bool areSongsSimilar(Song song1, Song song2) {
    if (isSameRecording(song1, song2)) return true;

    final title1 = normalizeTitle(song1.title);
    final title2 = normalizeTitle(song2.title);
    if (title1.isEmpty || title2.isEmpty) return false;

    final artist1 = normalizeTitle(song1.artists.isNotEmpty ? song1.artists.first : '');
    final artist2 = normalizeTitle(song2.artists.isNotEmpty ? song2.artists.first : '');
    if (artist1 != artist2) return false;

    if (song1.duration <= Duration.zero || song2.duration <= Duration.zero) {
      return false;
    }
    if ((song1.duration - song2.duration).abs() > duplicateDurationTolerance) {
      return false;
    }
    return _calculateSimilarity(title1, title2) >= 0.9;
  }

  /// Calculate similarity between two strings (0.0 to 1.0)
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    var previous = List<int>.generate(s2.length + 1, (j) => j);
    for (int i = 1; i <= s1.length; i++) {
      final current = List<int>.filled(s2.length + 1, 0);
      current[0] = i;
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        var best = deletion < insertion ? deletion : insertion;
        if (substitution < best) best = substitution;
        current[j] = best;
      }
      previous = current;
    }
    return previous[s2.length];
  }

  // ==================== UNIQUENESS VALIDATION ====================

  /// Validate that all songs have unique IDs
  static bool validateUniqueIds(List<Song> songs) {
    final Set<String> seenIds = <String>{};
    
    for (final song in songs) {
      if (seenIds.contains(song.id)) {
        return false; // Duplicate ID found
      }
      seenIds.add(song.id);
    }
    
    return true; // All IDs are unique
  }

  /// Remove duplicate songs based on ID, keeping the first occurrence
  static List<Song> removeDuplicatesById(List<Song> songs) {
    final Set<String> seenIds = <String>{};
    final List<Song> uniqueSongs = <Song>[];
    
    for (final song in songs) {
      if (!seenIds.contains(song.id)) {
        seenIds.add(song.id);
        uniqueSongs.add(song);
      }
    }
    
    return uniqueSongs;
  }

  /// Get duplicate song IDs for debugging
  static List<String> getDuplicateIds(List<Song> songs) {
    final Set<String> seenIds = <String>{};
    final List<String> duplicates = <String>[];
    
    for (final song in songs) {
      if (seenIds.contains(song.id)) {
        duplicates.add(song.id);
      } else {
        seenIds.add(song.id);
      }
    }
    
    return duplicates;
  }

  // ==================== COMPREHENSIVE DUPLICATE REMOVAL ====================

  /// Remove all types of duplicates (ID, title, fuzzy) with comprehensive strategy
  static List<Song> removeAllDuplicates(List<Song> songs, {
    bool useFuzzyMatching = false,
    bool useTitleMatching = true,
  }) {
    _logger.i('🧹 Starting comprehensive duplicate removal from ${songs.length} songs');
    
    // Step 1: Remove ID duplicates (always do this first)
    List<Song> result = removeDuplicatesById(songs);
    _logger.i('✅ Removed ID duplicates: ${songs.length} → ${result.length} songs');
    
    // Step 2: Remove title-based duplicates
    if (useTitleMatching) {
      final beforeTitle = result.length;
      result = removeDuplicateSongsByTitle(result);
      _logger.i('✅ Removed title duplicates: $beforeTitle → ${result.length} songs');
    }
    
    // Step 3: Remove fuzzy duplicates (optional, more aggressive)
    if (useFuzzyMatching) {
      final beforeFuzzy = result.length;
      result = removeDuplicatesSongsFuzzy(result);
      _logger.i('✅ Removed fuzzy duplicates: $beforeFuzzy → ${result.length} songs');
    }
    
    _logger.i('🎉 Comprehensive duplicate removal completed: ${songs.length} → ${result.length} songs');
    return result;
  }

  // ==================== COMPREHENSIVE STATE CLEANUP ====================

  /// Comprehensive cleanup for when songs are removed from device
  /// This handles all possible locations where invalid song IDs might exist
  static Map<String, dynamic> performComprehensiveCleanup({
    required List<Song> allSongs,
    required List<Album> albums,
    required List<Artist> artists,
    required List<MyPlaylist> playlists,
    required MyPlayerStateModel playerState,
    required List<String> invalidSongIds,
  }) {
    _logger.i('🧹 Starting comprehensive cleanup for ${invalidSongIds.length} invalid songs...');
    
    if (invalidSongIds.isEmpty) {
      _logger.i('✅ No invalid songs to clean up');
      return {
        'allSongs': allSongs,
        'albums': albums,
        'artists': artists,
        'playlists': playlists,
        'playerState': playerState,
        'songsRemoved': 0,
        'albumsRemoved': 0,
        'artistsRemoved': 0,
        'playlistsUpdated': 0,
      };
    }

    // Step 1: Remove invalid songs from allSongs
    final cleanedAllSongs = allSongs.where((song) => !invalidSongIds.contains(song.id)).toList();
    final songsRemoved = allSongs.length - cleanedAllSongs.length;
    
    // Step 2: Clean up player state
    final cleanedPlayerState = cleanupPlayerState(playerState, invalidSongIds);
    
    // Step 3: Clean up albums
    final cleanedAlbums = cleanupAlbums(albums, invalidSongIds);
    final albumsRemoved = albums.length - cleanedAlbums.length;
    
    // Step 4: Clean up artists
    final cleanedArtists = cleanupArtists(artists, invalidSongIds);
    final artistsRemoved = artists.length - cleanedArtists.length;
    
    // Step 5: Clean up playlists
    final cleanedPlaylists = cleanupMyPlaylists(playlists, invalidSongIds);
    final playlistsUpdated = _countUpdatedPlaylists(playlists, cleanedPlaylists);
    
    _logger.i('✅ Comprehensive cleanup completed: $songsRemoved songs, $albumsRemoved albums, $artistsRemoved artists, $playlistsUpdated playlists updated');
    
    return {
      'allSongs': cleanedAllSongs,
      'albums': cleanedAlbums,
      'artists': cleanedArtists,
      'playlists': cleanedPlaylists,
      'playerState': cleanedPlayerState,
      'songsRemoved': songsRemoved,
      'albumsRemoved': albumsRemoved,
      'artistsRemoved': artistsRemoved,
      'playlistsUpdated': playlistsUpdated,
    };
  }

  /// Count how many playlists were updated during cleanup
  static int _countUpdatedPlaylists(List<MyPlaylist> original, List<MyPlaylist> cleaned) {
    int updated = 0;
    for (int i = 0; i < original.length && i < cleaned.length; i++) {
      if (original[i].songIds.length != cleaned[i].songIds.length) {
        updated++;
      }
    }
    return updated;
  }

  /// Enhanced cleanup that also handles current song and queue scenarios
  static Map<String, dynamic> performEnhancedCleanup({
    required List<Song> allSongs,
    required List<Album> albums,
    required List<Artist> artists,
    required List<MyPlaylist> playlists,
    required MyPlayerStateModel playerState,
    required List<String> invalidSongIds,
  }) {
    _logger.i('🔧 Starting enhanced cleanup for ${invalidSongIds.length} invalid songs...');
    
    // Perform comprehensive cleanup
    final cleanupResult = performComprehensiveCleanup(
      allSongs: allSongs,
      albums: albums,
      artists: artists,
      playlists: playlists,
      playerState: playerState,
      invalidSongIds: invalidSongIds,
    );
    
    // Additional checks for critical scenarios
    final cleanedPlayerState = cleanupResult['playerState'] as MyPlayerStateModel;
    
    // Check if current song was removed and handle gracefully
    if (cleanedPlayerState.currentSongId == null && playerState.currentSongId != null) {
      _logger.w('⚠️ Current song was removed - player will be stopped');
    }
    
    // Check if playing queue is empty after cleanup
    if (cleanedPlayerState.currentPlayList.isEmpty && playerState.currentPlayList.isNotEmpty) {
      _logger.w('⚠️ Playing queue is now empty after cleanup');
    }
    
    // Check if any critical playlists are now empty
    final cleanedPlaylists = cleanupResult['playlists'] as List<MyPlaylist>;
    final emptyPlaylists = cleanedPlaylists.where((playlist) => playlist.songIds.isEmpty).length;
    if (emptyPlaylists > 0) {
      _logger.i('ℹ️ $emptyPlaylists playlists are now empty (preserved as per design)');
    }
    
    return cleanupResult;
  }
}

/// Result of [SongCleanupService.filterDuplicatesAgainst].
class DuplicateFilterResult {
  final List<Song> accepted;
  final List<Song> dropped;

  const DuplicateFilterResult({required this.accepted, required this.dropped});
}

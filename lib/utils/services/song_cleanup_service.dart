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
      
      return playerState.copyWith(
        currentSongId: removedSongIds.contains(playerState.currentSongId) ? null : playerState.currentSongId,
        previousSongId: removedSongIds.contains(playerState.previousSongId) ? null : playerState.previousSongId,
        currentPlayList: cleanedCurrentPlaylist,
        completedSongs: cleanedCompletedSongs,
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

  /// Remove duplicate songs by title, keeping the best version
  static List<Song> removeDuplicateSongsByTitle(List<Song> songs) {
    _logger.d('Removing duplicate songs by title from ${songs.length} songs');

    final Map<String, Song> uniqueSongs = {};
    int duplicatesRemoved = 0;

    for (final song in songs) {
      final normalizedTitle = normalizeTitle(song.title);

      if (uniqueSongs.containsKey(normalizedTitle)) {
        // Found a duplicate - keep the better version
        final existingSong = uniqueSongs[normalizedTitle]!;
        final betterSong = selectBetterSong(existingSong, song);

        if (betterSong != existingSong) {
          _logger.d(
            'Replacing duplicate: "${existingSong.title}" with better version: "${song.title}"',
          );
          uniqueSongs[normalizedTitle] = betterSong;
        } else {
          _logger.d(
            'Keeping existing song: "${existingSong.title}", removing duplicate: "${song.title}"',
          );
        }

        duplicatesRemoved++;
      } else {
        // First occurrence of this title
        uniqueSongs[normalizedTitle] = song;
      }
    }

    _logger.i(
      'Removed $duplicatesRemoved duplicate songs, kept ${uniqueSongs.length} unique songs',
    );
    return uniqueSongs.values.toList();
  }

  /// Enhanced normalization that handles multiple languages
  static String normalizeTitle(String title) {
    if (title.isEmpty) return '';

    // Convert to lowercase and remove extra whitespace
    String normalized = title.toLowerCase().trim();

    // Remove common punctuation and special characters
    normalized = normalized
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    // Remove common words that don't add uniqueness
    final commonWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during',
      'before', 'after', 'above', 'below', 'between', 'among', 'under',
      'over', 'around', 'near', 'far', 'here', 'there', 'where', 'when',
      'why', 'how', 'what', 'who', 'which', 'that', 'this', 'these',
      'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him',
      'her', 'us', 'them', 'my', 'your', 'his', 'its', 'our',
      'their', 'mine', 'yours', 'hers', 'ours', 'theirs', 'am', 'is',
      'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
      'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may',
      'might', 'must', 'can', 'shall', 'feat', 'ft', 'featuring',
      'vs', 'versus', 'remix', 'edit', 'version', 'extended', 'radio',
      'single', 'album', 'ep', 'lp', 'cd', 'vinyl', 'digital', 'live',
      'acoustic', 'instrumental', 'karaoke', 'cover', 'original'
    };

    final words = normalized.split(' ');
    final filteredWords = words.where((word) => !commonWords.contains(word)).toList();

    return filteredWords.join(' ');
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

  /// Alternative: More aggressive duplicate detection using fuzzy matching
  static List<Song> removeDuplicatesSongsFuzzy(List<Song> songs) {
    _logger.d('Removing duplicate songs using fuzzy matching from ${songs.length} songs');

    final List<Song> uniqueSongs = [];
    int duplicatesRemoved = 0;

    for (final song in songs) {
      bool isDuplicate = false;

      for (int i = 0; i < uniqueSongs.length; i++) {
        if (areSongsSimilar(uniqueSongs[i], song)) {
          // Found a potential duplicate
          final betterSong = selectBetterSong(uniqueSongs[i], song);
          
          if (betterSong != uniqueSongs[i]) {
            _logger.d('Replacing fuzzy duplicate: "${uniqueSongs[i].title}" with "${song.title}"');
            uniqueSongs[i] = betterSong;
          } else {
            _logger.d('Keeping existing song, removing fuzzy duplicate: "${song.title}"');
          }
          
          isDuplicate = true;
          duplicatesRemoved++;
          break;
        }
      }

      if (!isDuplicate) {
        uniqueSongs.add(song);
      }
    }

    _logger.i('Fuzzy matching removed $duplicatesRemoved duplicates, kept ${uniqueSongs.length} unique songs');
    return uniqueSongs;
  }

  /// Check if two songs are similar enough to be considered duplicates
  static bool areSongsSimilar(Song song1, Song song2) {
    // Check title similarity
    final title1 = normalizeTitle(song1.title);
    final title2 = normalizeTitle(song2.title);
    
    if (title1.isEmpty || title2.isEmpty) return false;
    
    // Exact match after normalization
    if (title1 == title2) return true;
    
    // Check for high similarity (80%+ match)
    final similarity = _calculateSimilarity(title1, title2);
    if (similarity >= 0.8) return true;
    
    // Check artist similarity if titles are somewhat similar
    if (similarity >= 0.6) {
      final artist1 = normalizeTitle(song1.artists.isNotEmpty ? song1.artists.first : '');
      final artist2 = normalizeTitle(song2.artists.isNotEmpty ? song2.artists.first : '');
      if (artist1.isNotEmpty && artist2.isNotEmpty) {
        final artistSimilarity = _calculateSimilarity(artist1, artist2);
        if (artistSimilarity >= 0.7) return true;
      }
    }
    
    return false;
  }

  /// Calculate similarity between two strings (0.0 to 1.0)
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;
    
    if (longer.isEmpty) return 1.0;
    
    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
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
    
    _logger.i('✅ Comprehensive cleanup completed:');
    _logger.i('   - Songs removed: $songsRemoved');
    _logger.i('   - Albums removed: $albumsRemoved');
    _logger.i('   - Artists removed: $artistsRemoved');
    _logger.i('   - Playlists updated: $playlistsUpdated');
    _logger.i('   - Player state cleaned: ${playerState != cleanedPlayerState}');
    
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

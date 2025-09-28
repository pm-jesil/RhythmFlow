import 'package:uuid/uuid.dart';
import '../logger/logger.dart';
import '../models/my_playlist/my_playlist_model.dart';
import '../models/song/song_model.dart';

/// Service for managing user playlists - works with HydratedBloc state
class MyPlaylistService {
  static final AppLogger _logger = AppLogger('MyPlaylistService');
  static const String _favoritesPlaylistId = 'my_playlist_favorites';
  static const String _favoritesPlaylistName = 'Favorites';
  static const String _favoritesPlaylistDescription = 'My favorite songs';

  /// Generate unique playlist ID with 'my_playlist_' prefix
  static String generateUniquePlaylistId() {
    return 'my_playlist_${const Uuid().v4()}';
  }

  /// Validate playlist ID format
  static bool isValidPlaylistId(String id) {
    return id.startsWith('my_playlist_') && id.length > 12; // 'my_playlist_' + UUID
  }

  /// Create default favorites playlist
  static MyPlaylist createDefaultFavoritesPlaylist() {
    return MyPlaylist(
      id: _favoritesPlaylistId,
      name: _favoritesPlaylistName,
      description: _favoritesPlaylistDescription,
      songIds: [],
      createdAt: DateTime.now(),
      isPublic: false,
      createdBy: 'system',
    );
  }

  /// Create new playlist
  static MyPlaylist createPlaylist({
    required String name,
    required String description,
    List<String> songIds = const [],
    String? coverImage,
    bool isPublic = false,
  }) {
    _logger.i('📝 Creating new playlist: $name');
    
    final now = DateTime.now();
    
    final playlist = MyPlaylist(
      id: generateUniquePlaylistId(),
      name: name,
      description: description,
      songIds: songIds,
      createdAt: now,
      updatedAt: now,
      coverImage: coverImage,
      isPublic: isPublic,
      createdBy: 'user',
      playCount: 0,
    );
    
    _logger.i('✅ Created playlist: $name (ID: ${playlist.id})');
    return playlist;
  }

  /// Update existing playlist
  static MyPlaylist updatePlaylist({
    required MyPlaylist playlist,
    String? name,
    String? description,
    List<String>? songIds,
    String? coverImage,
    bool? isPublic,
  }) {
    _logger.i('📝 Updating playlist: ${playlist.id}');
    
    final updatedPlaylist = playlist.copyWith(
      name: name ?? playlist.name,
      description: description ?? playlist.description,
      songIds: songIds ?? playlist.songIds,
      updatedAt: DateTime.now(),
      coverImage: coverImage ?? playlist.coverImage,
      isPublic: isPublic ?? playlist.isPublic,
    );
    
    _logger.i('✅ Updated playlist: ${updatedPlaylist.name}');
    return updatedPlaylist;
  }

  /// Add song to playlist
  static MyPlaylist addSongToPlaylist({
    required MyPlaylist playlist,
    required String songId,
  }) {
    _logger.i('➕ Adding song $songId to playlist ${playlist.id}');
    
    final updatedPlaylist = playlist.addSong(songId);
    _logger.i('✅ Added song to playlist: ${playlist.name}');
    return updatedPlaylist;
  }

  /// Remove song from playlist
  static MyPlaylist removeSongFromPlaylist({
    required MyPlaylist playlist,
    required String songId,
  }) {
    _logger.i('➖ Removing song $songId from playlist ${playlist.id}');
    
    final updatedPlaylist = playlist.removeSong(songId);
    _logger.i('✅ Removed song from playlist: ${playlist.name}');
    return updatedPlaylist;
  }

  /// Toggle song in favorites
  static MyPlaylist toggleSongInFavorites({
    required MyPlaylist favoritesPlaylist,
    required String songId,
  }) {
    _logger.i('❤️ Toggling song $songId in favorites');
    
    MyPlaylist updatedPlaylist;
    if (favoritesPlaylist.songIds.contains(songId)) {
      updatedPlaylist = favoritesPlaylist.removeSong(songId);
      _logger.i('💔 Removed from favorites');
    } else {
      updatedPlaylist = favoritesPlaylist.addSong(songId);
      _logger.i('❤️ Added to favorites');
    }
    
    return updatedPlaylist;
  }

  /// Check if song is in favorites
  static bool isSongInFavorites({
    required MyPlaylist favoritesPlaylist,
    required String songId,
  }) {
    return favoritesPlaylist.songIds.contains(songId);
  }

  /// Get playlist songs with full Song objects
  static List<Song> getPlaylistSongs({
    required MyPlaylist playlist,
    required List<Song> allSongs,
  }) {
    final playlistSongs = <Song>[];
    for (final songId in playlist.songIds) {
      try {
        final song = allSongs.firstWhere((s) => s.id == songId);
        playlistSongs.add(song);
      } catch (e) {
        _logger.w('⚠️ Song not found: $songId');
      }
    }
    return playlistSongs;
  }

  /// Update playlist duration
  static MyPlaylist updatePlaylistDuration({
    required MyPlaylist playlist,
    required List<Song> allSongs,
  }) {
    final playlistSongs = getPlaylistSongs(
      playlist: playlist,
      allSongs: allSongs,
    );
    
    final totalDuration = playlistSongs.fold<Duration>(
      Duration.zero,
      (total, song) => total + song.duration,
    );
    
    return playlist.copyWith(
      totalDuration: totalDuration,
      updatedAt: DateTime.now(),
    );
  }

  /// Ensure favorites playlist exists in the list
  static List<MyPlaylist> ensureFavoritesPlaylist(List<MyPlaylist> playlists) {
    final hasFavorites = playlists.any((p) => p.id == _favoritesPlaylistId);
    
    if (!hasFavorites) {
      _logger.i('❤️ Adding default favorites playlist to state');
      return [createDefaultFavoritesPlaylist(), ...playlists];
    }
    
    return playlists;
  }

  /// Get favorites playlist from list
  static MyPlaylist? getFavoritesPlaylist(List<MyPlaylist> playlists) {
    try {
      return playlists.firstWhere((p) => p.id == _favoritesPlaylistId);
    } catch (e) {
      return null;
    }
  }

  /// Get user-created playlists (excluding favorites)
  static List<MyPlaylist> getUserPlaylists(List<MyPlaylist> playlists) {
    return playlists.where((p) => p.id != _favoritesPlaylistId).toList();
  }

  /// Validate playlist list for any issues
  static Map<String, dynamic> validatePlaylists(List<MyPlaylist> playlists) {
    int validCount = 0;
    int invalidCount = 0;
    int totalSongs = 0;
    
    for (final playlist in playlists) {
      if (isValidPlaylistId(playlist.id)) {
        validCount++;
        totalSongs += playlist.songIds.length;
      } else {
        invalidCount++;
        _logger.w('⚠️ Invalid playlist ID format: ${playlist.id}');
      }
    }
    
    return {
      'validPlaylistCount': validCount,
      'invalidPlaylistCount': invalidCount,
      'totalSongs': totalSongs,
      'favoritesPlaylistId': _favoritesPlaylistId,
    };
  }
}
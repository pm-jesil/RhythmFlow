import '../../utils/models/playlist_source/playlist_source_model.dart';
import '../../utils/models/song/song_model.dart';
import '../../core/constants/app_constants.dart';

/// Centralized helper for PlaylistSource operations and conversions
class PlaylistSourceHelper {
  
  // ==================== PLAYLIST SOURCE CONVERSION ====================
  
  /// Convert playlist ID to PlaylistSource
  static PlaylistSource? getPlaylistSourceFromId(String? playlistId) {
    if (playlistId == null) return null;
    
    if (playlistId == 'all_songs') {
      return PlaylistSource.allSongs();
    } else if (playlistId.startsWith('album_')) {
      final albumId = playlistId.substring(6);
      return PlaylistSource.album(albumId);
    } else if (playlistId.startsWith('artist_')) {
      final artistId = playlistId.substring(7);
      return PlaylistSource.artist(artistId);
    } else if (playlistId.startsWith('my_playlist_')) {
      final myPlaylistId = playlistId.substring(12);
      return PlaylistSource.myPlaylist(myPlaylistId);
    }
    
    return null;
  }

  /// Convert PlaylistSource to playlist ID
  static String getPlaylistId(PlaylistSource playlistSource) {
    switch (playlistSource.source) {
      case Sources.allSongs:
        return 'all_songs';
      case Sources.album:
        return 'album_${playlistSource.albumId}';
      case Sources.artist:
        return 'artist_${playlistSource.artistId}';
      case Sources.myPlaylist:
        return 'my_playlist_${playlistSource.playlistId}';
      default:
        return 'unknown';
    }
  }

  // ==================== SONG OPERATIONS ====================
  
  /// Get songs from PlaylistSource using MusicState
  static List<Song> getPlaylistSongs(
    PlaylistSource playlistSource,
    dynamic state,
  ) {
    switch (playlistSource.source) {
      case Sources.allSongs:
        return state.allSongs;
      case Sources.album:
        if (playlistSource.albumId == null) return state.allSongs;
        final album = state.albumList.firstWhere(
          (album) => album.id == playlistSource.albumId,
          orElse: () => throw Exception('Album not found: ${playlistSource.albumId}'),
        );
        return getSongsFromIds(album.songIds, state.allSongs);
      case Sources.artist:
        if (playlistSource.artistId == null) return state.allSongs;
        final artist = state.artistList.firstWhere(
          (artist) => artist.id == playlistSource.artistId,
          orElse: () => throw Exception('Artist not found: ${playlistSource.artistId}'),
        );
        return getSongsFromIds(artist.songIds, state.allSongs);
      case Sources.myPlaylist:
        if (playlistSource.playlistId == null) return state.allSongs;
        final myPlaylist = state.myPlaylist.firstWhere(
          (playlist) => playlist.id == playlistSource.playlistId,
          orElse: () => throw Exception('MyPlaylist not found: ${playlistSource.playlistId}'),
        );
        return getSongsFromIds(myPlaylist.songIds, state.allSongs);
      default:
        return state.allSongs;
    }
  }

  /// Extract song IDs from a list of songs
  static List<String> getSongIds(List<Song> songs) {
    return songs.map((song) => song.id).toList();
  }

  /// Get songs from song IDs using allSongs list
  static List<Song> getSongsFromIds(List<String> songIds, List<Song> allSongs) {
    return songIds
        .map(
          (songId) => allSongs.firstWhere(
            (song) => song.id == songId,
            orElse: () => throw Exception('Song not found: $songId'),
          ),
        )
        .toList();
  }

  // ==================== VALIDATION ====================
  
  /// Validate that PlaylistSource exists in the current state
  static bool validatePlaylistSource(PlaylistSource playlistSource, dynamic state) {
    try {
      switch (playlistSource.source) {
        case Sources.allSongs:
          return true;
        case Sources.album:
          if (playlistSource.albumId == null) return false;
          return state.albumList.any((album) => album.id == playlistSource.albumId);
        case Sources.artist:
          if (playlistSource.artistId == null) return false;
          return state.artistList.any((artist) => artist.id == playlistSource.artistId);
        case Sources.myPlaylist:
          if (playlistSource.playlistId == null) return false;
          return state.myPlaylist.any((playlist) => playlist.id == playlistSource.playlistId);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get human-readable type name for PlaylistSource
  static String getPlaylistSourceTypeName(PlaylistSource playlistSource) {
    switch (playlistSource.source) {
      case Sources.allSongs:
        return 'All Songs';
      case Sources.album:
        return 'Album';
      case Sources.artist:
        return 'Artist';
      case Sources.myPlaylist:
        return 'Playlist';
      default:
        return 'Unknown';
    }
  }

  /// Get display name for PlaylistSource (e.g., album name, artist name)
  static String? getPlaylistSourceDisplayName(PlaylistSource playlistSource, dynamic state) {
    try {
      switch (playlistSource.source) {
        case Sources.allSongs:
          return 'All Songs';
        case Sources.album:
          if (playlistSource.albumId == null) return null;
          final album = state.albumList.firstWhere(
            (album) => album.id == playlistSource.albumId,
            orElse: () => throw Exception('Album not found'),
          );
          return album.name;
        case Sources.artist:
          if (playlistSource.artistId == null) return null;
          final artist = state.artistList.firstWhere(
            (artist) => artist.id == playlistSource.artistId,
            orElse: () => throw Exception('Artist not found'),
          );
          return artist.name;
        case Sources.myPlaylist:
          if (playlistSource.playlistId == null) return null;
          final playlist = state.myPlaylist.firstWhere(
            (playlist) => playlist.id == playlistSource.playlistId,
            orElse: () => throw Exception('Playlist not found'),
          );
          return playlist.name;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==================== UTILITY METHODS ====================
  
  /// Check if two PlaylistSource objects are equal
  static bool areEqual(PlaylistSource source1, PlaylistSource source2) {
    return source1.source == source2.source &&
           source1.albumId == source2.albumId &&
           source1.artistId == source2.artistId &&
           source1.playlistId == source2.playlistId;
  }

  /// Create a copy of PlaylistSource with updated fields
  static PlaylistSource copyWith(
    PlaylistSource source, {
    String? sourceType,
    String? albumId,
    String? artistId,
    String? playlistId,
  }) {
    return PlaylistSource(
      source: sourceType ?? source.source,
      albumId: albumId ?? source.albumId,
      artistId: artistId ?? source.artistId,
      playlistId: playlistId ?? source.playlistId,
    );
  }

  /// Get song count for a PlaylistSource
  static int getSongCount(PlaylistSource playlistSource, dynamic state) {
    try {
      switch (playlistSource.source) {
        case Sources.allSongs:
          return state.allSongs.length;
        case Sources.album:
          if (playlistSource.albumId == null) return 0;
          final album = state.albumList.firstWhere(
            (album) => album.id == playlistSource.albumId,
            orElse: () => throw Exception('Album not found'),
          );
          return album.songIds.length;
        case Sources.artist:
          if (playlistSource.artistId == null) return 0;
          final artist = state.artistList.firstWhere(
            (artist) => artist.id == playlistSource.artistId,
            orElse: () => throw Exception('Artist not found'),
          );
          return artist.songIds.length;
        case Sources.myPlaylist:
          if (playlistSource.playlistId == null) return 0;
          final playlist = state.myPlaylist.firstWhere(
            (playlist) => playlist.id == playlistSource.playlistId,
            orElse: () => throw Exception('Playlist not found'),
          );
          return playlist.songIds.length;
        default:
          return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Check if PlaylistSource is empty (no songs)
  static bool isEmpty(PlaylistSource playlistSource, dynamic state) {
    return getSongCount(playlistSource, state) == 0;
  }

  /// Get all available PlaylistSource types
  static List<String> getAvailableSourceTypes() {
    return [
      Sources.allSongs,
      Sources.album,
      Sources.artist,
      Sources.myPlaylist,
    ];
  }
}

import 'dart:async';
import '../logger/logger.dart';
import '../models/song/song_model.dart';
import '../models/artist/artist_model.dart';
import '../models/album/album_model.dart';
import '../models/my_playlist/my_playlist_model.dart';
import '../models/playlist_source/playlist_source_model.dart';

/// Service to track play counts for songs, artists, albums, and playlists
class PlayCountTrackingService {
  static final AppLogger _logger = AppLogger('PlayCountTrackingService');
  
  // Track current playing song and its progress
  static Song? _currentSong;
  static Duration _currentPosition = Duration.zero;
  static Duration _currentDuration = Duration.zero;
  static Timer? _progressTimer;
  static bool _hasTrackedPlay = false;
  static String? _currentPlaylistId;
  static PlaylistSource? _currentPlaylistSource;
  
  // Callbacks for updating models
  static Function(Song)? onSongPlayCountUpdated;
  static Function(Artist)? onArtistPlayCountUpdated;
  static Function(Album)? onAlbumPlayCountUpdated;
  static Function(MyPlaylist)? onPlaylistPlayCountUpdated;
  
  /// Start tracking a song's play progress
  static void startTracking({
    required Song song,
    required Duration currentPosition,
    required Duration duration,
    String? playlistId,
    PlaylistSource? playlistSource,
  }) {
    _logger.i('🎵 Starting play count tracking for: "${song.title}" | Position: ${currentPosition.inSeconds}s | Duration: ${duration.inSeconds}s');
    
    _currentSong = song;
    _currentPosition = currentPosition;
    _currentDuration = duration;
    _currentPlaylistId = playlistId;
    _currentPlaylistSource = playlistSource;
    _hasTrackedPlay = false;
    
    // Start progress tracking timer
    _startProgressTimer();
  }
  
  /// Update current position during playback
  static void updatePosition(Duration position) {
    _currentPosition = position;
    
    // Check if we should track the play count (40% threshold)
    if (!_hasTrackedPlay && _currentSong != null && _currentDuration.inMilliseconds > 0) {
      final playPercentage = _currentPosition.inMilliseconds / _currentDuration.inMilliseconds;
      
      if (playPercentage >= 0.4) { // 40% threshold
        _trackPlayCount();
      }
    }
  }
  
  /// Stop tracking current song
  static void stopTracking() {
    _logger.i('🛑 Stopping play count tracking');
    
    _progressTimer?.cancel();
    _progressTimer = null;
    _currentSong = null;
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
    _hasTrackedPlay = false;
    _currentPlaylistId = null;
    _currentPlaylistSource = null;
  }
  
  /// Start progress tracking timer (backup timer in case position updates fail)
  static void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentSong != null && !_hasTrackedPlay && _currentDuration.inMilliseconds > 0) {
        final playPercentage = _currentPosition.inMilliseconds / _currentDuration.inMilliseconds;
        
        if (playPercentage >= 0.4) { // 40% threshold
          _trackPlayCount();
          timer.cancel();
        }
      }
    });
  }
  
  /// Track play count for current song and related entities
  static void _trackPlayCount() {
    if (_currentSong == null || _hasTrackedPlay) return;
    
    _hasTrackedPlay = true;
    _logger.i('📊 Tracking play count for: "${_currentSong!.title}"');
    
    try {
      // Update song play count
      final updatedSong = _currentSong!.copyWith(
        playCount: (_currentSong!.playCount ?? 0) + 1,
        lastPlayed: DateTime.now(),
      );
      onSongPlayCountUpdated?.call(updatedSong);
      
      // Update artist play count
      _updateArtistPlayCount(_currentSong!);
      
      // Update album play count
      _updateAlbumPlayCount(_currentSong!);
      
      // Update playlist play count if playing from a specific playlist
      if (_currentPlaylistId != null && _currentPlaylistSource != null) {
        _updatePlaylistPlayCount(_currentPlaylistId!, _currentPlaylistSource!);
      }
      
      _logger.i('✅ Play count tracking completed for: "${_currentSong!.title}"');
    } catch (e) {
      _logger.e('❌ Error tracking play count: $e');
    }
  }
  
  /// Update artist play count
  static void _updateArtistPlayCount(Song song) {
    try {
      // Update play count for all artists of the song
      for (final artistName in song.artists) {
        final artistId = _generateArtistId(artistName);
        
        // Create or update artist with incremented play count
        final updatedArtist = Artist(
          id: artistId,
          name: artistName,
          songIds: [song.id], // This will be updated by the music service
          createdAt: DateTime.now(),
          playCount: 1, // This will be incremented by the music service
        );
        
        onArtistPlayCountUpdated?.call(updatedArtist);
      }
    } catch (e) {
      _logger.e('❌ Error updating artist play count: $e');
    }
  }
  
  /// Update album play count
  static void _updateAlbumPlayCount(Song song) {
    try {
      // Update play count for all albums of the song
      for (final albumName in song.albums) {
        final albumId = _generateAlbumId(albumName);
        
        // Create or update album with incremented play count
        final updatedAlbum = Album(
          id: albumId,
          name: albumName,
          songIds: [song.id], // This will be updated by the music service
          createdAt: DateTime.now(),
          playCount: 1, // This will be incremented by the music service
        );
        
        onAlbumPlayCountUpdated?.call(updatedAlbum);
      }
    } catch (e) {
      _logger.e('❌ Error updating album play count: $e');
    }
  }
  
  /// Update playlist play count
  static void _updatePlaylistPlayCount(String playlistId, PlaylistSource playlistSource) {
    try {
      if (playlistSource.source == 'my_playlist') {
        // Extract the actual playlist ID from the formatted ID
        String actualPlaylistId = playlistId;
        if (playlistId.startsWith('my_playlist_')) {
          actualPlaylistId = playlistId.substring(12); // Remove 'my_playlist_' prefix
        }
        
        // For MyPlaylist, we need to update the specific playlist
        final updatedPlaylist = MyPlaylist(
          id: actualPlaylistId,
          name: 'Playlist', // This will be updated by the music service
          description: 'User playlist',
          songIds: [], // This will be updated by the music service
          createdAt: DateTime.now(),
          playCount: 1, // This will be incremented by the music service
        );
        
        onPlaylistPlayCountUpdated?.call(updatedPlaylist);
        _logger.i('📋 Updated playlist play count for playlist: $actualPlaylistId');
      }
    } catch (e) {
      _logger.e('❌ Error updating playlist play count: $e');
    }
  }
  
  /// Generate consistent artist ID
  static String _generateArtistId(String artistName) {
    return 'artist_${artistName.hashCode}';
  }
  
  /// Generate consistent album ID
  static String _generateAlbumId(String albumName) {
    return 'album_${albumName.hashCode}';
  }
  
  /// Get current tracking status
  static Map<String, dynamic> getTrackingStatus() {
    return {
      'currentSong': _currentSong?.title,
      'currentPosition': _currentPosition.inSeconds,
      'currentDuration': _currentDuration.inSeconds,
      'hasTrackedPlay': _hasTrackedPlay,
      'playlistId': _currentPlaylistId,
      'playlistSource': _currentPlaylistSource?.toString(),
    };
  }
  
  /// Force track play count (for testing or manual tracking)
  static void forceTrackPlayCount({
    required Song song,
    String? playlistId,
    PlaylistSource? playlistSource,
  }) {
    _logger.i('🔧 Force tracking play count for: "${song.title}"');
    
    _currentSong = song;
    _currentPlaylistId = playlistId;
    _currentPlaylistSource = playlistSource;
    _hasTrackedPlay = false;
    
    _trackPlayCount();
  }
}

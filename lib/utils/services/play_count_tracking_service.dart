import 'dart:async';
import '../logger/logger.dart';
import '../models/song/song_model.dart';
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
  
  // Callback for updating play counts
  static Function(String songId)? onUpdatePlayCount;

  /// The song currently being tracked (for tests / diagnostics).
  static String? get trackedSongId => _currentSong?.id;
  
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
    _logger.i('🎤 Artists: ${_currentSong!.artists.length} | 💿 Albums: ${_currentSong!.albums.length}');
    
    try {
      // Just pass the song ID to the MusicBloc
      onUpdatePlayCount?.call(_currentSong!.id);
      
      _logger.i('✅ Play count tracking completed for: "${_currentSong!.title}"');
    } catch (e) {
      _logger.e('❌ Error tracking play count: $e');
    }
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

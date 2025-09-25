import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:injectable/injectable.dart';
import '../models/song/song_model.dart';
import '../models/playlist_source/playlist_source_model.dart';
import '../logger/logger.dart';
import 'enhanced_notification_service.dart';
import 'play_count_tracking_service.dart';

@singleton
class AudioService {
  static final AppLogger _logger = AppLogger('AudioService');
  
  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Callback to notify when song changes
  Function(Song song)? onSongChanged;
  
  // Play count tracking context (used by PlayCountTrackingService)
  
  // Stream controllers for state updates
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<PlayerState> _playerStateController = StreamController<PlayerState>.broadcast();
  
  // Position tracking callback
  Function(Duration)? onPositionChanged;
  
  // Current song info
  Song? _currentSong;
  
  // Removed playback settings - handled by MusicBloc
  
  // Getters
  AudioPlayer get player => _audioPlayer;
  Song? get currentSong => _currentSong;
  
  // Streams
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  
  // Current values
  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  bool get isPlaying => _audioPlayer.playing;
  PlayerState get playerState => _audioPlayer.playerState;
  
  AudioService() {
    try {
      _initializeAudioPlayer();
    } catch (e) {
      _logger.e('❌ Error initializing audio player: $e');
    }
  }
  
  /// Initialize audio player and set up listeners
  void _initializeAudioPlayer() {
    _logger.i('Initializing audio player...');
    
    // Set up position listener
    _audioPlayer.positionStream.listen(
      (position) {
        _positionController.add(position);
        
        // Update play count tracking with current position
        PlayCountTrackingService.updatePosition(position);
        
        // Notify position change callback
        onPositionChanged?.call(position);
      },
      onError: (error) {
        _logger.e('❌ Error in position stream: $error');
      },
    );
    
    // Set up duration listener
    _audioPlayer.durationStream.listen(
      (duration) {
        if (duration != null) {
          _durationController.add(duration);
        }
      },
      onError: (error) {
        _logger.e('❌ Error in duration stream: $error');
      },
    );
    
    // Set up playing state listener
    _audioPlayer.playingStream.listen(
      (playing) {
        _logger.i('Playing state changed: $playing | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s');
        _playingController.add(playing);
      },
      onError: (error) {
        _logger.e('❌ Error in playing stream: $error');
      },
    );
    
    // Set up player state listener
    _audioPlayer.playerStateStream.listen(
      (state) {
        _logger.i('Player state changed: ${state.processingState} | Playing: ${state.playing} | Song: ${_currentSong?.title ?? "None"}');
        _playerStateController.add(state);
      },
      onError: (error) {
        _logger.e('❌ Error in player state stream: $error');
      },
    );
    
    _logger.i('Audio player initialized successfully');
  }
  
  /// Load a song without playing it (for restoration purposes)
  Future<void> loadSong(Song song, {String? playlistId, PlaylistSource? playlistSource}) async {
    try {
      _logger.i('📁 Loading song: "${song.title}" by ${song.artists.join(', ')} | Duration: ${song.duration.inSeconds}s | File: ${song.path}');
      
      // Update current song and playlist context
      _currentSong = song;
      
      // Create media item for notification
      final mediaItem = MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artists.join(', '),
        album: song.albums.isNotEmpty ? song.albums.first : null,
        duration: song.duration,
        artUri: song.albumArt != null ? Uri.file(song.albumArt!) : null,
      );
      
      // Set audio source
      final audioSource = AudioSource.file(
        song.path,
        tag: mediaItem,
      );
      
      await _audioPlayer.setAudioSource(audioSource);
      
      _logger.i('✅ Song loaded successfully (not playing)');
    } catch (e) {
      _logger.e('❌ Error loading song: $e');
      rethrow;
    }
  }
  
  /// Play a specific song
  Future<void> playSong(Song song, {String? playlistId, PlaylistSource? playlistSource}) async {
    try {
      _logger.i('🎵 Starting to play song: "${song.title}" by ${song.artists.join(', ')} | Duration: ${song.duration.inSeconds}s | File: ${song.path}');
      
      // Update current song and playlist context
      _currentSong = song;
      
      _logger.d('✅ Updated current song: ${_currentSong?.title}');
      
      // Notify listeners that song has changed
      onSongChanged?.call(song);
      
      // Validate file exists
      final file = File(song.path);
      if (!await file.exists()) {
        _logger.e('❌ Song file not found: ${song.path}');
        throw Exception('Song file not found');
      }
      
      _logger.d('📁 File exists, size: ${await file.length()} bytes');
      
      // Create MediaItem and play directly
        final mediaItem = _createMediaItem(song);
        final audioSource = AudioSource.file(
          song.path,
          tag: mediaItem,
        );
        
        await _audioPlayer.setAudioSource(audioSource);
        await _audioPlayer.play();
        
        // Start play count tracking
        final duration = _audioPlayer.duration ?? song.duration;
        PlayCountTrackingService.startTracking(
          song: song,
          currentPosition: _audioPlayer.position,
          duration: duration,
          playlistId: playlistId,
          playlistSource: playlistSource,
        );
      
      _logger.i('🎉 Successfully started playing: "${song.title}" | Position: ${_audioPlayer.position.inSeconds}s | Duration: ${_audioPlayer.duration?.inSeconds ?? 0}s');
    } catch (e) {
      _logger.e('❌ Error playing song "${song.title}": $e');
      rethrow;
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    try {
      _logger.i('⏸️ Pausing playback | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s');
      await _audioPlayer.pause();
      _logger.i('✅ Playback paused successfully | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s');
    } catch (e) {
      _logger.e('❌ Error pausing playback: $e | Song: ${_currentSong?.title ?? "None"}');
      rethrow;
    }
  }
  
  /// Resume playback
  Future<void> resume() async {
    try {
      _logger.i('▶️ Resuming playback | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s');
      await _audioPlayer.play();
      _logger.i('✅ Playback resumed successfully | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s');
    } catch (e) {
      _logger.e('❌ Error resuming playback: $e | Song: ${_currentSong?.title ?? "None"}');
      rethrow;
    }
  }
  
  /// Stop playback
  Future<void> stop() async {
    try {
      // Stop play count tracking
      PlayCountTrackingService.stopTracking();
      
      await _audioPlayer.stop();
      _currentSong = null;
      _logger.i('Playback stopped');
    } catch (e) {
      _logger.e('Error stopping playback: $e');
      rethrow;
    }
  }
  
  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      if (_currentSong == null) {
        _logger.w('⚠️ Cannot seek - no current song loaded');
        return;
      }
      
      _logger.i('🔍 Seeking to position: ${position.inSeconds}s | Song: ${_currentSong?.title ?? "None"} | Current: ${_audioPlayer.position.inSeconds}s');
      
      // Check if audio source is loaded and player is ready
      if (_audioPlayer.audioSource == null) {
        _logger.w('⚠️ Cannot seek - no audio source loaded');
        return;
      }
      
      // Check if player is in a valid state for seeking
      final playerState = _audioPlayer.playerState;
      if (playerState.processingState == ProcessingState.idle) {
        _logger.w('⚠️ Cannot seek - player is in idle state');
        return;
      }
      
      // Use the seek method directly
      await _audioPlayer.seek(position);
      _logger.i('✅ Seeked successfully to: ${position.inSeconds}s | Song: ${_currentSong?.title ?? "None"} | New position: ${_audioPlayer.position.inSeconds}s');
    } catch (e) {
      _logger.e('❌ Error seeking to ${position.inSeconds}s: $e | Song: ${_currentSong?.title ?? "None"}');
      rethrow;
    }
  }
  
  // Removed playNext, playPrevious, setShuffle, setRepeat, and _handleSongCompletion methods
  // All queue management and playback logic is now handled by MusicBloc
  
  /// Set volume
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      _logger.i('🔊 Setting volume: $clampedVolume | Current: ${_audioPlayer.volume}');
      await _audioPlayer.setVolume(clampedVolume);
      _logger.i('✅ Volume updated: ${_audioPlayer.volume}');
    } catch (e) {
      _logger.e('❌ Error setting volume to $volume: $e');
      rethrow;
    }
  }
  
  /// Get current volume
  double get volume => _audioPlayer.volume;
  
  /// Check if a specific song is currently loaded
  bool isSongLoaded(String songId) {
    return _currentSong?.id == songId;
  }
  
  /// Set callback for song changes
  void setSongChangedCallback(Function(Song song) callback) {
    onSongChanged = callback;
    _logger.i('✅ Song change callback set');
  }
  
  /// Set callback for position changes
  void setPositionChangedCallback(Function(Duration position) callback) {
    onPositionChanged = callback;
    _logger.i('✅ Position change callback set');
  }
  
  /// Create MediaItem for notification and lock screen
  MediaItem _createMediaItem(Song song) {
    // Use enhanced notification service for better MediaItem creation
    return EnhancedNotificationService.createEnhancedMediaItem(song);
  }

  // Removed playlist management functions - handled by MusicBloc

  /// Get current MediaItem
  MediaItem? get currentMediaItem {
    if (_currentSong == null) return null;
    return _createMediaItem(_currentSong!);
  }

  /// Dispose resources
  Future<void> dispose() async {
    _logger.i('Disposing audio service...');
    
    await _audioPlayer.dispose();
    await _positionController.close();
    await _durationController.close();
    await _playingController.close();
    await _playerStateController.close();
    
    _logger.i('Audio service disposed');
  }
}

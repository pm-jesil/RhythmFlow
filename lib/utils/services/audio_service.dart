import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import '../models/song/song_model.dart';
import '../models/playlist_source/playlist_source_model.dart';
import '../logger/logger.dart';
import 'enhanced_notification_service.dart';
import 'play_count_tracking_service.dart';
import 'audio_handler.dart';

@singleton
class AudioService {
  static final AppLogger _logger = AppLogger('AudioService');

  // Audio handler (bridges audio_service with just_audio)
  RhythmFlowAudioHandler? _audioHandler;
  
  // Fallback player (used until handler is set)
  AudioPlayer? _fallbackPlayer;
  
  // Get the audio player from handler or fallback
  AudioPlayer get _audioPlayer {
    if (_audioHandler != null) {
      return _audioHandler!.player;
    }
    // Create fallback player if not exists
    _fallbackPlayer ??= AudioPlayer();
    return _fallbackPlayer!;
  }

  // Callback to notify when song changes
  Function(Song song)? onSongChanged;

  /// Called with the real duration reported by the player after a song is
  /// loaded (used to fill in songs whose tags had no readable duration).
  void Function(Song song, Duration duration)? onDurationResolved;
  
  // Callback to notify when song is invalid
  Function(Song song, String? playlistId, PlaylistSource? playlistSource)? onInvalidSong;

  // Callbacks for skip actions (from notification buttons)
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;
  
  // Callbacks for shuffle and repeat actions
  // Changed: onToggleShuffle now triggers 3-state cycle (None → AI → Normal → None)
  VoidCallback? onToggleShuffle;
  VoidCallback? onToggleRepeat;
  
  // Callbacks for play/pause actions
  VoidCallback? onPlay;
  VoidCallback? onPause;

  // Stream controllers for state updates
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  // Stream subscriptions (to cancel when reinitializing)
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Position tracking callback
  Function(Duration)? onPositionChanged;

  // Current song info
  Song? _currentSong;

  // Getters
  AudioPlayer get player => _audioPlayer;
  Song? get currentSong => _currentSong;
  
  // Set audio handler (called after audio_service initialization)
  void setAudioHandler(RhythmFlowAudioHandler handler) {
    _audioHandler = handler;
    _logger.i('✅ AudioHandler set for AudioService');
    
    // Wire skip callbacks from AudioHandler to AudioService callbacks
    handler.setSkipCallbacks(
      onNext: () {
        _logger.i('⏭️ Skip to next requested from notification');
        onSkipToNext?.call();
      },
      onPrevious: () {
        _logger.i('⏮️ Skip to previous requested from notification');
        onSkipToPrevious?.call();
      },
    );

    // Wire shuffle and repeat callbacks
    handler.setShuffleRepeatCallbacks(
      onShuffle: () {
        _logger.i('🔀 Shuffle button pressed - triggering 3-state cycle');
        // Trigger the same logic as music player screen: None → AI → Normal → None
        onToggleShuffle?.call();
      },
      onRepeat: () {
        _logger.i('🔄 Repeat toggled');
        onToggleRepeat?.call();
      },
    );

    // Wire play/pause callbacks
    handler.setPlayPauseCallbacks(
      onPlay: () {
        _logger.i('▶️ Play requested from notification');
        onPlay?.call();
      },
      onPause: () {
        _logger.i('⏸️ Pause requested from notification');
        onPause?.call();
      },
    );
    
    // Dispose fallback player if it exists (handler has its own player)
    if (_fallbackPlayer != null) {
      _fallbackPlayer!.dispose();
      _fallbackPlayer = null;
    }
    
    // Reinitialize listeners with the handler's player
    // This is critical because listeners were set up on fallback player
    _initializeAudioPlayer();
    _logger.i('✅ AudioService listeners reinitialized with AudioHandler player');
  }
  
  /// Set callbacks for skip actions (called by MusicBloc)
  void setSkipCallbacks({
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) {
    onSkipToNext = onNext;
    onSkipToPrevious = onPrevious;
    _logger.i('✅ Skip callbacks set in AudioService');
  }

  /// Set callbacks for shuffle and repeat actions (called by MusicBloc)
  void setShuffleRepeatCallbacks({
    VoidCallback? onShuffle,
    VoidCallback? onRepeat,
  }) {
    onToggleShuffle = onShuffle;
    onToggleRepeat = onRepeat;
    _logger.i('✅ Shuffle/Repeat callbacks set in AudioService');
  }

  /// Set callbacks for play/pause actions (called by MusicBloc)
  void setPlayPauseCallbacks({
    VoidCallback? onPlay,
    VoidCallback? onPause,
  }) {
    this.onPlay = onPlay;
    this.onPause = onPause;
    _logger.i('✅ Play/Pause callbacks set in AudioService');
  }

  /// Update shuffle and repeat state in notification
  void updateShuffleRepeatState({
    bool? isShuffle,
    bool? isAiShuffle,
    int? repeatModeIndex,
  }) {
    if (_audioHandler != null) {
      if (isShuffle != null) {
        _audioHandler!.updateShuffleState(isShuffle);
      }
      if (isAiShuffle != null) {
        _audioHandler!.updateAiShuffleState(isAiShuffle);
      }
      if (repeatModeIndex != null) {
        _audioHandler!.updateRepeatState(repeatModeIndex);
      }
      _logger.i('📱 Updated notification shuffle/repeat state');
    }
  }

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

    // Cancel existing subscriptions if any
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _playerStateSubscription?.cancel();

    // Set up position listener
    _positionSubscription = _audioPlayer.positionStream.listen(
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
    _durationSubscription = _audioPlayer.durationStream.listen(
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
    _playingSubscription = _audioPlayer.playingStream.listen(
      (playing) {
        _logger.i(
          'Playing state changed: $playing | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s',
        );
        _playingController.add(playing);
      },
      onError: (error) {
        _logger.e('❌ Error in playing stream: $error');
      },
    );

    // Set up player state listener
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (state) {
        _logger.i(
          'Player state changed: ${state.processingState} | Playing: ${state.playing} | Song: ${_currentSong?.title ?? "None"}',
        );
        _playerStateController.add(state);
      },
      onError: (error) {
        _logger.e('❌ Error in player state stream: $error');
      },
    );

    _logger.i('Audio player initialized successfully');
  }

  /// Load a song without playing it (for restoration purposes)
  Future<void> loadSong(
    Song song, {
    String? playlistId,
    PlaylistSource? playlistSource,
  }) async {
    try {
      _logger.i(
        '📁 Loading song: "${song.title}" by ${song.artists.join(', ')} | Duration: ${song.duration.inSeconds}s | File: ${song.path}',
      );

      // Update current song and playlist context
      _currentSong = song;

      // Create media item for notification
      final mediaItem = EnhancedNotificationService.createEnhancedMediaItem(song);

      // Set audio source (no tag needed - we'll update through audio_service)
      final audioSource = AudioSource.file(song.path);

      final resolvedDuration = await _audioPlayer.setAudioSource(audioSource);
      if (resolvedDuration != null &&
          resolvedDuration > Duration.zero &&
          song.duration <= Duration.zero) {
        onDurationResolved?.call(song, resolvedDuration);
      }
      
      // Update media item in audio_service for notification
      _audioHandler?.updateMediaItem(mediaItem);

      _logger.i('✅ Song loaded successfully (not playing)');
    } catch (e) {
      _logger.e('❌ Error loading song: $e');
      rethrow;
    }
  }

  /// Play a specific song
  Future<void> playSong(
    Song song, {
    String? playlistId,
    PlaylistSource? playlistSource,
  }) async {
    try {
      _logger.i(
        '🎵 Starting to play song: "${song.title}" by ${song.artists.join(', ')} | Duration: ${song.duration.inSeconds}s | File: ${song.path}',
      );

      // Update current song and playlist context
      _currentSong = song;

      _logger.d('✅ Updated current song: ${_currentSong?.title}');

      // Notify listeners that song has changed
      onSongChanged?.call(song);

      // Validate file exists
      final file = File(song.path);
      if (!await file.exists()) {
        _logger.e('❌ Song file not found: ${song.path}');

        // Instead of throwing exception, handle gracefully
        _handleInvalidSong(song, playlistId, playlistSource);
        return; // Exit gracefully
      }

      _logger.d('📁 File exists, size: ${await file.length()} bytes');

      // Create MediaItem and play directly
      final mediaItem = _createMediaItem(song);
      final audioSource = AudioSource.file(song.path);

      await _audioPlayer.setAudioSource(audioSource);
      
      // Update media item in audio_service for notification BEFORE playing
      // This ensures the notification appears immediately
      // Note: Shuffle/repeat state should already be synced by MusicBloc before playSong is called
      await _audioHandler?.updateMediaItem(mediaItem);
      
      // Start playback - this triggers PlaybackState update which shows notification
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

      _logger.i(
        '🎉 Successfully started playing: "${song.title}" | Position: ${_audioPlayer.position.inSeconds}s | Duration: ${_audioPlayer.duration?.inSeconds ?? 0}s',
      );
    } catch (e) {
      _logger.e('❌ Error playing song "${song.title}": $e');
      // Handle other playback errors gracefully
      _handleInvalidSong(song, playlistId, playlistSource);
    }
  }

  /// Handle invalid song gracefully
  void _handleInvalidSong(
    Song song,
    String? playlistId,
    PlaylistSource? playlistSource,
  ) {
    _logger.w('🚫 Handling invalid song: "${song.title}"');

    // Notify the bloc to handle the invalid song
    if (onInvalidSong != null) {
      onInvalidSong!(song, playlistId, playlistSource);
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      _logger.i(
        '⏸️ Pausing playback | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s',
      );
      await _audioPlayer.pause();
      _logger.i(
        '✅ Playback paused successfully | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s',
      );
    } catch (e) {
      _logger.e(
        '❌ Error pausing playback: $e | Song: ${_currentSong?.title ?? "None"}',
      );
      rethrow;
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      _logger.i(
        '▶️ Resuming playback | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s',
      );
      
      // Ensure MediaItem is set in AudioHandler before resuming
      // This is critical for notification to appear when resuming
      if (_currentSong != null && _audioHandler != null) {
        final mediaItem = _createMediaItem(_currentSong!);
        await _audioHandler!.updateMediaItem(mediaItem);
        _logger.i('📱 MediaItem updated for resume - notification should appear');
      }
      
      await _audioPlayer.play();
      _logger.i(
        '✅ Playback resumed successfully | Song: ${_currentSong?.title ?? "None"} | Position: ${_audioPlayer.position.inSeconds}s',
      );
    } catch (e) {
      _logger.e(
        '❌ Error resuming playback: $e | Song: ${_currentSong?.title ?? "None"}',
      );
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
      
      // Clear media item from notification
      await _audioHandler?.clearMediaItem();
      
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

      _logger.i(
        '🔍 Seeking to position: ${position.inSeconds}s | Song: ${_currentSong?.title ?? "None"} | Current: ${_audioPlayer.position.inSeconds}s',
      );

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
      _logger.i(
        '✅ Seeked successfully to: ${position.inSeconds}s | Song: ${_currentSong?.title ?? "None"} | New position: ${_audioPlayer.position.inSeconds}s',
      );
    } catch (e) {
      _logger.e(
        '❌ Error seeking to ${position.inSeconds}s: $e | Song: ${_currentSong?.title ?? "None"}',
      );
      rethrow;
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      _logger.i(
        '🔊 Setting volume: $clampedVolume | Current: ${_audioPlayer.volume}',
      );
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

  /// Set callback for invalid songs
  void setInvalidSongCallback(Function(Song song, String? playlistId, PlaylistSource? playlistSource) callback) {
    onInvalidSong = callback;
    _logger.i('✅ Invalid song callback set');
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      _logger.i('⚡ Setting playback speed: ${speed}x');
      await _audioPlayer.setSpeed(speed);
      _logger.i('✅ Playback speed set to: ${speed}x');
    } catch (e) {
      _logger.e('❌ Error setting playback speed: $e');
      rethrow;
    }
  }

  /// Get current playback speed
  double get speed => _audioPlayer.speed;

  /// Create MediaItem for notification and lock screen
  MediaItem _createMediaItem(Song song) {
    // Use enhanced notification service for better MediaItem creation
    return EnhancedNotificationService.createEnhancedMediaItem(song);
  }

  /// Get current MediaItem
  MediaItem? get currentMediaItem {
    if (_currentSong == null) return null;
    return _createMediaItem(_currentSong!);
  }

  /// Dispose resources
  Future<void> dispose() async {
    _logger.i('Disposing audio service...');

    // Cancel subscriptions
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playingSubscription?.cancel();
    await _playerStateSubscription?.cancel();

    // Dispose fallback player if exists
    if (_fallbackPlayer != null) {
      await _fallbackPlayer!.dispose();
      _fallbackPlayer = null;
    }
    
    await _positionController.close();
    await _durationController.close();
    await _playingController.close();
    await _playerStateController.close();

    _logger.i('Audio service disposed');
  }
}

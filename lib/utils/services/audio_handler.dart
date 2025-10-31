import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../logger/logger.dart';

/// AudioHandler that bridges audio_service with just_audio
/// This enables background playback and notification controls
class RhythmFlowAudioHandler extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  static final AppLogger _logger = AppLogger('RhythmFlowAudioHandler');

  final AudioPlayer _player = AudioPlayer();

  // Shuffle and Repeat state
  bool _isShuffle = false;
  bool _isAiShuffle = false; // Track AI shuffle state
  int _repeatModeIndex = 0; // 0: off, 1: repeat one, 2: loop

  // Custom action IDs for shuffle and repeat
  static const String shuffleActionId = 'com.technexa.rhythmflow.SHUFFLE';
  static const String repeatActionId = 'com.technexa.rhythmflow.REPEAT';
  
  static final CustomMediaAction shuffleAction = CustomMediaAction(
    name: 'Shuffle',
  );
  static final CustomMediaAction repeatAction = CustomMediaAction(
    name: 'Repeat',
  );

  RhythmFlowAudioHandler() {
    _initializePlayer();
  }

  /// Update shuffle state
  void updateShuffleState(bool isShuffle) {
    if (_isShuffle != isShuffle) {
      _isShuffle = isShuffle;
      _logger.i('🔀 Shuffle state updated: $isShuffle');
      _updatePlaybackState();
    }
  }

  /// Update AI shuffle state
  void updateAiShuffleState(bool isAiShuffle) {
    if (_isAiShuffle != isAiShuffle) {
      _isAiShuffle = isAiShuffle;
      _logger.i('✨ AI Shuffle state updated: $isAiShuffle');
      _updatePlaybackState();
    }
  }

  /// Update repeat state
  void updateRepeatState(int repeatModeIndex) {
    if (_repeatModeIndex != repeatModeIndex) {
      _repeatModeIndex = repeatModeIndex;
      _logger.i('🔄 Repeat state updated: $repeatModeIndex (${_getRepeatDescription(repeatModeIndex)})');
      _updatePlaybackState();
    }
  }

  String _getRepeatDescription(int mode) {
    switch (mode) {
      case 0: return 'Off';
      case 1: return 'Repeat One';
      case 2: return 'Loop';
      default: return 'Off';
    }
  }

  /// Update playback state with current controls
  void _updatePlaybackState() {
    // Get current player state and create a playback event
    final currentState = _player.playerState;
    final position = _player.position;
    final bufferedPosition = _player.bufferedPosition;
    final duration = _player.duration ?? Duration.zero;

    // Create a synthetic PlaybackEvent with current state
    final event = PlaybackEvent(
      processingState: currentState.processingState,
      updatePosition: position,
      updateTime: DateTime.now(),
      bufferedPosition: bufferedPosition,
      duration: duration,
      currentIndex: null,
    );

    playbackState.add(_transformEvent(event));
  }

  void _initializePlayer() {
    _logger.i('🎵 Initializing RhythmFlowAudioHandler...');

    // Transform just_audio playback events to audio_service playback states
    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });

    // Listen to player state changes
    _player.playerStateStream.listen((playerState) {
      _logger.d(
        'Player state: ${playerState.processingState} | Playing: ${playerState.playing}',
      );
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      _logger.d('Position: ${position.inSeconds}s');
    });

    _logger.i('✅ RhythmFlowAudioHandler initialized');
  }

  /// Transform just_audio PlaybackEvent to audio_service PlaybackState
  PlaybackState _transformEvent(PlaybackEvent event) {
    // Create custom controls for shuffle and repeat
    // Shuffle has 3 states: None → AI → Normal → None (matching music player screen)
    final shuffleControl = MediaControl(
      androidIcon: _getShuffleIcon(),
      label: _getShuffleLabel(),
      action: MediaAction.custom,
      customAction: shuffleAction,
    );

    final repeatControl = MediaControl(
      androidIcon: _getRepeatIcon(),
      label: _getRepeatDescription(_repeatModeIndex),
      action: MediaAction.custom,
      customAction: repeatAction,
    );

    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        shuffleControl,
        repeatControl,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.custom,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // Getters
  AudioPlayer get player => _player;
  
  // Callbacks for skip actions (set by AudioService)
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;
  
  // Callbacks for shuffle and repeat (set by AudioService)
  // Changed: onToggleShuffle now triggers the 3-state cycle (None → AI → Normal → None)
  VoidCallback? onToggleShuffle;
  VoidCallback? onToggleRepeat;
  
  // Callbacks for play/pause (set by AudioService)
  VoidCallback? onPlay;
  VoidCallback? onPause;
  
  /// Set callbacks for skip actions
  void setSkipCallbacks({
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) {
    onSkipToNext = onNext;
    onSkipToPrevious = onPrevious;
    _logger.i('✅ Skip callbacks set in AudioHandler');
  }

  /// Set callbacks for shuffle and repeat actions
  void setShuffleRepeatCallbacks({
    VoidCallback? onShuffle,
    VoidCallback? onRepeat,
  }) {
    onToggleShuffle = onShuffle;
    onToggleRepeat = onRepeat;
    _logger.i('✅ Shuffle/Repeat callbacks set in AudioHandler');
  }

  /// Set callbacks for play/pause actions
  void setPlayPauseCallbacks({
    VoidCallback? onPlay,
    VoidCallback? onPause,
  }) {
    this.onPlay = onPlay;
    this.onPause = onPause;
    _logger.i('✅ Play/Pause callbacks set in AudioHandler');
  }

  /// Get shuffle icon based on state (AI → Normal → None cycle)
  String _getShuffleIcon() {
    if (_isAiShuffle) {
      return 'drawable/ic_shuffle_ai'; // AI shuffle - sparkles icon
    } else if (_isShuffle) {
      return 'drawable/ic_shuffle'; // Normal shuffle
    } else {
      return 'drawable/ic_shuffle_off'; // None - shuffle with cross
    }
  }

  /// Get shuffle label based on state
  String _getShuffleLabel() {
    if (_isAiShuffle) {
      return 'AI Shuffle';
    } else if (_isShuffle) {
      return 'Shuffle On';
    } else {
      return 'Shuffle Off';
    }
  }

  /// Get repeat icon based on mode
  String _getRepeatIcon() {
    switch (_repeatModeIndex) {
      case 0: return 'drawable/ic_repeat_off';
      case 1: return 'drawable/ic_repeat_one';
      case 2: return 'drawable/ic_repeat_all';
      default: return 'drawable/ic_repeat_off';
    }
  }

  @override
  Future<void> play() async {
    _logger.i('▶️ Play requested from notification');
    await _player.play();
    // Trigger callback to sync with MusicBloc
    onPlay?.call();
  }

  @override
  Future<void> pause() async {
    _logger.i('⏸️ Pause requested from notification');
    await _player.pause();
    // Trigger callback to sync with MusicBloc
    onPause?.call();
  }

  @override
  Future<void> stop() async {
    _logger.i('⏹️ Stop requested');
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    _logger.i('🔍 Seek to ${position.inSeconds}s');
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    _logger.i('⏭️ Skip to next requested from notification');
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    _logger.i('⏮️ Skip to previous requested from notification');
    onSkipToPrevious?.call();
  }

  /// Handle custom actions (shuffle and repeat)
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    _logger.i('🎛️ Custom action requested: $name');
    
    // Compare by name since CustomMediaAction uses name for identification
    if (name == shuffleAction.name || name == shuffleActionId) {
      // Trigger 3-state cycle: None → AI → Normal → None (matching music player screen)
      // The callback will handle the state logic in MusicBloc
      _logger.i('🔀 Shuffle button pressed - triggering 3-state cycle');
      onToggleShuffle?.call();
    } else if (name == repeatAction.name || name == repeatActionId) {
      _logger.i('🔄 Toggling repeat mode');
      onToggleRepeat?.call();
    } else {
      _logger.w('⚠️ Unknown custom action: $name');
    }
  }

  /// Update the current media item
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    _logger.i('📱 Updating media item: ${item.title}');
    // Set MediaItem first - this is required for notification to appear
    mediaItem.add(item);
    
    // Force update playback state immediately after setting MediaItem
    // The notification requires BOTH MediaItem and PlaybackState to appear
    _updatePlaybackState();
    
    _logger.i('✅ MediaItem and PlaybackState updated - notification should appear');
  }

  /// Clear the current media item
  Future<void> clearMediaItem() async {
    _logger.i('🧹 Clearing media item');
    mediaItem.add(null);
  }

  /// Dispose resources
  @override
  Future<void> onTaskRemoved() async {
    _logger.i('🗑️ Task removed - disposing handler');
    await _player.dispose();
    await super.onTaskRemoved();
  }
}

/// ============================================================================
/// AI SHUFFLE INTEGRATION GUIDE
/// ============================================================================
/// 
/// This file contains the complete integration code for AI Shuffle with your app settings.
/// Copy the relevant parts into your MusicBloc and AppSettingsBloc.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logger/logger.dart';
import '../../models/song/song_model.dart';
import 'ai_shuffle_service.dart';

/// ============================================================================
/// STEP 1: Add to AppSettingsBloc
/// ============================================================================
/// 
/// Add this event handler to your AppSettingsBloc:

/*
on<_UpdateAiShuffle>((event, emit) async {
  try {
    _logger.i('🎵 Updating AI Shuffle setting: ${event.isEnabled}');
    
    final newState = state.copyWith(isAiShuffleEnabled: event.isEnabled);
    emit(newState);
    
    _logger.i('✅ AI Shuffle setting updated: ${event.isEnabled}');
  } catch (e, stackTrace) {
    _logger.e('❌ Failed to update AI Shuffle setting: $e');
    _logger.e('Stack trace: $stackTrace');
  }
});
*/

/// ============================================================================
/// STEP 2: Add to MusicBloc - Import Required
/// ============================================================================
/// 
/// Add this import to your music_bloc.dart:
/// import '../../../utils/services/ai_shuffle/ai_shuffle_service.dart';

/// ============================================================================
/// STEP 3: Add AI Shuffle Event Handler to MusicBloc
/// ============================================================================
/// 
/// Add this event handler to your MusicBloc:

/*
on<_AiShuffle>((event, emit) async {
  try {
    _logger.i('🎵 AI Shuffle triggered for song: ${event.currentSongId}');
    
    // Get current state
    final currentState = state;
    
    // Reorder playlist using AI shuffle
    final reorderedPlaylist = AiShuffleService.reorderPlaylistBySimilarity(
      currentSongId: event.currentSongId,
      playlistSongIds: event.currentPlayList,
      allSongs: currentState.allSongs,
      maxSimilarSongs: 20,
    );
    
    _logger.d('🎯 Original playlist: ${event.currentPlayList.take(5).join(', ')}...');
    _logger.d('🎯 Reordered playlist: ${reorderedPlaylist.take(5).join(', ')}...');
    
    // Update player state with reordered playlist
    final updatedPlayerState = currentState.myPlayerState.aiShufflePlaylist(reorderedPlaylist);
    
    // Emit new state
    emit(currentState.copyWith(myPlayerState: updatedPlayerState));
    
    _logger.i('✅ AI Shuffle completed: ${reorderedPlaylist.length} songs reordered');
    
  } catch (e, stackTrace) {
    _logger.e('❌ AI Shuffle failed: $e');
    _logger.e('Stack trace: $stackTrace');
    // Don't fail silently - maintain current playlist
  }
});
*/

/// ============================================================================
/// STEP 4: Modify playOrPauseSong Event Handler
/// ============================================================================
/// 
/// In your existing _PlayOrPauseSong event handler, add this code after the song starts playing:

/*
on<_PlayOrPauseSong>((event, emit) async {
  try {
    // ... your existing playOrPauseSong logic ...
    
    // After successfully starting to play a song:
    if (songToPlay != null && event.songId != null) {
      
      // ... existing logic to start playing ...
      
      // CHECK AI SHUFFLE SETTING AND TRIGGER IF ENABLED
      final appSettings = _appSettingsBloc.state;
      if (appSettings.isAiShuffleEnabled) {
        _logger.d('🎵 AI Shuffle enabled - triggering intelligent reordering');
        
        add(MusicEvent.aiShuffle(
          currentSongId: event.songId!,
          currentPlayList: state.myPlayerState.currentPlayList,
          playlistSource: event.playlistSource,
        ));
      } else {
        _logger.d('🎵 AI Shuffle disabled - maintaining original playlist order');
      }
    }
    
  } catch (e, stackTrace) {
    _logger.e('❌ Play or pause song failed: $e');
    _logger.e('Stack trace: $stackTrace');
  }
});
*/

/// ============================================================================
/// STEP 5: Add to App Settings UI
/// ============================================================================
/// 
/// In your app settings screen, add the AI Shuffle settings tile:

/*
// Import the widget
import '../widgets/ai_shuffle_settings_tile.dart';

// Add to your settings list
ListView(
  children: [
    // ... other settings tiles ...
    
    // AI Shuffle Settings
    const AiShuffleSettingsTile(),
    
    // ... other settings tiles ...
  ],
)
*/

/// ============================================================================
/// COMPLETE EXAMPLE - Music Bloc Integration
/// ============================================================================

class AiShuffleMusicBlocExample {
  static final AppLogger _logger = AppLogger('AiShuffleMusicBlocExample');
  
  /// Example: Complete playOrPauseSong handler with AI Shuffle integration
  static void handlePlayOrPauseSongWithAiShuffle({
    required String? songId,
    required List<String> currentPlayList,
    required List<Song> allSongs,
    required bool isAiShuffleEnabled,
    required Function(String, List<String>) onAiShuffleTriggered,
    required Function() onSongStarted,
  }) {
    try {
      _logger.i('🎵 Handling playOrPauseSong with AI Shuffle check');
      
      // Start playing the song
      onSongStarted();
      
      // Check if AI Shuffle is enabled
      if (isAiShuffleEnabled && songId != null) {
        _logger.d('🎵 AI Shuffle enabled - analyzing song features');
        
        // Trigger AI Shuffle
        onAiShuffleTriggered(songId, currentPlayList);
        
        _logger.i('✅ AI Shuffle triggered successfully');
      } else {
        _logger.d('🎵 AI Shuffle disabled - maintaining original order');
      }
      
    } catch (e, stackTrace) {
      _logger.e('❌ Error in playOrPauseSong with AI Shuffle: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }
  
  /// Example: AI Shuffle trigger with settings validation
  static Future<void> triggerAiShuffleWithValidation({
    required String currentSongId,
    required List<String> playlist,
    required List<Song> allSongs,
    required bool isAiShuffleEnabled,
    required bool isShuffleEnabled,
    required Function(List<String>) onPlaylistReordered,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      // Validate settings
      if (!isAiShuffleEnabled) {
        onStatusUpdate?.call('AI Shuffle is disabled in settings');
        return;
      }
      
      if (!isShuffleEnabled) {
        onStatusUpdate?.call('Regular shuffle is disabled - AI Shuffle requires shuffle to be enabled');
        return;
      }
      
      onStatusUpdate?.call('🎵 Analyzing song features...');
      
      // Perform AI Shuffle
      final reorderedPlaylist = AiShuffleService.reorderPlaylistBySimilarity(
        currentSongId: currentSongId,
        playlistSongIds: playlist,
        allSongs: allSongs,
        maxSimilarSongs: 20,
      );
      
      onStatusUpdate?.call('✅ Found ${reorderedPlaylist.length} similar songs!');
      onPlaylistReordered(reorderedPlaylist);
      
    } catch (e) {
      onStatusUpdate?.call('❌ AI Shuffle failed: $e');
      _logger.e('AI Shuffle validation error: $e');
    }
  }
}

/// ============================================================================
/// SETTINGS VALIDATION LOGIC
/// ============================================================================

class AiShuffleSettingsValidator {
  /// Validate AI Shuffle settings
  static bool canUseAiShuffle({
    required bool isAiShuffleEnabled,
    required bool isShuffleEnabled,
    required String? currentSongId,
    required List<String> playlist,
    required List<Song> allSongs,
  }) {
    // Check if AI Shuffle is enabled
    if (!isAiShuffleEnabled) {
      return false;
    }
    
    // Check if regular shuffle is enabled (AI Shuffle requires shuffle to be on)
    if (!isShuffleEnabled) {
      return false;
    }
    
    // Check if we have a current song
    if (currentSongId == null) {
      return false;
    }
    
    // Check if playlist has songs
    if (playlist.isEmpty) {
      return false;
    }
    
    // Check if current song has features
    final currentSong = allSongs.firstWhere(
      (song) => song.id == currentSongId,
      orElse: () => Song(
        id: '',
        title: '',
        artists: [],
        albums: [],
        path: '',
        duration: Duration.zero,
      ),
    );
    
    if (currentSong.features == null) {
      return false;
    }
    
    return true;
  }
  
  /// Get validation message
  static String getValidationMessage({
    required bool isAiShuffleEnabled,
    required bool isShuffleEnabled,
    required String? currentSongId,
    required List<String> playlist,
    required List<Song> allSongs,
  }) {
    if (!isAiShuffleEnabled) {
      return 'AI Shuffle is disabled in settings';
    }
    
    if (!isShuffleEnabled) {
      return 'Enable shuffle in settings to use AI Shuffle';
    }
    
    if (currentSongId == null) {
      return 'No song is currently playing';
    }
    
    if (playlist.isEmpty) {
      return 'Playlist is empty';
    }
    
    final currentSong = allSongs.firstWhere(
      (song) => song.id == currentSongId,
      orElse: () => Song(
        id: '',
        title: '',
        artists: [],
        albums: [],
        path: '',
        duration: Duration.zero,
      ),
    );
    
    if (currentSong.features == null) {
      return 'Current song needs feature analysis to use AI Shuffle';
    }
    
    return 'AI Shuffle is ready to use';
  }
}

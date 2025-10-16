import 'dart:async';
import '../app_settings/bloc/app_settings_bloc.dart';
import '../../utils/services/audio_service.dart';
import '../../utils/logger/logger.dart';
import '../bottom_tab/bloc/music_bloc.dart';

/// Helper class to centralize all app settings synchronization logic
/// Handles theme, playback speed, and other settings sync between AppSettingsBloc and services
class SyncAppSettingsHelper {
  static final AppLogger _logger = AppLogger('SyncAppSettingsHelper');
  
  /// Initialize all settings synchronization
  /// Call this when the app starts to sync all settings
  static Future<void> initializeSettingsSync({
    required AppSettingsBloc appSettingsBloc,
    required AudioService audioService,
  }) async {
    try {
      _logger.i('🔄 Initializing app settings synchronization...');
      
      // Initialize playback speed
      await _initializePlaybackSpeed(appSettingsBloc, audioService);
      
      _logger.i('✅ App settings synchronization initialized successfully');
    } catch (e) {
      _logger.e('❌ Error initializing app settings sync: $e');
    }
  }
  
  /// Sync playback speed from AppSettingsBloc to AudioService
  static Future<void> syncPlaybackSpeed({
    required AppSettingsBloc appSettingsBloc,
    required AudioService audioService,
  }) async {
    try {
      final appSettingsState = appSettingsBloc.state;
      final playbackSpeed = appSettingsState.playbackSpeed;
      
      _logger.i('⚡ Syncing playback speed: ${playbackSpeed}x');
      await audioService.setSpeed(playbackSpeed);
      _logger.i('✅ Playback speed synced: ${playbackSpeed}x');
    } catch (e) {
      _logger.e('❌ Error syncing playback speed: $e');
    }
  }
  
  /// Initialize playback speed from AppSettingsBloc to AudioService
  static Future<void> _initializePlaybackSpeed(
    AppSettingsBloc appSettingsBloc,
    AudioService audioService,
  ) async {
    try {
      final appSettingsState = appSettingsBloc.state;
      final playbackSpeed = appSettingsState.playbackSpeed;
      
      _logger.i('⚡ Initializing playback speed: ${playbackSpeed}x');
      await audioService.setSpeed(playbackSpeed);
      _logger.i('✅ Playback speed initialized: ${playbackSpeed}x');
    } catch (e) {
      _logger.e('❌ Error initializing playback speed: $e');
    }
  }
  
  /// Apply playback speed to AudioService (for use during song playback)
  static Future<void> applyPlaybackSpeed({
    required AppSettingsBloc appSettingsBloc,
    required AudioService audioService,
  }) async {
    try {
      final appSettingsState = appSettingsBloc.state;
      final playbackSpeed = appSettingsState.playbackSpeed;
      
      _logger.i('⚡ Applying playback speed: ${playbackSpeed}x');
      await audioService.setSpeed(playbackSpeed);
      _logger.i('✅ Playback speed applied: ${playbackSpeed}x');
    } catch (e) {
      _logger.e('❌ Error applying playback speed: $e');
    }
  }
  
  /// Sync theme settings from AppSettingsBloc
  /// This method can be extended to sync theme with other services if needed
  static void syncThemeSettings({
    required AppSettingsBloc appSettingsBloc,
  }) {
    try {
      final appSettingsState = appSettingsBloc.state;
      final isDarkMode = appSettingsState.isDarkMode;
      final followSystemTheme = appSettingsState.followSystemTheme;
      
      _logger.i('🎨 Syncing theme settings - isDarkMode: $isDarkMode, followSystemTheme: $followSystemTheme');
      
      // Here you can add theme synchronization logic with other services
      // For example, if you have a ThemeService or need to update UI components
      
      _logger.i('✅ Theme settings synced successfully');
    } catch (e) {
      _logger.e('❌ Error syncing theme settings: $e');
    }
  }
  
  /// Sync all settings at once
  static Future<void> syncAllSettings({
    required AppSettingsBloc appSettingsBloc,
    required AudioService audioService,
  }) async {
    try {
      _logger.i('🔄 Syncing all app settings...');
      
      // Sync playback speed
      await syncPlaybackSpeed(
        appSettingsBloc: appSettingsBloc,
        audioService: audioService,
      );
      
      // Sync theme settings
      syncThemeSettings(appSettingsBloc: appSettingsBloc);
      
      _logger.i('✅ All app settings synced successfully');
    } catch (e) {
      _logger.e('❌ Error syncing all settings: $e');
    }
  }

  // ==================== SLEEP TIMER CONTROL ====================
  
  /// Start sleep timer when song starts playing
  static void startSleepTimer({
    required AppSettingsBloc appSettingsBloc,
    required MusicBloc musicBloc,
  }) {
    try {
      final appSettingsState = appSettingsBloc.state;
      
      // Only start timer if sleep timer is enabled
      if (!appSettingsState.isSleepTimerEnabled) {
        _logger.d('💤 Sleep timer disabled - not starting timer');
        return;
      }
      
      // Only start timer if music is actually playing
      if (!musicBloc.state.myPlayerState.isPlaying || musicBloc.state.myPlayerState.currentSongId == null) {
        _logger.d('💤 No music playing - not starting timer');
        return;
      }
      
      final timerMinutes = appSettingsState.sleepTimerMinutes;
      final timerDuration = Duration(minutes: timerMinutes);
      
      _logger.i('💤 Starting sleep timer: $timerMinutes minutes');
      
      // Use the MusicBloc's internal timer management
      musicBloc.startSleepTimerInternal(timerDuration);
      
      _logger.i('✅ Sleep timer started: $timerMinutes minutes');
    } catch (e) {
      _logger.e('❌ Error starting sleep timer: $e');
    }
  }
  
  /// Stop sleep timer
  static void stopSleepTimer({
    required MusicBloc musicBloc,
  }) {
    try {
      musicBloc.stopSleepTimerInternal();
    } catch (e) {
      _logger.e('❌ Error stopping sleep timer: $e');
    }
  }
  
  /// Handle sleep timer settings changes with proper cleanup
  static void handleSleepTimerSettingsChange({
    required AppSettingsBloc appSettingsBloc,
    required MusicBloc musicBloc,
  }) {
    try {
      final appSettingsState = appSettingsBloc.state;
      
      _logger.i('💤 Sleep timer settings changed - cleaning up existing timer');
      
      // Always stop existing timer first
      stopSleepTimer(musicBloc: musicBloc);
      
      // Check if sleep timer is enabled
      if (appSettingsState.isSleepTimerEnabled) {
        // Only start new timer if music is currently playing
        if (musicBloc.state.myPlayerState.isPlaying && musicBloc.state.myPlayerState.currentSongId != null) {
          _logger.i('💤 Sleep timer enabled and music playing - starting new timer');
          startSleepTimer(appSettingsBloc: appSettingsBloc, musicBloc: musicBloc);
        } else {
          _logger.i('💤 Sleep timer enabled but no music playing - timer will start when music plays');
        }
      } else {
        _logger.i('💤 Sleep timer disabled - timer cleared');
      }
    } catch (e) {
      _logger.e('❌ Error handling sleep timer settings change: $e');
    }
  }
  
  /// Check if sleep timer is currently running
  static bool isSleepTimerRunning({
    required MusicBloc musicBloc,
  }) => musicBloc.isSleepTimerRunning;
  
  /// Get remaining sleep timer duration (for debugging/logging)
  static Duration? getSleepTimerRemainingDuration({
    required MusicBloc musicBloc,
  }) {
    return musicBloc.getSleepTimerRemainingDuration();
  }
  
  
}

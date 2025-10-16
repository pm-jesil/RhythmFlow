import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logger/logger.dart';
import 'audio_service.dart';
import 'permission_service.dart';
import '../../screens/bottom_tab/bloc/music_bloc.dart';
import '../../core/di/injection.dart';
import '../../screens/widgets/playlist_source_helper.dart';

class AppInitializationService {
  static final AppLogger _logger = AppLogger('AppInitializationService');
  static bool _isInitialized = false;

  /// Initialize the app with all required permissions and data loading
  static Future<void> initializeApp(BuildContext context) async {
    if (_isInitialized) {
      _logger.i('App already initialized, skipping...');
      return;
    }

    _logger.i('🚀 Starting app initialization...');
    
    try {
      // Step 1: Request permissions (non-blocking)
      _requestPermissions().catchError((error) {
        _logger.e('❌ Permission request failed', error: error);
      });
      
      // Step 2: Load all music data (non-blocking)
      if (context.mounted) {
        _loadMusicData(context).catchError((error) {
          _logger.e('❌ Music data loading failed', error: error);
        });
      }
      
      _isInitialized = true;
      _logger.i('✅ App initialization completed successfully');
      
    } catch (e) {
      _logger.e('❌ App initialization failed', error: e);
      // Continue anyway to avoid blocking the UI
    }
  }

  /// Request all required permissions
  static Future<void> _requestPermissions() async {
    _logger.i('📋 Requesting permissions...');
    
    try {
      final hasPermissions = await PermissionService.hasAllRequiredPermissions();
      
      if (hasPermissions) {
        _logger.i('✅ Permissions granted');
      } else {
        _logger.w('⚠️ Some permissions not granted, continuing anyway...');
      }
    } catch (e) {
      _logger.e('❌ Permission request failed', error: e);
      // Continue anyway to avoid blocking the UI
    }
  }

  /// Load all music data (non-blocking)
  static Future<void> _loadMusicData(BuildContext context) async {
    _logger.i('🎵 Loading music data...');
    
    try {
      final musicBloc = context.read<MusicBloc>();
      final currentState = musicBloc.state;
      
      // Check if we have cached data
      final hasCachedSongs = currentState.allSongs.isNotEmpty;
      final hasCachedAlbums = currentState.albumList.isNotEmpty;
      final hasCachedArtists = currentState.artistList.isNotEmpty;
      
      _logger.i('📊 Cache status - Songs: ${hasCachedSongs ? currentState.allSongs.length : 0}, Albums: ${hasCachedAlbums ? currentState.albumList.length : 0}, Artists: ${hasCachedArtists ? currentState.artistList.length : 0}');
      
      // Load data in parallel for better performance
      final futures = <Future>[];
      
      // Always load songs (to check for new ones)
      futures.add(_loadSongs(musicBloc));
      
      // Load metadata (albums and artists) only if they're empty
      if (!hasCachedAlbums || !hasCachedArtists) {
        futures.add(_loadMetadata(musicBloc));
      }
      
      // Always load playlists (they're user-created)
      futures.add(_loadMyPlaylists(musicBloc));
      
      // Wait for all operations to complete
      await Future.wait(futures);
      
      // Check if we need to restore last played song and position
      await _restoreLastPlayedSong(musicBloc);
      
      _logger.i('✅ Music data loaded successfully');
    } catch (e) {
      _logger.e('❌ Music data loading failed', error: e);
      // Continue anyway to avoid blocking the UI
    }
  }

  /// Load songs
  static Future<void> _loadSongs(MusicBloc musicBloc) async {
    try {
      musicBloc.add(const MusicEvent.fetchAndUpdateSongs());
      _logger.d('📀 Songs loading initiated');
    } catch (e) {
      _logger.e('❌ Failed to load songs', error: e);
    }
  }

  /// Load metadata (albums and artists)
  static Future<void> _loadMetadata(MusicBloc musicBloc) async {
    try {
      musicBloc.add(const MusicEvent.fetchAndUpdateMetadata(
        includeAlbums: true,
        includeArtists: true,
        isProgressive: true,
      ));
      _logger.d('💿👤 Metadata loading initiated');
    } catch (e) {
      _logger.e('❌ Failed to load metadata', error: e);
    }
  }

  /// Load my playlists
  static Future<void> _loadMyPlaylists(MusicBloc musicBloc) async {
    try {
      musicBloc.add(const MusicEvent.loadMyPlaylists());
      _logger.d('📋 My playlists loading initiated');
    } catch (e) {
      _logger.e('❌ Failed to load my playlists', error: e);
    }
  }



  /// Check if app is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Restore last played song and position if available
  static Future<void> _restoreLastPlayedSong(MusicBloc musicBloc) async {
    try {
      final currentState = musicBloc.state;
      
      // Check if we have a saved song and position
      if (currentState.myPlayerState.currentSongId != null && 
          currentState.myPlayerState.lastPosition != null) {
        
        _logger.i(
          '🔄 Restoring last played song: ${currentState.myPlayerState.currentSongId} at position: ${currentState.myPlayerState.lastPosition!.inSeconds}s (paused - user must tap play)',
        );
        
        // Find the current song and restore it with the saved position
        final currentSong = currentState.allSongs.firstWhere(
          (song) => song.id == currentState.myPlayerState.currentSongId,
          orElse: () => throw Exception('Current song not found'),
        );
        
        // Get audio service and load the song (but don't play it)
        final audioService = getIt<AudioService>();
        
        // Load the song without playing it - user must manually tap play
        await audioService.loadSong(
          currentSong,
          playlistId: currentState.myPlayerState.playlistId,
          playlistSource: PlaylistSourceHelper.getPlaylistSourceFromId(currentState.myPlayerState.playlistId),
        );
        
        // Wait for song to be fully loaded, then seek to the saved position
        await Future.delayed(const Duration(milliseconds: 1000));
        await audioService.seekTo(currentState.myPlayerState.lastPosition!);
        
        _logger.i('✅ Last played song restored and positioned successfully (paused - user must tap play)');
      } else {
        _logger.i('ℹ️ No last played song to restore');
      }
      
      // Mark initialization as complete to allow position updates
      musicBloc.markInitializationComplete();
    } catch (e) {
      _logger.e('❌ Error restoring last played song', error: e);
    }
  }
  
}

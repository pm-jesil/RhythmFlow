import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:pmj_music_player/core/constants/app_enums.dart';
import 'package:pmj_music_player/utils/models/my_playlist/my_playlist_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../utils/models/song/song_model.dart';
import '../../../../utils/models/album/album_model.dart';
import '../../../../utils/models/artist/artist_model.dart';
import '../../../../utils/models/my_player_state_model.dart';
import '../../../../utils/models/playlist_source/playlist_source_model.dart';
import '../../../../utils/logger/logger.dart';
import '../../../../utils/services/fetch_songs.dart';
import '../../../../utils/services/music_service.dart';
import '../../../../utils/services/audio_service.dart';
import '../../../../utils/services/enhanced_notification_service.dart';
import '../../../../utils/services/remote_control_service.dart';
import '../../../../utils/services/song_uniqueness_validator.dart';
import '../../../../utils/services/play_count_tracking_service.dart';
import '../../../../utils/services/my_playlist_service.dart';
import '../../../widgets/sync_app_settings_helper.dart';
import '../../../app_settings/bloc/app_settings_bloc.dart';

part 'music_event.dart';
part 'music_state.dart';
part 'music_bloc.freezed.dart';

@singleton
class MusicBloc extends HydratedBloc<MusicEvent, MusicState> {
  static final AppLogger _logger = AppLogger('MusicBloc');

  // Services
  final AudioService _audioService;
  final RemoteControlService _remoteControlService;
  final AppSettingsBloc _appSettingsBloc;

  // Stream subscriptions for proper disposal
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<AppSettingsState>? _appSettingsSubscription;
  
  // Sleep timer
  Timer? _sleepTimer;

  // Flag to prevent race conditions during state updates
  bool _isUpdatingState = false;
  
  // Flag to prevent position updates during app initialization
  bool _isInitializing = true;

  // Sorting options constants
  static const List<String> sortingOptions = [
    'Newest First',
    'Oldest First',
    'Alphabetical',
    'Duration (Shortest)',
    'Duration (Longest)',
  ];

  MusicBloc(this._audioService, this._remoteControlService, this._appSettingsBloc)
    : super(MusicState.initial()) {
    // ==================== SETUP PLAY COUNT TRACKING ====================
    _setupPlayCountTracking();
    
    // ==================== REGISTER EVENT HANDLERS ====================
    // Loading events
    on<_LoadAllSongs>(_onLoadAllSongs);
    on<_LoadAllSongsProgressive>(_onLoadAllSongsProgressive);

    on<_LoadAlbums>(_onLoadAlbums);
    on<_LoadAlbumsProgressive>(_onLoadAlbumsProgressive);

    on<_LoadArtists>(_onLoadArtists);
    on<_LoadArtistsProgressive>(_onLoadArtistsProgressive);

    on<_LoadMyPlaylists>(_onLoadMyPlaylists);
    on<_AddOrUpdateMyPlayList>(_onAddOrUpdateMyPlayList);

    // Playback events
    on<_PlayOrPauseSong>(_onPlayOrPauseSong);
    on<_PlayNext>(_onPlayNext);
    on<_PlayPrevious>(_onPlayPrevious);

    // Playback settings events
    on<_ToggleShuffle>(_onToggleShuffle);
    on<_ToggleRepeat>(_onToggleRepeat);

    // Sorting and seeking events
    on<_ChangeSortingOrder>(_onChangeSortingOrder);
    on<_SeekToPosition>(_onSeekToPosition);
    on<_UpdateLastPosition>(_onUpdateLastPosition);

    // Filter events
    on<_UpdateFilterKeyword>(_onUpdateFilterKeyword);
    on<_SetNavigationFilter>(_onSetNavigationFilter);

    // State update event
    on<_UpdateMusicBlocState>(_onUpdateMusicBlocState);

    // Listen to audio service song changes
    _audioService.onSongChanged = _onAudioServiceSongChanged;
    
    // Set up position tracking callback
    _audioService.setPositionChangedCallback(_onPositionChanged);

    // Set up remote control service
    _remoteControlService.setActionCallback(_handleRemoteControlAction);
    
    // Initialize all app settings synchronization
    SyncAppSettingsHelper.initializeSettingsSync(
      appSettingsBloc: _appSettingsBloc,
      audioService: _audioService,
    );
    
    // Listen to AppSettingsBloc changes for settings sync
    _appSettingsSubscription = _appSettingsBloc.stream.listen((appSettingsState) {
      SyncAppSettingsHelper.syncAllSettings(
        appSettingsBloc: _appSettingsBloc,
        audioService: _audioService,
      );
      
      // Handle sleep timer settings changes with proper cleanup
      SyncAppSettingsHelper.handleSleepTimerSettingsChange(
        appSettingsBloc: _appSettingsBloc,
        musicBloc: this,
      );
    });

    // ==================== SINGLE STATE SYNC LISTENER ====================
    // Listen to player state for comprehensive sync (includes playing state)
    _playerStateSubscription = _audioService.playerStateStream.listen((
      playerState,
    ) {
      // Only sync if we're not currently updating state to prevent race conditions
      if (!_isUpdatingState) {
        // Sync playing state into myPlayerState
        if (state.myPlayerState.isPlaying != playerState.playing) {
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: state.myPlayerState.copyWith(
                  isPlaying: playerState.playing,
                ),
              ),
            ),
          );
        }
      }

      // Handle completion state - remove completed song from queue
      if (playerState.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });
  }

  @override
  String get storagePrefix => 'MusicBloc';

  @override
  Map<String, dynamic>? toJson(MusicState state) {
    try {
      return {
        'sortingIndex': state.sortingIndex,
        'allSongs': state.allSongs.map((s) => s.toJson()).toList(),
        'albumList': state.albumList.map((a) => a.toJson()).toList(),
        'artistList': state.artistList.map((a) => a.toJson()).toList(),
        'myPlaylist': state.myPlaylist.map((p) => p.toJson()).toList(),
        'myPlayerState': {
          'completedSongs': state.myPlayerState.completedSongs,
          'currentPlayList': state.myPlayerState.currentPlayList,
          'currentSongId': state.myPlayerState.currentSongId,
          'repeatModeIndex': state.myPlayerState.repeatModeIndex,
          'playlistId': state.myPlayerState.playlistId,
          'previousSongId': state.myPlayerState.previousSongId,
          'isShuffle': state.myPlayerState.isShuffle,
          'isPlaying': state.myPlayerState.isPlaying,
          'lastPosition': state.myPlayerState.lastPosition?.inMilliseconds,
        },
      };
    } catch (_) {
      return null; // skip persisting on serialization errors
    }
  }

  @override
  MusicState? fromJson(Map<String, dynamic> json) {
    try {
      final songs = (json['allSongs'] as List<dynamic>? ?? [])
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
      final albums = (json['albumList'] as List<dynamic>? ?? [])
          .map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList();
      final artists = (json['artistList'] as List<dynamic>? ?? [])
          .map((e) => Artist.fromJson(e as Map<String, dynamic>))
          .toList();
      final myPlaylists = (json['myPlaylist'] as List<dynamic>? ?? [])
          .map((e) => MyPlaylist.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Ensure favorites playlist exists when loading from storage
      final playlistsWithFavorites = MyPlaylistService.ensureFavoritesPlaylist(myPlaylists);

      final mp = (json['myPlayerState'] as Map<String, dynamic>? ?? {});
      final myPlayerState = MyPlayerStateModel(
        playlistId: mp['playlistId'] as String?,
        currentPlayList: List<String>.from(mp['currentPlayList'] ?? const []),
        currentSongId: mp['currentSongId'] as String?,
        previousSongId: mp['previousSongId'] as String?,
        completedSongs: List<String>.from(mp['completedSongs'] ?? const []),
        repeatModeIndex: (mp['repeatModeIndex'] as int?) ?? 0,
        filterKeyword: '',
        isShuffle: (mp['isShuffle'] as bool?) ?? false,
        isPlaying: false,
        lastPosition: mp['lastPosition'] != null 
            ? Duration(milliseconds: mp['lastPosition'] as int)
            : null,
      );

      return MusicState(
        myPlayerState: myPlayerState,
        allSongs: songs,
        albumList: albums,
        artistList: artists,
        myPlaylist: playlistsWithFavorites,
        sortingIndex: (json['sortingIndex'] as int?) ?? 0,

        isSongListLoading: false,
        isAlbumListLoading: false,
        isArtistListLoading: false,
        isSongListError: false,
        isAlbumListError: false,
        isArtistListError: false,
        isLoading: false,
        isError: false,
      );
    } catch (e) {
      _logger.e('Failed to restore state from storage: $e');
      // Clear corrupted storage to prevent future issues
      try {
        HydratedBloc.storage.clear();
        _logger.i('Cleared corrupted storage');
      } catch (clearError) {
        _logger.e('Failed to clear corrupted storage: $clearError');
      }
      return null; // Fall back to initial state
    }
  }

  // ==================== LOADING EVENT HANDLERS ====================
  
  /// Check if we should skip fetching based on last update time (5-hour rule)
  bool _shouldSkipFetch() {
    final lastUpdate = _appSettingsBloc.state.lastUpdateMusicLibrary;
    if (lastUpdate == null) {
      _logger.i('⏰ No previous fetch time found - proceeding with fetch');
      return false;
    }
    
    final now = DateTime.now();
    final timeDifference = now.difference(lastUpdate);
    const fiveHours = Duration(hours: 5);
    
    if (timeDifference < fiveHours) {
      _logger.i('⏰ Last fetch was ${timeDifference.inMinutes} minutes ago (< 5 hours) - skipping fetch');
      return true;
    } else {
      _logger.i('⏰ Last fetch was ${timeDifference.inHours} hours ago (>= 5 hours) - proceeding with fetch');
      return false;
    }
  }
  
  /// Update the last music library fetch timestamp
  void _updateLastFetchTime() {
    _appSettingsBloc.add(
      AppSettingsEvent.updateLastMusicLibraryUpdate(
        timestamp: DateTime.now(),
      ),
    );
    _logger.i('⏰ Updated last music library fetch time');
  }

  Future<void> _onLoadAllSongs(
    _LoadAllSongs event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('Loading all songs...');

    // Check if we should skip fetching based on 5-hour rule
    if (_shouldSkipFetch() && state.allSongs.isNotEmpty) {
      _logger.i('⏰ Skipping song fetch - using cached data (${state.allSongs.length} songs)');
      return;
    }

    try {
      emit(
        state.copyWith(
          isSongListLoading: state.allSongs.isEmpty ? true : false,
          isSongListError: false,
        ),
      );

      final songs = await FetchSongsService.fetchAllSongs();
      _logger.i('Loaded ${songs.length} songs');

      // Validate song uniqueness
      if (!SongUniquenessValidator.validateUniqueIds(songs)) {
        _logger.e('❌ Song uniqueness validation failed - removing duplicates');
        final uniqueSongs = SongUniquenessValidator.removeDuplicates(songs);
        _logger.i(
          '✅ Removed duplicates: ${songs.length} → ${uniqueSongs.length} songs',
        );
        emit(state.copyWith(allSongs: uniqueSongs, isSongListLoading: false));
      } else {
        _logger.i('✅ All songs are unique');
        emit(state.copyWith(allSongs: songs, isSongListLoading: false));
      }

      // Update last fetch time after successful fetch
      _updateLastFetchTime();

      // Auto-load albums and artists if they're empty
      if (state.albumList.isEmpty) {
        add(const MusicEvent.loadAlbums());
      }
      if (state.artistList.isEmpty) {
        add(const MusicEvent.loadArtists());
      }
    } catch (e) {
      _logger.e('Error loading songs: $e');
      emit(state.copyWith(isSongListLoading: false, isSongListError: true));
    }
  }

  /// Progressive song loading - shows songs as they're fetched
  Future<void> _onLoadAllSongsProgressive(
    _LoadAllSongsProgressive event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🚀 Starting progressive song loading...');

    // Check if we should skip fetching based on 5-hour rule
    if (_shouldSkipFetch() && state.allSongs.isNotEmpty) {
      _logger.i('⏰ Skipping progressive song fetch - using cached data (${state.allSongs.length} songs)');
      return;
    }

    try {
      // Check if we already have songs in cache (HydratedBloc)
      final hasExistingSongs = state.allSongs.isNotEmpty;
      
      if (hasExistingSongs) {
        _logger.i('📀 Found ${state.allSongs.length} cached songs - fetching only new songs');
        
        // Set loading state but keep existing songs visible
        emit(
          state.copyWith(
            isSongListLoading: true,
            isSongListError: false,
            // Keep existing songs - don't clear them
          ),
        );

        // Fetch only new songs (not in existing list)
        final newSongs = await FetchSongsService.fetchNewSongs(state.allSongs);
        
        if (newSongs.isNotEmpty) {
          _logger.i('🆕 Found ${newSongs.length} new songs to add');
          
          // Add new songs to existing list
          final updatedSongs = [...state.allSongs, ...newSongs];
          
          // Validate uniqueness
          final uniqueSongs = SongUniquenessValidator.removeDuplicates(updatedSongs);
          
          emit(
            state.copyWith(
              allSongs: uniqueSongs,
              isSongListLoading: false,
            ),
          );
          
          _logger.i('✅ Added ${uniqueSongs.length - state.allSongs.length} new songs');
        } else {
          _logger.i('✅ No new songs found - keeping existing ${state.allSongs.length} songs');
          emit(state.copyWith(isSongListLoading: false));
        }
      } else {
        _logger.i('📀 No cached songs found - performing full progressive scan');
        
        // No existing songs - do progressive loading for first time
        emit(
          state.copyWith(
            isSongListLoading: true,
            isSongListError: false,
            allSongs: [], // Clear for fresh start
          ),
        );

        // Start progressive loading in background
        await FetchSongsService.fetchAllSongsProgressive(
          onProgress: (newSongs, isComplete, totalFound) {
            _logger.d(
              '📀 Progress update: ${newSongs.length} new songs, total: $totalFound, complete: $isComplete',
            );

            // Add new songs to existing list
            final updatedSongs = [...state.allSongs, ...newSongs];

            // Validate uniqueness for new batch
            final uniqueSongs = SongUniquenessValidator.removeDuplicates(
              updatedSongs,
            );

            emit(
              state.copyWith(
                allSongs: uniqueSongs,
                isSongListLoading: !isComplete,
                songLoadingProgress: totalFound,
              ),
            );

            // If this is the first batch (10+ songs), hide loading and show songs
            if (uniqueSongs.length >= 10 && state.isSongListLoading) {
              _logger.i(
                '🎵 First batch loaded (${uniqueSongs.length} songs) - showing UI',
              );
            }
          },
        );

        _logger.i('✅ Progressive song loading completed');
      }

      // Update last fetch time after successful progressive loading
      _updateLastFetchTime();

      // Auto-load albums and artists if they're empty
      if (state.albumList.isEmpty) {
        add(const MusicEvent.loadAlbumsProgressive());
      }
      if (state.artistList.isEmpty) {
        add(const MusicEvent.loadArtistsProgressive());
      }
    } catch (e) {
      _logger.e('❌ Error in progressive song loading: $e');
      emit(state.copyWith(isSongListLoading: false, isSongListError: true));
    }
  }

  /// Progressive album loading
  Future<void> _onLoadAlbumsProgressive(
    _LoadAlbumsProgressive event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🚀 Starting progressive album loading...');

    try {
      // Check if we already have albums in cache
      final hasExistingAlbums = state.albumList.isNotEmpty;
      
      if (hasExistingAlbums) {
        _logger.i('💿 Found ${state.albumList.length} cached albums - extracting from current songs');
        
        // Extract albums from current songs (no progressive loading needed)
        final albums = MusicService.fetchAlbumList(state.allSongs);
        final uniqueAlbums = albums.toSet().toList();
        
        emit(state.copyWith(albumList: uniqueAlbums));
        _logger.i('✅ Updated albums: ${uniqueAlbums.length} total');
      } else {
        _logger.i('💿 No cached albums found - performing progressive extraction');
        
        // Start progressive loading in background
        await _extractAlbumsProgressive(
          onProgress: (newAlbums, isComplete) {
            _logger.d(
              '💿 Album progress: ${newAlbums.length} new albums, complete: $isComplete',
            );

            // Add new albums to existing list
            final updatedAlbums = [...state.albumList, ...newAlbums];

            // Remove duplicates
            final uniqueAlbums = updatedAlbums.toSet().toList();

            emit(state.copyWith(albumList: uniqueAlbums));
          },
        );

        _logger.i('✅ Progressive album loading completed');
      }
    } catch (e) {
      _logger.e('❌ Error in progressive album loading: $e');
    }
  }

  /// Progressive artist loading
  Future<void> _onLoadArtistsProgressive(
    _LoadArtistsProgressive event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🚀 Starting progressive artist loading...');

    try {
      // Check if we already have artists in cache
      final hasExistingArtists = state.artistList.isNotEmpty;
      
      if (hasExistingArtists) {
        _logger.i('👤 Found ${state.artistList.length} cached artists - extracting from current songs');
        
        // Extract artists from current songs (no progressive loading needed)
        final artists = MusicService.fetchArtistList(state.allSongs);
        final uniqueArtists = artists.toSet().toList();
        
        emit(state.copyWith(artistList: uniqueArtists));
        _logger.i('✅ Updated artists: ${uniqueArtists.length} total');
      } else {
        _logger.i('👤 No cached artists found - performing progressive extraction');
        
        // Start progressive loading in background
        await _extractArtistsProgressive(
          onProgress: (newArtists, isComplete) {
            _logger.d(
              '👤 Artist progress: ${newArtists.length} new artists, complete: $isComplete',
            );

            // Add new artists to existing list
            final updatedArtists = [...state.artistList, ...newArtists];

            // Remove duplicates
            final uniqueArtists = updatedArtists.toSet().toList();

            emit(state.copyWith(artistList: uniqueArtists));
          },
        );

        _logger.i('✅ Progressive artist loading completed');
      }
    } catch (e) {
      _logger.e('❌ Error in progressive artist loading: $e');
    }
  }

  Future<void> _onLoadAlbums(
    _LoadAlbums event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('Loading albums...');

    try {
      emit(state.copyWith(isAlbumListLoading: true, isAlbumListError: false));

      final albums = MusicService.fetchAlbumList(
        state.allSongs,
        state.albumList,
      );
      _logger.i('Loaded ${albums.length} albums');

      emit(state.copyWith(albumList: albums, isAlbumListLoading: false));
    } catch (e) {
      _logger.e('Error loading albums: $e');
      emit(state.copyWith(isAlbumListLoading: false, isAlbumListError: true));
    }
  }

  Future<void> _onLoadArtists(
    _LoadArtists event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('Loading artists...');

    try {
      emit(state.copyWith(isArtistListLoading: true, isArtistListError: false));

      final artists = MusicService.fetchArtistList(
        state.allSongs,
        state.artistList,
      );
      _logger.i('Loaded ${artists.length} artists');

      emit(state.copyWith(artistList: artists, isArtistListLoading: false));
    } catch (e) {
      _logger.e('Error loading artists: $e');
      emit(state.copyWith(isArtistListLoading: false, isArtistListError: true));
    }
  }

  Future<void> _onLoadMyPlaylists(
    _LoadMyPlaylists event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('Loading my playlists...');

    try {
      // Check current state and ensure favorites playlist exists
      List<MyPlaylist> currentPlaylists = List.from(state.myPlaylist);
      
      // If the list is empty, add default favorites playlist
      if (currentPlaylists.isEmpty) {
        _logger.i('📝 Playlist list is empty, adding default favorites playlist');
        final defaultFavorites = MyPlaylistService.createDefaultFavoritesPlaylist();
        currentPlaylists.add(defaultFavorites);
      } else {
        // Ensure favorites playlist exists in the current state
        currentPlaylists = MyPlaylistService.ensureFavoritesPlaylist(currentPlaylists);
      }
      
      _logger.i('✅ Loaded ${currentPlaylists.length} playlists (including favorites)');
      emit(state.copyWith(myPlaylist: currentPlaylists));
    } catch (e) {
      _logger.e('Error loading playlists: $e');
      // Don't emit error state for playlists as they're optional
    }
  }

  Future<void> _onAddOrUpdateMyPlayList(
    _AddOrUpdateMyPlayList event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🎵 Playlist operation: ${event.operation}');

    try {
      List<MyPlaylist> updatedPlaylists = List.from(state.myPlaylist);
      MyPlaylist? updatedPlaylist;

      switch (event.operation) {
        case MyPlaylistOperation.create:
          _logger.i('📝 Creating new playlist: ${event.name}');
          updatedPlaylist = MyPlaylistService.createPlaylist(
            name: event.name!,
            description: event.description ?? '',
            songIds: event.songIds ?? [],
            coverImage: event.coverImage,
            isPublic: event.isPublic ?? false,
          );
          updatedPlaylists.insert(0, updatedPlaylist);
          break;

        case MyPlaylistOperation.update:
          _logger.i('📝 Updating playlist: ${event.playlistId}');
          final existingPlaylist = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () => throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.updatePlaylist(
            playlist: existingPlaylist,
            name: event.name,
            description: event.description,
            songIds: event.songIds,
            coverImage: event.coverImage,
            isPublic: event.isPublic,
          );
          final index = updatedPlaylists.indexWhere((p) => p.id == event.playlistId);
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.delete:
          _logger.i('🗑️ Deleting playlist: ${event.playlistId}');
          if (event.playlistId == 'my_playlist_favorites') {
            throw Exception('Cannot delete favorites playlist');
          }
          updatedPlaylists.removeWhere((p) => p.id == event.playlistId);
          break;

        case MyPlaylistOperation.addSong:
          _logger.i('➕ Adding song ${event.songId} to playlist ${event.playlistId}');
          final playlistToUpdate = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () => throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.addSongToPlaylist(
            playlist: playlistToUpdate,
            songId: event.songId!,
          );
          final index = updatedPlaylists.indexWhere((p) => p.id == event.playlistId);
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.removeSong:
          _logger.i('➖ Removing song ${event.songId} from playlist ${event.playlistId}');
          final playlistToRemoveFrom = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () => throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.removeSongFromPlaylist(
            playlist: playlistToRemoveFrom,
            songId: event.songId!,
          );
          final index = updatedPlaylists.indexWhere((p) => p.id == event.playlistId);
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.toggleFavorite:
          _logger.i('❤️ Toggling song ${event.songId} in favorites');
          final favoritesPlaylist = MyPlaylistService.getFavoritesPlaylist(updatedPlaylists);
          if (favoritesPlaylist == null) {
            throw Exception('Favorites playlist not found');
          }
          updatedPlaylist = MyPlaylistService.toggleSongInFavorites(
            favoritesPlaylist: favoritesPlaylist,
            songId: event.songId!,
          );
          final index = updatedPlaylists.indexWhere((p) => p.id == 'my_playlist_favorites');
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;

        case MyPlaylistOperation.updateDuration:
          _logger.i('⏱️ Updating playlist duration: ${event.playlistId}');
          final playlistToUpdateDuration = updatedPlaylists.firstWhere(
            (p) => p.id == event.playlistId,
            orElse: () => throw Exception('Playlist not found: ${event.playlistId}'),
          );
          updatedPlaylist = MyPlaylistService.updatePlaylistDuration(
            playlist: playlistToUpdateDuration,
            allSongs: state.allSongs,
          );
          final index = updatedPlaylists.indexWhere((p) => p.id == event.playlistId);
          if (index != -1) {
            updatedPlaylists[index] = updatedPlaylist;
          }
          break;
      }

      emit(state.copyWith(myPlaylist: updatedPlaylists));
      _logger.i('✅ Playlist operation completed successfully');
    } catch (e) {
      _logger.e('❌ Playlist operation failed: $e');
      // Don't emit error state for playlist operations as they're optional
    }
  }

  // ==================== PLAYBACK EVENT HANDLERS ====================
  Future<void> _onPlayOrPauseSong(
    _PlayOrPauseSong event,
    Emitter<MusicState> emit,
  ) async {
    // Prevent race conditions
    if (_isUpdatingState) {
      _logger.w('⚠️ PlayOrPause event ignored - state update in progress');
      return;
    }

    _isUpdatingState = true;

    try {
      _logger.i(
        '🎵 PlayOrPause event: ${event.songId} | Current: ${state.myPlayerState.currentSongId} | Playing: ${state.myPlayerState.isPlaying}',
      );

      // Handle force stop (clear current song and set isPlaying = false)
      if (event.isForceStop == true) {
        _logger.i('🛑 Force stopping music - clearing current song');

        // Stop the audio service to actually stop playback
        await _audioService.stop();
        
        // Stop sleep timer when force stopping
        SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);

        emit(state.copyWith(myPlayerState: state.myPlayerState.clear()));
        _hideNotification();
        return;
      }

      // Handle empty songId (clear current song and set isPlaying = false)
      if (event.songId == null || event.songId!.isEmpty) {
        _logger.i('🧹 Clearing current song and playlist');

        // Stop the audio service to actually stop playback
        await _audioService.stop();
        
        // Stop sleep timer when clearing song
        SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);

        emit(state.copyWith(myPlayerState: state.myPlayerState.clear()));
        _hideNotification();
        return;
      }

      // Check if no song is currently selected
      if (state.myPlayerState.currentSongId == null) {
        _logger.i('🎵 No current song - playing new song');
        // No current song - play the new song
        final song = state.allSongs.firstWhere(
          (s) => s.id == event.songId,
          orElse: () => throw Exception('Song not found in allSongs'),
        );

        // Determine source and create appropriate playlist
        final source = event.playlistSource ?? PlaylistSource.allSongs();
        List<Song> playlistSongs;
        String playlistId;

        if (event.playlistSource == null) {
          // No source provided - keep current playlist if it exists, otherwise use allSongs
          if (state.myPlayerState.currentPlayList.isNotEmpty) {
            playlistSongs = currentPlayListSongs;
            playlistId = state.myPlayerState.playlistId ?? 'all_songs';
          } else {
            playlistSongs = state.allSongs;
            playlistId = 'all_songs';
          }
        } else {
          // Source provided - create new playlist
          playlistSongs = _getPlaylistSongs(source);
          playlistId = _getPlaylistId(source);
        }

        // Create new myPlayerState with appropriate playlist
        final newPlayerState = MyPlayerStateModel(
          playlistId: playlistId,
          currentPlayList: getSongIds(playlistSongs),
          currentSongId: event.songId,
          previousSongId: null,
          completedSongs: [],
          repeatModeIndex: state.myPlayerState.repeatModeIndex,
        );

        // Reorder playlist to start with the tapped song
        final reorderedQueue = newPlayerState.reorderToStartWith(event.songId!);

        _logger.i(
          '🔄 Reordered playlist: ${newPlayerState.currentPlayList} → ${reorderedQueue.currentPlayList}',
        );

        // Update state immediately - clear last position for new song
        emit(
          state.copyWith(
            myPlayerState: reorderedQueue.copyWith(
              isPlaying: true,
              lastPosition: null, // Clear position for new song
            ),
          ),
        );

        // Play the song with the complete allSongs list to maintain order
        // Play the song from beginning
        _audioService.playSong(
          song,
          playlistId: playlistId,
          playlistSource: source,
        );
        _showNotificationForCurrentSong();
        
        // Start sleep timer when song starts playing
        SyncAppSettingsHelper.startSleepTimer(
          appSettingsBloc: _appSettingsBloc,
          musicBloc: this,
        );
        return;
      }

      // Check if this is the same song that's currently selected
      if (event.songId == state.myPlayerState.currentSongId) {
        _logger.i('🔄 Same song - toggling play/pause');
        // Same song - toggle play/pause
        if (state.myPlayerState.isPlaying) {
          // Currently playing - pause
          // Save current position before pausing
          final currentPosition = _audioService.position;
          _logger.i(
            '⏸️ Pausing and saving position: ${currentPosition.inSeconds}s',
          );
          
          emit(
            state.copyWith(
              myPlayerState: state.myPlayerState.copyWith(
                isPlaying: false,
                lastPosition: currentPosition,
              ),
            ),
          );
          _audioService.pause();
          _updateNotificationForCurrentSong();
          
          // Stop sleep timer when pausing
          SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);
        } else {
          // Currently paused - resume
          emit(
            state.copyWith(
              myPlayerState: state.myPlayerState.copyWith(isPlaying: true),
            ),
          );
          
          // Resume playback
          _audioService.resume();
          _updateNotificationForCurrentSong();
          
          // Start sleep timer when resuming playback
          SyncAppSettingsHelper.startSleepTimer(
            appSettingsBloc: _appSettingsBloc,
            musicBloc: this,
          );
        }
      } else {
        _logger.i('🆕 Different song - playing new song');
        // Different song - play the new song
        final song = state.allSongs.firstWhere(
          (s) => s.id == event.songId,
          orElse: () => throw Exception('Song not found in allSongs'),
        );

        // Determine source and create appropriate playlist
        final source = event.playlistSource ?? PlaylistSource.allSongs();
        List<Song> playlistSongs;
        String playlistId;

        if (event.playlistSource == null) {
          // No source provided - keep current playlist if it exists, otherwise use allSongs
          if (state.myPlayerState.currentPlayList.isNotEmpty) {
            playlistSongs = currentPlayListSongs;
            playlistId = state.myPlayerState.playlistId ?? 'all_songs';
          } else {
            playlistSongs = state.allSongs;
            playlistId = 'all_songs';
          }
        } else {
          // Source provided - create new playlist
          playlistSongs = _getPlaylistSongs(source);
          playlistId = _getPlaylistId(source);
        }

        // Create new myPlayerState with appropriate playlist
        final newPlayerState = MyPlayerStateModel(
          playlistId: playlistId,
          currentPlayList: getSongIds(playlistSongs),
          currentSongId: event.songId,
          previousSongId: state.myPlayerState.currentSongId,
          completedSongs: [],
          repeatModeIndex: state.myPlayerState.repeatModeIndex,
        );

        // Reorder playlist to start with the tapped song
        final reorderedQueue = newPlayerState.reorderToStartWith(event.songId!);

        _logger.i(
          '🔄 Reordered playlist: ${newPlayerState.currentPlayList} → ${reorderedQueue.currentPlayList}',
        );

        // Update state immediately - clear last position for new song
        emit(
          state.copyWith(
            myPlayerState: reorderedQueue.copyWith(
              isPlaying: true,
              lastPosition: null, // Clear position for new song
            ),
          ),
        );

        // Play the song with the complete allSongs list to maintain order
        // Play the song from beginning
        _audioService.playSong(
          song,
          playlistId: playlistId,
          playlistSource: source,
        );
        _showNotificationForCurrentSong();
        
        // Start sleep timer when playing different song
        SyncAppSettingsHelper.startSleepTimer(
          appSettingsBloc: _appSettingsBloc,
          musicBloc: this,
        );
      }

      _logger.i(
        '✅ PlayOrPause completed | Song: ${event.songId} | Playing: ${state.myPlayerState.isPlaying}',
      );
    } catch (e) {
      _logger.e('❌ Error in play/pause song: $e | Event: ${event.songId}');
    } finally {
      _isUpdatingState = false;
    }
  }

  Future<void> _onPlayNext(_PlayNext event, Emitter<MusicState> emit) async {
    try {
      _logger.i('Playing next song from queue');

      if (state.myPlayerState.currentPlayList.isNotEmpty) {
        final updatedQueue = state.myPlayerState.nextSong();

        if (updatedQueue.currentSongId != null &&
            updatedQueue.currentSongId != state.myPlayerState.currentSongId) {
          final nextSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );
          _logger.i('🎵 Playing next song in queue: "${nextSong.title}"');
          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${updatedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${updatedQueue.completedCount} songs',
          );

          // Update state immediately with new queue
          emit(
            state.copyWith(
              myPlayerState: updatedQueue.copyWith(isPlaying: true),
            ),
          );

          // Play the song
          await _audioService.playSong(
            nextSong,
            playlistId: state.myPlayerState.playlistId,
            playlistSource: _getPlaylistSourceFromId(state.myPlayerState.playlistId),
          );

          // Update notification
          _updateNotificationForCurrentSong();
          
          // Start sleep timer when playing next song
          SyncAppSettingsHelper.startSleepTimer(
            appSettingsBloc: _appSettingsBloc,
            musicBloc: this,
          );
        } else {
          _logger.w('⚠️ No next song in queue or same song (loop/repeat mode)');
        }
      } else {
        _logger.w('⚠️ No songs in queue');
      }
    } catch (e) {
      _logger.e('Error playing next song: $e');
    }
  }

  Future<void> _onPlayPrevious(
    _PlayPrevious event,
    Emitter<MusicState> emit,
  ) async {
    try {
      _logger.i('Playing previous song from completed songs');

      if (state.myPlayerState.completedSongs.isNotEmpty) {
        final updatedQueue = state.myPlayerState.previousSong();

        if (updatedQueue.currentSongId != null &&
            updatedQueue.currentSongId != state.myPlayerState.currentSongId) {
          final previousSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );
          _logger.i(
            '🎵 Playing previous song from completed: "${previousSong.title}"',
          );
          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${updatedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${updatedQueue.completedCount} songs',
          );

          // Update state immediately with new queue
          emit(
            state.copyWith(
              myPlayerState: updatedQueue.copyWith(isPlaying: true),
            ),
          );

          // Play the song
          await _audioService.playSong(
            previousSong,
            playlistId: state.myPlayerState.playlistId,
            playlistSource: _getPlaylistSourceFromId(state.myPlayerState.playlistId),
          );

          // Update notification
          _updateNotificationForCurrentSong();
          
          // Start sleep timer when playing previous song
          SyncAppSettingsHelper.startSleepTimer(
            appSettingsBloc: _appSettingsBloc,
            musicBloc: this,
          );
        } else {
          _logger.w('⚠️ No previous song available or same song');
        }
      } else {
        _logger.w('⚠️ No completed songs to go back to');
      }
    } catch (e) {
      _logger.e('Error playing previous song: $e');
    }
  }

  // ==================== PLAYBACK SETTINGS EVENT HANDLERS ====================
  Future<void> _onToggleShuffle(
    _ToggleShuffle event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i(
      '🔄 Toggle shuffle → ${event.isShuffle} | Auto-start: ${event.isAutoStart ?? false}',
    );

    // Shuffle setting is handled by MusicBloc state management

    if (event.isShuffle) {
      // Shuffle current playlist
      _logger.i('🔀 Shuffling current playlist...');
      final shuffledQueue = state.myPlayerState.shufflePlaylist();

      emit(
        state.copyWith(myPlayerState: shuffledQueue.copyWith(isShuffle: true)),
      );

      _logger.i(
        '✅ Shuffle enabled | Queue: ${shuffledQueue.remainingSongs} songs',
      );

      // Auto-start if requested and there's a current song
      if (event.isAutoStart == true && shuffledQueue.currentSongId != null) {
        _logger.i('🎵 Auto-starting shuffled playlist...');

        // Use playOrPauseSong event for auto-start
        add(
          MusicEvent.playOrPauseSong(
            songId: shuffledQueue.currentSongId!,
            currentPlayList: event.currentPlayList,
            playlistSource: event.playlistSource,
          ),
        );

        _logger.i(
          '🎵 Auto-start event dispatched for: ${shuffledQueue.currentSongId}',
        );
      }
    } else {
      // Revert shuffle - restore original order based on playlistId
      _logger.i('🔄 Reverting shuffle to original order...');

      List<String> originalOrder;
      final playlistId = state.myPlayerState.playlistId;

      if (playlistId == null || playlistId == 'all_songs') {
        originalOrder = getSongIds(state.allSongs);
        _logger.i('📋 Reverting to all songs order');
      } else if (playlistId.startsWith('album_')) {
        final albumId = playlistId.substring(6); // Remove 'album_' prefix
        final album = state.albumList.firstWhere(
          (album) => album.id == albumId,
          orElse: () => throw Exception('Album not found: $albumId'),
        );
        originalOrder = album.songIds;
        _logger.i('📋 Reverting to album "${album.name}" order');
      } else if (playlistId.startsWith('artist_')) {
        final artistId = playlistId.substring(7); // Remove 'artist_' prefix
        final artist = state.artistList.firstWhere(
          (artist) => artist.id == artistId,
          orElse: () => throw Exception('Artist not found: $artistId'),
        );
        originalOrder = artist.songIds;
        _logger.i('📋 Reverting to artist "${artist.name}" order');
      } else if (playlistId.startsWith('my_playlist_')) {
        final myPlaylistId = playlistId.substring(
          12,
        ); // Remove 'my_playlist_' prefix
        final myPlaylist = state.myPlaylist.firstWhere(
          (playlist) => playlist.id == myPlaylistId,
          orElse: () => throw Exception('MyPlaylist not found: $myPlaylistId'),
        );
        originalOrder = myPlaylist.songIds;
        _logger.i('📋 Reverting to my playlist "${myPlaylist.name}" order');
      } else {
        originalOrder = getSongIds(state.allSongs);
        _logger.i('📋 Reverting to all songs order (unknown playlist)');
      }

      // Apply filter if keyword exists
      if (state.myPlayerState.filterKeyword.isNotEmpty) {
        // Get the actual song list based on playlist type
        List<Song> actualSongList;
        if (playlistId == null || playlistId == 'all_songs') {
          actualSongList = state.allSongs;
        } else if (playlistId.startsWith('album_')) {
          final albumId = playlistId.substring(6);
          final album = state.albumList.firstWhere(
            (album) => album.id == albumId,
            orElse: () => throw Exception('Album not found: $albumId'),
          );
          actualSongList = getSongsFromIds(album.songIds);
        } else if (playlistId.startsWith('artist_')) {
          final artistId = playlistId.substring(7);
          final artist = state.artistList.firstWhere(
            (artist) => artist.id == artistId,
            orElse: () => throw Exception('Artist not found: $artistId'),
          );
          actualSongList = getSongsFromIds(artist.songIds);
        } else if (playlistId.startsWith('my_playlist_')) {
          final myPlaylistId = playlistId.substring(12);
          final myPlaylist = state.myPlaylist.firstWhere(
            (playlist) => playlist.id == myPlaylistId,
            orElse: () =>
                throw Exception('MyPlaylist not found: $myPlaylistId'),
          );
          actualSongList = getSongsFromIds(myPlaylist.songIds);
        } else {
          actualSongList = state.allSongs;
        }

        originalOrder = state.myPlayerState.getFilteredSongIds(
          originalOrder,
          actualSongList,
        );
        _logger.i(
          '🔍 Applied filter "${state.myPlayerState.filterKeyword}" to reverted order using ${actualSongList.length} songs',
        );
      }

      final revertedQueue = state.myPlayerState.revertShuffle(originalOrder);

      emit(
        state.copyWith(myPlayerState: revertedQueue.copyWith(isShuffle: false)),
      );

      _logger.i(
        '✅ Shuffle disabled | Queue: ${revertedQueue.remainingSongs} songs',
      );
    }
  }

  Future<void> _onToggleRepeat(
    _ToggleRepeat event,
    Emitter<MusicState> emit,
  ) async {
    // Cycle through repeat modes: 0 -> 1 -> 2 -> 0
    final updatedQueue = state.myPlayerState.cycleRepeatMode();
    final newRepeatModeIndex = updatedQueue.repeatModeIndex;

    _logger.i(
      '🔄 Toggle repeat → ${updatedQueue.repeatModeDescription} (Index: $newRepeatModeIndex)',
    );

    // Update myPlayerState with new repeat mode
    emit(state.copyWith(myPlayerState: updatedQueue));
  }

  // ==================== SORTING AND SEEKING EVENT HANDLERS ====================
  Future<void> _onChangeSortingOrder(
    _ChangeSortingOrder event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i(
      '🔄 Change sorting order → Index: ${event.sortingIndex} | Source: ${event.playlistSource?.source ?? Sources.allSongs}',
    );

    emit(state.copyWith(sortingIndex: event.sortingIndex));

    // Apply sorting based on source
    final source = event.playlistSource?.source ?? Sources.allSongs;

    switch (source) {
      case Sources.allSongs:
        // Apply sorting to all songs
        final sortedSongs = _applySorting(
          event.sortingList
              .map(
                (songId) => state.allSongs.firstWhere(
                  (song) => song.id == songId,
                  orElse: () => throw Exception('Song not found: $songId'),
                ),
              )
              .toList(),
          event.sortingIndex,
        );
        emit(state.copyWith(allSongs: sortedSongs));
        _logger.i('✅ All songs sorted with index ${event.sortingIndex}');
        break;

      case Sources.album:
        // Apply sorting to album songs
        if (event.playlistSource?.albumId != null) {
          final albumSongs = _getPlaylistSongs(event.playlistSource!);
          final sortedAlbumSongs = _applySorting(
            albumSongs,
            event.sortingIndex,
          );
          // Update album list with sorted songs
          final updatedAlbumList = state.albumList.map((album) {
            if (album.id == event.playlistSource!.albumId) {
              return album.copyWith(
                songIds: sortedAlbumSongs.map((s) => s.id).toList(),
              );
            }
            return album;
          }).toList();
          emit(state.copyWith(albumList: updatedAlbumList));
          _logger.i(
            '✅ Album "${event.playlistSource!.albumId}" songs sorted with index ${event.sortingIndex}',
          );
        }
        break;

      case Sources.artist:
        // Apply sorting to artist songs
        if (event.playlistSource?.artistId != null) {
          final artistSongs = _getPlaylistSongs(event.playlistSource!);
          final sortedArtistSongs = _applySorting(
            artistSongs,
            event.sortingIndex,
          );
          // Update artist list with sorted songs
          final updatedArtistList = state.artistList.map((artist) {
            if (artist.id == event.playlistSource!.artistId) {
              return artist.copyWith(
                songIds: sortedArtistSongs.map((s) => s.id).toList(),
              );
            }
            return artist;
          }).toList();
          emit(state.copyWith(artistList: updatedArtistList));
          _logger.i(
            '✅ Artist "${event.playlistSource!.artistId}" songs sorted with index ${event.sortingIndex}',
          );
        }
        break;

      case Sources.myPlaylist:
        // Apply sorting to playlist songs
        if (event.playlistSource?.playlistId != null) {
          final playlistSongs = _getPlaylistSongs(event.playlistSource!);
          final sortedPlaylistSongs = _applySorting(
            playlistSongs,
            event.sortingIndex,
          );
          // Update playlist with sorted songs
          final updatedPlaylist = state.myPlaylist.map((playlist) {
            if (playlist.id == event.playlistSource!.playlistId) {
              return playlist.copyWith(
                songIds: sortedPlaylistSongs.map((s) => s.id).toList(),
              );
            }
            return playlist;
          }).toList();
          emit(state.copyWith(myPlaylist: updatedPlaylist));
          _logger.i(
            '✅ Playlist "${event.playlistSource!.playlistId}" songs sorted with index ${event.sortingIndex}',
          );
        }
        break;

      default:
        _logger.w('⚠️ Unknown sorting source: $source');
        break;
    }
  }

  Future<void> _onSeekToPosition(
    _SeekToPosition event,
    Emitter<MusicState> emit,
  ) async {
    try {
      _logger.i(
        '🔍 Seek event triggered | Position: ${event.position.inSeconds}s (${event.position.inMilliseconds}ms)',
      );

      await _audioService.seekTo(event.position);
      _logger.i(
        '✅ Seek event completed successfully | Position: ${event.position.inSeconds}s',
      );
    } catch (e) {
      _logger.e(
        '❌ Error seeking to position ${event.position.inSeconds}s: $e | Current state: currentSongId=${state.myPlayerState.currentSongId}',
      );
    }
  }

  Future<void> _onUpdateLastPosition(
    _UpdateLastPosition event,
    Emitter<MusicState> emit,
  ) async {
    try {
      _logger.i(
        '💾 Updating last position: ${event.position.inSeconds}s | Song: ${state.myPlayerState.currentSongId}',
      );

      emit(
        state.copyWith(
          myPlayerState: state.myPlayerState.copyWith(
            lastPosition: event.position,
          ),
        ),
      );

      _logger.i('✅ Last position updated successfully');
    } catch (e) {
      _logger.e('❌ Error updating last position: $e');
    }
  }

  // ==================== STATE UPDATE EVENT HANDLERS ====================
  Future<void> _onUpdateMusicBlocState(
    _UpdateMusicBlocState event,
    Emitter<MusicState> emit,
  ) async {
    // Removed redundant state update logging
    emit(event.newState);
  }
  
  /// Mark initialization as complete to allow position updates
  void markInitializationComplete() {
    _isInitializing = false;
    _logger.i('✅ App initialization marked as complete - position tracking enabled');
  }

  // ==================== AUDIO SERVICE CALLBACKS ====================
  /// Handle position changes from audio service
  void _onPositionChanged(Duration position) {
    // Don't update position during app initialization to prevent overriding restored position
    if (_isInitializing) {
      _logger.d('🔍 Position change ignored during initialization: ${position.inSeconds}s');
      return;
    }
    
    // Only update position if we're not currently updating state to prevent race conditions
    if (!_isUpdatingState && state.myPlayerState.currentSongId != null) {
      // Update position every 5 seconds to avoid too frequent updates
      // But only if the position has actually changed significantly
      final currentSavedPosition = state.myPlayerState.lastPosition;
      if (currentSavedPosition == null || 
          (position.inSeconds - currentSavedPosition.inSeconds).abs() >= 5) {
        if (position.inSeconds % 5 == 0) {
          add(MusicEvent.updateLastPosition(position: position));
        }
      }
    }
  }
  
  /// Handle when audio service changes songs automatically
  void _onAudioServiceSongChanged(Song newSong) {
    _logger.i(
      '🎵 Audio service song changed: "${newSong.title}" | Updating bloc state',
    );

    // Only update if we're not currently updating state to prevent conflicts
    if (!_isUpdatingState) {
      // Check if this is a different song (skip scenario)
      if (state.myPlayerState.currentSongId != null && 
          state.myPlayerState.currentSongId != newSong.id) {
        
        _logger.i('🔄 Song skipped - moving previous song to completed');
        
        // Move current song to completed and set new song as current
        final updatedQueue = state.myPlayerState.moveCurrentToCompleted();
        final finalQueue = updatedQueue.copyWith(
          currentSongId: newSong.id,
          previousSongId: state.myPlayerState.currentSongId,
          isPlaying: true,
        );
        
        _logger.i(
          '✅ Completed songs: ${state.myPlayerState.completedCount} → ${finalQueue.completedCount} songs',
        );
        
        add(
          MusicEvent.updateMusicBlocState(
            newState: state.copyWith(myPlayerState: finalQueue),
          ),
        );
      } else {
        // Same song or no previous song - just update current song
        add(
          MusicEvent.updateMusicBlocState(
            newState: state.copyWith(
              myPlayerState: state.myPlayerState.copyWith(
                currentSongId: newSong.id,
                currentPlayList: state.myPlayerState.currentPlayList,
                isPlaying: true,
              ),
            ),
          ),
        );
      }

      // Update notification with new song
      _updateNotificationForCurrentSong();

      _logger.i(
        '✅ Bloc state updated for new song: "${newSong.title}" | currentSongId: ${newSong.id}',
      );
    } else {
      _logger.w(
        '⚠️ Audio service song change ignored - state update in progress',
      );
    }
  }

  // ==================== REMOTE CONTROL METHODS ====================
  /// Handle remote control actions from external devices
  void _handleRemoteControlAction(RemoteControlAction action) {
    _logger.i('🎧 Remote control action received: ${action.description}');

    if (state.myPlayerState.currentSongId == null ||
        state.myPlayerState.currentPlayList.isEmpty) {
      _logger.w('⚠️ Remote control action ignored - no current song');
      return;
    }

    switch (action) {
      case RemoteControlAction.play:
        if (!state.myPlayerState.isPlaying) {
          add(
            MusicEvent.playOrPauseSong(
              songId: state.myPlayerState.currentSongId!,
              currentPlayList: state.myPlayerState.currentPlayList,
            ),
          );
        }
        break;
      case RemoteControlAction.pause:
        if (state.myPlayerState.isPlaying) {
          add(
            MusicEvent.playOrPauseSong(
              songId: state.myPlayerState.currentSongId!,
              currentPlayList: state.myPlayerState.currentPlayList,
            ),
          );
        }
        break;
      case RemoteControlAction.togglePlayPause:
        add(
          MusicEvent.playOrPauseSong(
            songId: state.myPlayerState.currentSongId!,
            currentPlayList: state.myPlayerState.currentPlayList,
          ),
        );
        break;
      case RemoteControlAction.next:
        add(const MusicEvent.playNext());
        break;
      case RemoteControlAction.previous:
        add(const MusicEvent.playPrevious());
        break;
      case RemoteControlAction.stop:
        // Stop playback and clear current song
        add(MusicEvent.playOrPauseSong(songId: '', currentPlayList: []));
        break;
      case RemoteControlAction.seekForward:
        // Seek forward 10 seconds
        final newPosition =
            _audioService.position + const Duration(seconds: 10);
        final duration = _audioService.duration;
        if (duration > Duration.zero && newPosition < duration) {
          add(MusicEvent.seekToPosition(position: newPosition));
        }
        break;
      case RemoteControlAction.seekBackward:
        // Seek backward 10 seconds
        final newPosition =
            _audioService.position - const Duration(seconds: 10);
        if (newPosition > Duration.zero) {
          add(MusicEvent.seekToPosition(position: newPosition));
        }
        break;
    }
  }

  // ==================== NOTIFICATION METHODS ====================
  /// Update notification for current song
  void _updateNotificationForCurrentSong() {
    if (state.myPlayerState.currentSongId != null) {
      try {
        final currentSong = state.allSongs.firstWhere(
          (song) => song.id == state.myPlayerState.currentSongId,
        );

        EnhancedNotificationService.showEnhancedNotification(
          song: currentSong,
          isPlaying: state.myPlayerState.isPlaying,
        );

        _logger.i('📱 Notification updated for: "${currentSong.title}"');
      } catch (e) {
        _logger.e('❌ Error updating notification: $e');
      }
    }
  }

  /// Show notification when music starts
  void _showNotificationForCurrentSong() {
    if (state.myPlayerState.currentSongId != null) {
      try {
        final currentSong = state.allSongs.firstWhere(
          (song) => song.id == state.myPlayerState.currentSongId,
        );

        EnhancedNotificationService.showEnhancedNotification(
          song: currentSong,
          isPlaying: state.myPlayerState.isPlaying,
        );

        _logger.i('📱 Notification shown for: "${currentSong.title}"');
      } catch (e) {
        _logger.e('❌ Error showing notification: $e');
      }
    }
  }

  /// Hide notification when music stops
  void _hideNotification() {
    try {
      EnhancedNotificationService.hideEnhancedNotification();
      _logger.i('📱 Notification hidden');
    } catch (e) {
      _logger.e('❌ Error hiding notification: $e');
    }
  }

  // ==================== SONG COMPLETION HANDLING ====================
  /// Handle when a song completes - move it to completed songs and play next
  Future<void> _handleSongCompletion() async {
    _logger.i('🎯 Song completed - checking autoPlayNext setting');

    if (state.myPlayerState.currentSongId != null &&
        state.myPlayerState.currentPlayList.isNotEmpty) {
      
      // Check autoPlayNext setting from AppSettingsBloc
      final appSettingsState = _appSettingsBloc.state;
      final autoPlayNext = appSettingsState.autoPlayNext;
      
      _logger.i('⚙️ AutoPlayNext setting: $autoPlayNext');
      
      if (autoPlayNext) {
        // AutoPlayNext is enabled - continue with normal flow
        _logger.i('✅ AutoPlayNext enabled - moving to completed songs and playing next');
        
        // Try to get next song (handles repeat/loop logic)
        final updatedQueue = state.myPlayerState.nextSong();

        if (updatedQueue.currentSongId != null) {
          // There's a next song to play
          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${updatedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${updatedQueue.completedCount} songs',
          );

          // Update state with new queue and play next song
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: updatedQueue.copyWith(isPlaying: true),
              ),
            ),
          );

          // Play the next song
          final nextSong = state.allSongs.firstWhere(
            (s) => s.id == updatedQueue.currentSongId,
          );
          _audioService.playSong(
            nextSong,
            playlistId: state.myPlayerState.playlistId,
            playlistSource: _getPlaylistSourceFromId(state.myPlayerState.playlistId),
          );
          _updateNotificationForCurrentSong();
        } else {
          // No next song - just move current to completed
          final completedQueue = state.myPlayerState.moveCurrentToCompleted();

          _logger.i(
            '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${completedQueue.remainingSongs} songs',
          );
          _logger.i(
            '✅ Completed songs: ${state.myPlayerState.completedCount} → ${completedQueue.completedCount} songs',
          );

          // Update state with completed queue
          add(
            MusicEvent.updateMusicBlocState(
              newState: state.copyWith(
                myPlayerState: completedQueue.copyWith(isPlaying: false),
              ),
            ),
          );

          // Hide notification when queue is empty
          if (completedQueue.currentPlayList.isEmpty) {
            _hideNotification();
          }
        }
      } else {
        // AutoPlayNext is disabled - just pause and move to completed
        _logger.i('⏸️ AutoPlayNext disabled - pausing playback and moving to completed');
        
        // Move current song to completed
        final completedQueue = state.myPlayerState.moveCurrentToCompleted();

        _logger.i(
          '📋 Queue updated: ${state.myPlayerState.remainingSongs} → ${completedQueue.remainingSongs} songs',
        );
        _logger.i(
          '✅ Completed songs: ${state.myPlayerState.completedCount} → ${completedQueue.completedCount} songs',
        );

        // Update state with completed queue and pause
        add(
          MusicEvent.updateMusicBlocState(
            newState: state.copyWith(
              myPlayerState: completedQueue.copyWith(isPlaying: false),
            ),
          ),
        );

        // Reset position to beginning and pause the audio service
        await _audioService.seekTo(Duration.zero);
        await _audioService.pause();
        
        _logger.i('🔄 Song position reset to beginning for next play');
        
        // Hide notification when queue is empty
        if (completedQueue.currentPlayList.isEmpty) {
          _hideNotification();
        }
      }
    }
  }

  // ==================== PLAYBACK SPEED CONTROL ====================
  
  /// Public method to sync playback speed (can be called from outside)
  void syncPlaybackSpeed() {
    SyncAppSettingsHelper.syncPlaybackSpeed(
      appSettingsBloc: _appSettingsBloc,
      audioService: _audioService,
    );
  }

  // ==================== SLEEP TIMER PUBLIC METHODS ====================
  /// Check if sleep timer is currently running
  bool get isSleepTimerRunning => _sleepTimer != null;
  
  /// Get remaining sleep timer duration (for debugging/logging)
  Duration? getSleepTimerRemainingDuration() {
    if (_sleepTimer == null) return null;
    // Note: Dart Timer doesn't provide remaining time, so we return null
    // This is just for future enhancement if needed
    return null;
  }
  
  /// Handle app lifecycle changes (background/foreground)
  void handleAppLifecycleChange(AppLifecycleState lifecycleState) {
    SyncAppSettingsHelper.handleAppLifecycleChange(
      lifecycleState: lifecycleState,
      appSettingsBloc: _appSettingsBloc,
      musicBloc: this,
    );
  }

  // ==================== SLEEP TIMER INTERNAL METHODS ====================
  /// Internal method to start sleep timer (used by helper)
  void startSleepTimerInternal(Duration timerDuration) {
    try {
      // Cancel any existing timer first
      _sleepTimer?.cancel();
      _sleepTimer = null;
      
      // Start new timer
      _sleepTimer = Timer(timerDuration, () {
        _handleSleepTimerExpiredInternal();
      });
    } catch (e) {
      _logger.e('❌ Error starting sleep timer internally: $e');
    }
  }
  
  /// Internal method to stop sleep timer (used by helper)
  void stopSleepTimerInternal() {
    try {
      if (_sleepTimer != null) {
        _sleepTimer?.cancel();
        _sleepTimer = null;
        _logger.i('💤 Sleep timer stopped and cleared');
      } else {
        _logger.d('💤 No sleep timer running to stop');
      }
    } catch (e) {
      _logger.e('❌ Error stopping sleep timer internally: $e');
    }
  }
  
  /// Internal method to handle sleep timer expiration (used by helper)
  void _handleSleepTimerExpiredInternal() {
    try {
      _logger.i('💤 Sleep timer expired - pausing playback');
      
      // Pause the audio service
      _audioService.pause();
      
      // Update state to reflect paused state
      add(
        MusicEvent.updateMusicBlocState(
          newState: state.copyWith(
            myPlayerState: state.myPlayerState.copyWith(isPlaying: false),
          ),
        ),
      );
      
      // Hide notification
      _hideNotification();
      
      _logger.i('✅ Sleep timer completed - playback paused');
    } catch (e) {
      _logger.e('❌ Error handling sleep timer expiration internally: $e');
    }
  }


  // ==================== UTILITY METHODS ====================
  List<Song> _applySorting(List<Song> songs, int sortingIndex) {
    List<Song> result = List.from(songs);

    switch (sortingIndex) {
      case 0: // Newest First
        result.sort(
          (a, b) => (b.dateAdded ?? DateTime.now()).compareTo(
            a.dateAdded ?? DateTime.now(),
          ),
        );
        break;
      case 1: // Oldest First
        result.sort(
          (a, b) => (a.dateAdded ?? DateTime.now()).compareTo(
            b.dateAdded ?? DateTime.now(),
          ),
        );
        break;
      case 2: // Alphabetical
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 3: // Duration (Shortest)
        result.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 4: // Duration (Longest)
        result.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }

    return result;
  }

  // ==================== HELPER METHODS ====================
  /// Get current song from state using allSongs
  Song? get currentSong {
    if (state.myPlayerState.currentSongId == null) {
      return null;
    }

    try {
      return state.allSongs.firstWhere(
        (song) => song.id == state.myPlayerState.currentSongId,
      );
    } catch (e) {
      _logger.e('Error finding current song: $e');
      return null;
    }
  }

  /// Get songs from currentPlayList (song IDs) using allSongs
  List<Song> get currentPlayListSongs {
    return state.myPlayerState.currentPlayList
        .map(
          (songId) => state.allSongs.firstWhere(
            (song) => song.id == songId,
            orElse: () => throw Exception('Song not found: $songId'),
          ),
        )
        .toList();
  }

  /// Get playlist ID based on PlaylistSource
  String _getPlaylistId(PlaylistSource playlistSource) {
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

  /// Get playlist songs based on PlaylistSource
  List<Song> _getPlaylistSongs(PlaylistSource playlistSource) {
    switch (playlistSource.source) {
      case Sources.allSongs:
        return state.allSongs;
      case Sources.album:
        if (playlistSource.albumId == null) return state.allSongs;
        final album = state.albumList.firstWhere(
          (album) => album.id == playlistSource.albumId,
          orElse: () =>
              throw Exception('Album not found: ${playlistSource.albumId}'),
        );
        return getSongsFromIds(album.songIds);
      case Sources.artist:
        if (playlistSource.artistId == null) return state.allSongs;
        final artist = state.artistList.firstWhere(
          (artist) => artist.id == playlistSource.artistId,
          orElse: () =>
              throw Exception('Artist not found: ${playlistSource.artistId}'),
        );
        return getSongsFromIds(artist.songIds);
      case Sources.myPlaylist:
        if (playlistSource.playlistId == null) return state.allSongs;
        final myPlaylist = state.myPlaylist.firstWhere(
          (playlist) => playlist.id == playlistSource.playlistId,
          orElse: () => throw Exception(
            'MyPlaylist not found: ${playlistSource.playlistId}',
          ),
        );
        return getSongsFromIds(myPlaylist.songIds);
      default:
        return state.allSongs;
    }
  }

  /// Get song IDs from a list of songs
  List<String> getSongIds(List<Song> songs) {
    return songs.map((song) => song.id).toList();
  }

  /// Get songs from song IDs using allSongs
  List<Song> getSongsFromIds(List<String> songIds) {
    return songIds
        .map(
          (songId) => state.allSongs.firstWhere(
            (song) => song.id == songId,
            orElse: () => throw Exception('Song not found: $songId'),
          ),
        )
        .toList();
  }

  /// Get PlaylistSource from playlist ID
  PlaylistSource? _getPlaylistSourceFromId(String? playlistId) {
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
      // Verify playlist exists
      state.myPlaylist.firstWhere(
        (playlist) => playlist.id == myPlaylistId,
        orElse: () => throw Exception('MyPlaylist not found: $myPlaylistId'),
      );
      return PlaylistSource.myPlaylist(myPlaylistId);
    }
    
    return null;
  }

  // ==================== FILTER EVENT HANDLERS ====================
  Future<void> _onUpdateFilterKeyword(
    _UpdateFilterKeyword event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🔍 Updating filter keyword: "${event.filterKeyword}"');

    emit(
      state.copyWith(
        myPlayerState: state.myPlayerState.copyWith(
          filterKeyword: event.filterKeyword,
        ),
      ),
    );

    _logger.i('✅ Filter keyword updated');
  }

  Future<void> _onSetNavigationFilter(
    _SetNavigationFilter event,
    Emitter<MusicState> emit,
  ) async {
    _logger.i('🧭 Setting navigation filter: type="${event.filterType}", value="${event.filterValue}"');

    emit(
      state.copyWith(
        navigationFilterType: event.filterType,
        navigationFilterValue: event.filterValue ?? '',
      ),
    );

    _logger.i('✅ Navigation filter updated');
  }

  // ==================== PROGRESSIVE EXTRACTION METHODS ====================

  /// Extract albums progressively from current songs
  Future<void> _extractAlbumsProgressive({
    required Function(List<Album>, bool) onProgress,
  }) async {
    try {
      final songs = state.allSongs;
      final List<Album> albums = [];
      const int batchSize = 10;

      for (int i = 0; i < songs.length; i += batchSize) {
        final batch = songs.skip(i).take(batchSize).toList();
        final batchAlbums = MusicService.fetchAlbumList(batch);

        // Add new albums to the list
        for (final album in batchAlbums) {
          if (!albums.any((existing) => existing.name == album.name)) {
            albums.add(album);
          }
        }

        // Report progress
        final isComplete = (i + batchSize) >= songs.length;
        onProgress(batchAlbums, isComplete);

        // Small delay to prevent UI blocking
        if (!isComplete) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      _logger.i(
        '✅ Progressive album extraction completed: ${albums.length} albums',
      );
    } catch (e) {
      _logger.e('❌ Error in progressive album extraction: $e');
    }
  }

  /// Extract artists progressively from current songs
  Future<void> _extractArtistsProgressive({
    required Function(List<Artist>, bool) onProgress,
  }) async {
    try {
      final songs = state.allSongs;
      final List<Artist> artists = [];
      const int batchSize = 10;

      for (int i = 0; i < songs.length; i += batchSize) {
        final batch = songs.skip(i).take(batchSize).toList();
        final batchArtists = MusicService.fetchArtistList(batch);

        // Add new artists to the list
        for (final artist in batchArtists) {
          if (!artists.any((existing) => existing.name == artist.name)) {
            artists.add(artist);
          }
        }

        // Report progress
        final isComplete = (i + batchSize) >= songs.length;
        onProgress(batchArtists, isComplete);

        // Small delay to prevent UI blocking
        if (!isComplete) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      _logger.i(
        '✅ Progressive artist extraction completed: ${artists.length} artists',
      );
    } catch (e) {
      _logger.e('❌ Error in progressive artist extraction: $e');
    }
  }

  // ==================== PLAY COUNT TRACKING METHODS ====================
  
  /// Setup play count tracking callbacks
  void _setupPlayCountTracking() {
    PlayCountTrackingService.onUpdatePlayCount = _updatePlayCountOnState;
    _logger.i('📊 Play count tracking service initialized');
  }
  
  /// Comprehensive play count update method - updates song, artists, albums, and playlist in one atomic operation
  void _updatePlayCountOnState(String songId) {
    try {
      _logger.i('🎵 Updating play counts for song ID: $songId');
      
      final currentState = state;
      final now = DateTime.now();
      
      // Step 1: Find and update the current song
      final songIndex = currentState.allSongs.indexWhere((song) => song.id == songId);
      if (songIndex == -1) {
        _logger.w('⚠️ Song not found with ID: $songId');
        return;
      }
      
      final currentSong = currentState.allSongs[songIndex];
      final updatedSongWithCount = currentSong.copyWith(
        lastPlayed: now,
        playCount: (currentSong.playCount ?? 0) + 1,
      );
      
      // Create updated allSongs list
      final updatedAllSongs = List<Song>.from(currentState.allSongs);
      updatedAllSongs[songIndex] = updatedSongWithCount;
      
      // Step 2: Update artists based on song's artist names (case-insensitive)
      List<Artist> updatedArtistList = List<Artist>.from(currentState.artistList);
      
      for (String artistName in currentSong.artists) {
        final artistIndex = updatedArtistList.indexWhere((artist) => 
          artist.name.toLowerCase().trim() == artistName.toLowerCase().trim());
        if (artistIndex != -1) {
          final currentArtist = updatedArtistList[artistIndex];
          final updatedArtist = currentArtist.copyWith(
            lastPlayed: now,
            playCount: (currentArtist.playCount ?? 0) + 1,
          );
          updatedArtistList[artistIndex] = updatedArtist;
          _logger.d('🎤 Updated artist: "${currentArtist.name}"');
        } else {
          _logger.w('⚠️ Artist not found: "$artistName"');
        }
      }
      
      // Step 3: Update albums based on song's album names (case-insensitive)
      List<Album> updatedAlbumList = List<Album>.from(currentState.albumList);
      
      for (String albumName in currentSong.albums) {
        final albumIndex = updatedAlbumList.indexWhere((album) => 
          album.name.toLowerCase().trim() == albumName.toLowerCase().trim());
        if (albumIndex != -1) {
          final currentAlbum = updatedAlbumList[albumIndex];
          final updatedAlbum = currentAlbum.copyWith(
            lastPlayed: now,
            playCount: (currentAlbum.playCount ?? 0) + 1,
          );
          updatedAlbumList[albumIndex] = updatedAlbum;
          _logger.d('💿 Updated album: "${currentAlbum.name}"');
        } else {
          _logger.w('⚠️ Album not found: "$albumName"');
        }
      }
      
      // Step 4: Update MyPlaylist if applicable (from tracking service context)
      List<MyPlaylist> updatedMyPlaylistList = List<MyPlaylist>.from(currentState.myPlaylist);
      
      // Check if we have playlist context from the tracking service
      final trackingStatus = PlayCountTrackingService.getTrackingStatus();
      final playlistId = trackingStatus['playlistId'] as String?;
      final playlistSource = trackingStatus['playlistSource'] as String?;
      
      if (playlistId != null && playlistSource != null && playlistSource == 'my_playlist') {
        // Extract actual playlist ID (remove prefix if present)
        String actualPlaylistId = playlistId;
        if (playlistId.startsWith('my_playlist_')) {
          actualPlaylistId = playlistId.substring(12);
        }
        
        final playlistIndex = updatedMyPlaylistList.indexWhere((playlist) => playlist.id == actualPlaylistId);
        
        if (playlistIndex != -1) {
          final currentPlaylist = updatedMyPlaylistList[playlistIndex];
          final updatedPlaylist = currentPlaylist.copyWith(
            lastPlayed: now,
            playCount: (currentPlaylist.playCount ?? 0) + 1,
          );
          updatedMyPlaylistList[playlistIndex] = updatedPlaylist;
          _logger.d('📋 Updated playlist: "${currentPlaylist.name}"');
        } else {
          _logger.w('⚠️ Playlist not found: $actualPlaylistId');
        }
      }
      
      // Step 5: Emit updated state (preserving all other state properties)
      add(MusicEvent.updateMusicBlocState(
        newState: currentState.copyWith(
          allSongs: updatedAllSongs,
          artistList: updatedArtistList,
          albumList: updatedAlbumList,
          myPlaylist: updatedMyPlaylistList,
        ),
      ));
      
      _logger.i('✅ Play count updated successfully for: "${currentSong.title}"');
      
    } catch (e) {
      _logger.e('❌ Error updating play count: $e');
    }
  }
  


  @override
  Future<void> close() {
    // Stop play count tracking
    PlayCountTrackingService.stopTracking();
    
    // Stop sleep timer
    SyncAppSettingsHelper.stopSleepTimer(musicBloc: this);
    
    // Dispose stream subscriptions to prevent memory leaks
    _playerStateSubscription?.cancel();
    _appSettingsSubscription?.cancel();
    return super.close();
  }
}
